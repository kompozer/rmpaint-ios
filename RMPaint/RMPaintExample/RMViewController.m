//
//  RMViewController.m
//  RMPaintExample
//
//  Created by Hermes Pique on 5/9/12.
//  Copyright (c) 2012 Robot Media SL. All rights reserved.
//

#import "RMViewController.h"

#define HISTORY_KEY @"history"

@interface RMViewController ()

@property (nonatomic, strong) RMPaintSession *session;

@end

@implementation RMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.session = [[RMPaintSession alloc] initWithDefaultsWithKey:HISTORY_KEY];
    RMCanvasView *canvas = [[RMGestureCanvasView alloc] initWithFrame:self.view.frame];
    canvas.session = self.session;
    canvas.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:canvas];
//    [self.session paintInCanvas:canvas];
    canvas.delegate = self;
    canvas.brush = [UIImage imageNamed:@"brush.png"];
    canvas.brushColor = [UIColor redColor];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (self.isBeingDismissed) {
        [self.session saveToDefaultsWithKey:HISTORY_KEY];
    }
}

- (void)canvasView:(RMCanvasView *)canvasView painted:(RMPaintStep *)step
{
//    [self.session addStep:step];
}

@end
