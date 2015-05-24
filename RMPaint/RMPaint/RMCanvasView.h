#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "RMPaintStep.h"

@class RMCanvasOptions;
@protocol RMCanvasViewDelegate;



@interface RMCanvasView : UIView {
    @private
    /// The pixel dimensions of the backbuffer
    GLint backingWidth;
    GLint backingHeight;
    
    /// OpenGL names for the renderbuffer and framebuffers used to render to this view
    GLuint viewRenderbuffer;
    GLuint viewFramebuffer;
    
    /// OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist)
    GLuint depthRenderbuffer;
    
    GLuint brushTexture;
}

/// Brush dimensions dimensions must be a power of 2.
@property (nonatomic, strong) UIImage *brush;
@property (nonatomic, strong) UIColor *brushColor;
@property (nonatomic, strong) RMCanvasOptions *canvasOptions;
@property (nonatomic, weak) id<RMCanvasViewDelegate> delegate;

- (void)erase;
- (void)renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end;

- (UIImage *)snapshotImage;

@end



@protocol RMCanvasViewDelegate <NSObject>

- (void)canvasView:(RMCanvasView *)canvasView painted:(RMPaintStep *)step;

@end