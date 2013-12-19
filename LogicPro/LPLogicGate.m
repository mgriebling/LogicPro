//
//  LPLogicGate.m
//  LogicPro
//
//  Created by Mike Griebling on 19 Dec 2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPLogicGate.h"

@implementation LPLogicGate

- (void)setNumberOfInputs:(NSUInteger)numberOfInputs {
    
}

- (BOOL)canMakeNaturalSize {
    return YES;
}

- (void)makeNaturalSize {
    [self setBounds:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, [self naturalWidth]/5, [self naturalHeight]/5)];
}

- (CGFloat)naturalWidth {
    // should be overridden
    return 0.0;
}

- (CGFloat)naturalHeight {
    // should be overridden
    return 0.0;
}


- (BOOL)isContentsUnderPoint:(CGPoint)point {
    
    // Just check to see if the point is in the path.
    return [[self bezierPathForDrawing] containsPoint:point];
    
}

@end
