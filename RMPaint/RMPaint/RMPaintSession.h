//
//  RMPaintSession.h
//  GLPaint
//
//  Created by Hermes Pique on 5/9/12.
//	Copyright 2012 Robot Media SL <http://www.robotmedia.net>. All rights reserved.
//
//	This file is part of RMPaint.
//
//	RMPaint is free software: you can redistribute it and/or modify
//	it under the terms of the GNU Lesser Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	RMPaint is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU Lesser Public License for more details.
//
//	You should have received a copy of the GNU Lesser Public License
//	along with RMPaint.  If not, see <http://www.gnu.org/licenses/>.

#import <Foundation/Foundation.h>

@class RMCanvasView;
@class RMPaintStep;



@interface RMPaintSession : NSObject

@property (nonatomic, strong, readonly) NSArray *steps;

- (id)initWithDefaultsWithKey:(NSString *)key;

- (void)startOperation;
- (void)addStep:(RMPaintStep *)step;
- (void)endOperation;

- (void)removeLastOperation;

- (void)paintInCanvas:(RMCanvasView *)canvas;

- (void)clear;
- (void)saveToDefaultsWithKey:(NSString *)key;

@end
