//
//  RMCanvasOptions.h
//  RMPaint
//
//  Created by Andreas Kompanez on 22.05.15.
//  Copyright (c) 2015 Robot Media SL. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RMCanvasOptions : NSObject

@property (nonatomic, assign) float brushPixelStep;
@property (nonatomic, assign) float brushScale;

+ (instancetype)canvasOptionsDefaults;

@end
