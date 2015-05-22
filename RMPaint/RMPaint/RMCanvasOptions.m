//
//  RMCanvasOptions.m
//  RMPaint
//
//  Created by Andreas Kompanez on 22.05.15.
//  Copyright (c) 2015 Robot Media SL. All rights reserved.
//

#import "RMCanvasOptions.h"



@implementation RMCanvasOptions

+ (instancetype)canvasOptionsDefaults
{
    RMCanvasOptions *options = [[self alloc] init];
    options.brushPixelStep = 3.0;
    options.brushScale = 2.0;
    
    return options;
}

@end
