//
//  LPBuffer.m
//  LogicPro
//
//  Created by Mike Griebling on 10 Dec 2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPBuffer.h"

@implementation LPBuffer

const CGFloat IWIDTH_BUFFER = 132.5;
const CGFloat IHEIGHT_BUFFER = 180.0;

- (BOOL)canMakeNaturalSize {
    return YES;
}

- (void)makeNaturalSize {
    [self setBounds:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, IWIDTH_BUFFER/5, IHEIGHT_BUFFER/5)];
}

- (UIBezierPath *)bezierPathForDrawing {
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint point = self.bounds.origin;
    CGFloat x = point.x;
    CGFloat y = point.y;
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat scale = MIN(w/IWIDTH_BUFFER, h/IHEIGHT_BUFFER);
    
    [path setLineWidth:[self strokeWidth]];
    [path moveToPoint:point];
    [path addLineToPoint:CGPointMake(x, y+180.0*scale)];
    [path addLineToPoint:CGPointMake(x+132.5*scale, y+90.0*scale)];
    [path addLineToPoint:point];
    return path;
    
}

- (NSString *)description {
    return @"Buffer Gate";
}


- (BOOL)isContentsUnderPoint:(CGPoint)point {
    
    // Just check to see if the point is in the path.
    return [[self bezierPathForDrawing] containsPoint:point];
    
}

@end
