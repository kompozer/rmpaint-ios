#import "RMCanvasView.h"

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import "RMCanvasOptions.h"
#import "RMPaintStep.h"
#import "RMPaintSession.h"



@interface RMCanvasView ()

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, assign) BOOL needsErase;

@end

@implementation RMCanvasView

// Implement this to override the default layer class (which is [CALayer class]).
// We do this so that our view will be backed by a layer that is capable of OpenGL ES rendering.
+ (Class)layerClass
{
	return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initCanvasView];
	}
	return self; 
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initCanvasView];
	}
	return self;
}

// Releases resources when they are not longer needed.
- (void)dealloc
{
    if (brushTexture) {
        glDeleteTextures(1, &brushTexture);
        brushTexture = 0;
    }
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)initCanvasView
{
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    
    eaglLayer.opaque = NO;
    // In this application, we want to retain the EAGLDrawable contents after a call to presentRenderbuffer.
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:YES], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    
    if (! self.context || ![EAGLContext setCurrentContext:self.context]) {
        return;
    }
    
    
    // Set the view's scale factor
    self.contentScaleFactor = 1.0;
    
    // Setup OpenGL states
    glMatrixMode(GL_PROJECTION);
    CGRect frame = self.bounds;
    CGFloat scale = self.contentScaleFactor;
    // Setup the view port in Pixels
    glOrthof(0, frame.size.width * scale, 0, frame.size.height * scale, -1, 1);
    glViewport(0, 0, frame.size.width * scale, frame.size.height * scale);
    glMatrixMode(GL_MODELVIEW);
    
    glDisable(GL_DITHER);
    glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_VERTEX_ARRAY);
    
    glEnable(GL_BLEND);
    // Set a blending function appropriate for premultiplied alpha pixel data
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    // Make sure to start with a cleared buffer
    self.needsErase = YES;
    
    self.canvasOptions = [RMCanvasOptions canvasOptionsDefaults];
    self.session = [RMPaintSession new];
}

// Drawings a line onscreen based on where the user touches
- (void)renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end
{
    // Set brush color
    if (self.brushColor) {
        CGFloat red, green, blue, alpha;
        [_brushColor getRed:&red green:&green blue:&blue alpha:&alpha];
        glColor4f(red * alpha, green * alpha, blue * alpha, alpha);
    }
    
    RMPaintStep *step = [[RMPaintStep alloc] initWithColor:self.brushColor start:start end:end];
    
    // Convert touch point from UIView referential to OpenGL one (upside-down flip)
    CGRect bounds = [self bounds];    
    start.y = bounds.size.height - start.y;
    end.y = bounds.size.height - end.y;
    
	static GLfloat* vertexBuffer = NULL;
	static NSUInteger vertexMax = 64;
    GLsizei	vertexCount = 0;
    GLsizei count;
    GLsizei i;
	
	[EAGLContext setCurrentContext:self.context];
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	
	// Convert locations from Points to Pixels
	CGFloat scale = self.contentScaleFactor;
	start.x *= scale;
	start.y *= scale;
	end.x *= scale;
	end.y *= scale;
	
	// Allocate vertex array buffer
    if (vertexBuffer == NULL) {
		vertexBuffer = malloc(vertexMax * 2 * sizeof(GLfloat));
    }
	
	// Add points to the buffer so there are drawing points every X pixels
	count = MAX(ceilf(sqrtf((end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y)) / self.canvasOptions.brushPixelStep), 1);
	for(i = 0; i < count; ++i) {
		if (vertexCount == vertexMax) {
			vertexMax = 2 * vertexMax;
			vertexBuffer = realloc(vertexBuffer, vertexMax * 2 * sizeof(GLfloat));
		}
		
		vertexBuffer[2 * vertexCount + 0] = start.x + (end.x - start.x) * ((GLfloat)i / (GLfloat)count);
		vertexBuffer[2 * vertexCount + 1] = start.y + (end.y - start.y) * ((GLfloat)i / (GLfloat)count);
		vertexCount += 1;
	}
	
	// Render the vertex array
	glVertexPointer(2, GL_FLOAT, 0, vertexBuffer);
	glDrawArrays(GL_POINTS, 0, vertexCount);
	
	// Display the buffer
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[self.context presentRenderbuffer:GL_RENDERBUFFER_OES];
    
    [self.delegate canvasView:self painted:step];
    [self.session addStep:step];
}

// If our view is resized, we'll be asked to layout subviews.
// This is the perfect opportunity to also update the framebuffer so that it is
// the same size as our display area.
-(void)layoutSubviews
{
	[EAGLContext setCurrentContext:self.context];
	[self destroyFramebuffer];
	[self createFramebuffer];
	
	// Clear the framebuffer the first time it is allocated
	if (self.needsErase) {
		[self erase];
		self.needsErase = NO;
	}
}

- (BOOL)createFramebuffer
{
	// Generate IDs for a framebuffer object and a color renderbuffer
	glGenFramebuffersOES(1, &viewFramebuffer);
	glGenRenderbuffersOES(1, &viewRenderbuffer);
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	// This call associates the storage for the current render buffer with the EAGLDrawable (our CAEAGLLayer)
	// allowing us to draw into a buffer that will later be rendered to screen wherever the layer is (which corresponds with our view).
	[self.context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)self.layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
	
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
	// For this sample, we also need a depth buffer, so we'll create and attach one via another renderbuffer.
	glGenRenderbuffersOES(1, &depthRenderbuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
	glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
	
	if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
		return NO;
	}
	
	return YES;
}

// Clean up any buffers we have allocated.
- (void)destroyFramebuffer
{
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;
	
	if (depthRenderbuffer) {
		glDeleteRenderbuffersOES(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
}

// Erases the screen
- (void)erase
{
	[EAGLContext setCurrentContext:self.context];
	
	// Clear the buffer
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glClearColor(0.0, 0.0, 0.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	// Display the buffer
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[self.context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (UIImage *)snapshotImage
{
    const CGFloat width = self.frame.size.width;
    const CGFloat height = self.frame.size.height;
    GLubyte *tmpBuffer = (GLubyte *)malloc(width * height * 4);
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, tmpBuffer);
    GLubyte *buffer = (GLubyte *)malloc(width * height * 4);
    
    for (int y = 0; y < height; y++) {
        for(int x = 0; x < width * 4; x++) {
            buffer[((NSInteger)height - 1 - y) * (NSInteger)width * 4 + x] = tmpBuffer[y * 4 * (NSInteger)width + x];
        }
    }
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, width * height * 4, NULL);
    
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * width;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    // Make the cgimage.
    CGImageRef imageRef = CGImageCreate(width, height,
                                        bitsPerComponent,
                                        bitsPerPixel,
                                        bytesPerRow,
                                        colorSpaceRef,
                                        bitmapInfo,
                                        provider,
                                        NULL, NO,
                                        renderingIntent);
    
    return [UIImage imageWithCGImage:imageRef];
}

#pragma mark - Properties

- (void)setBrush:(UIImage *)image
{
    _brush = image;
    
    [EAGLContext setCurrentContext:self.context];
    
    CGImageRef brushImage = self.brush.CGImage;
    
    // Get the width and height of the image
    size_t width = CGImageGetWidth(brushImage);
    size_t height = CGImageGetHeight(brushImage);

    // Allocate  memory needed for the bitmap context
    GLubyte *brushData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));
    // Use  the bitmatp creation function provided by the Core Graphics framework. 
    CGContextRef brushContext = CGBitmapContextCreate(brushData, width, height, 8, width * 4, CGImageGetColorSpace(brushImage), kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast);
    // After you create the context, you can draw the  image to the context.
    CGContextDrawImage(brushContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), brushImage);
    // You don't need the context at this point, so you need to release it to avoid memory leaks.
    CGContextRelease(brushContext);
    // Use OpenGL ES to generate a name for the texture.
    glGenTextures(1, &brushTexture);
    // Bind the texture name. 
    glBindTexture(GL_TEXTURE_2D, brushTexture);
    // Set the texture parameters to use a minifying filter and a linear filer (weighted average)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    // Specify a 2D texture image, providing the a pointer to the image data in memory
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, brushData);
    // Release  the image data; it's no longer needed
    free(brushData);
    
    glEnable(GL_POINT_SPRITE_OES);
    glTexEnvf(GL_POINT_SPRITE_OES, GL_COORD_REPLACE_OES, GL_TRUE);
    glPointSize(width / self.canvasOptions.brushScale);
}

@end
