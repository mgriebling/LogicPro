//
//  LPAnd.m
//  LogicPro
//
//  Created by Michael Griebling on 9Dec2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPAnd.h"

@implementation LPAnd

- (UIBezierPath *)bezierPathForDrawing {
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint point = self.bounds.origin;
    CGFloat x = point.x;
    CGFloat y = point.y;
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat scale = MIN(w/277.0, h/217.0);
    
    [path setLineWidth:[self strokeWidth]];
    [path moveToPoint:point];
    [path addCurveToPoint:CGPointMake(x, y+216.0*scale) controlPoint1:point controlPoint2:CGPointMake(x, y+216.0*scale)];
    [path addCurveToPoint:CGPointMake(x+173.0*scale, y+217.0*scale) controlPoint1:CGPointMake(x, y+216.0*scale) controlPoint2:CGPointMake(x+173.0*scale, y+217.0*scale)];
    [path addCurveToPoint:CGPointMake(x+275.0*scale, y+106.0*scale) controlPoint1:CGPointMake(x+231.0*scale, y+217.0*scale) controlPoint2:CGPointMake(x+277.0*scale, y+156.0*scale)];
    [path addCurveToPoint:CGPointMake(x+174.0*scale, y) controlPoint1:CGPointMake(x+271.0*scale, y+83.75*scale) controlPoint2:CGPointMake(x+249.0*scale, y+11.0*scale)];
    [path addCurveToPoint:CGPointMake(x-7.0*scale, y) controlPoint1:CGPointMake(x+174.0*scale, y) controlPoint2:CGPointMake(x-7.0*scale, y)];
    
    return path;
    
}

- (NSString *)name {
    return @"And Gate";
}


- (BOOL)isContentsUnderPoint:(CGPoint)point {
    
    // Just check to see if the point is in the path.
    return [[self bezierPathForDrawing] containsPoint:point];
    
}

@end
