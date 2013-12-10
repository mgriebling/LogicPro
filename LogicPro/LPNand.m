//
//  LPNand.m
//  LogicPro
//
//  Created by Mike Griebling on 10 Dec 2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPNand.h"

@implementation LPNand

- (UIBezierPath *)bezierPathForDrawing {
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint point = self.bounds.origin;
    CGFloat x = point.x;
    CGFloat y = point.y;
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat scale = MIN(w/300.0, h/192.0);
    
    [path setLineWidth:[self strokeWidth]];
    [path moveToPoint:point];
    [path addCurveToPoint:CGPointMake(x, y+216.0*scale) controlPoint1:point controlPoint2:CGPointMake(x, y+216.0*scale)];
    [path addCurveToPoint:CGPointMake(x+173.0*scale, y+217.0*scale) controlPoint1:CGPointMake(x, y+216.0*scale) controlPoint2:CGPointMake(x+173.0*scale, y+217.0*scale)];
    [path addCurveToPoint:CGPointMake(x+275.0*scale, y+106.0*scale) controlPoint1:CGPointMake(x+231.0*scale, y+217.0*scale) controlPoint2:CGPointMake(x+277.0*scale, y+156.0*scale)];
    [path addCurveToPoint:CGPointMake(x+174.0*scale, y) controlPoint1:CGPointMake(x+271.0*scale, y+83.75*scale) controlPoint2:CGPointMake(x+249.0*scale, y+11.0*scale)];
    [path addCurveToPoint:CGPointMake(x-7.0*scale, y) controlPoint1:CGPointMake(x+174.0*scale, y) controlPoint2:CGPointMake(x-7.0*scale, y)];

    //    [self drawNotInContext:context atPoint:CGPointMake(point.x+275.0*scale, point.y+81.0*scale) withScale:scale];
    CGPathRef circle = path.CGPath;
    CGMutablePathRef mcircle = CGPathCreateMutableCopy(circle);
    CGPathAddEllipseInRect(mcircle, NULL, CGRectMake(x+275.0*scale, y+81.0*scale, 50*scale, 50*scale));
    path.CGPath = mcircle;
    CGPathRelease(mcircle);
    
    return path;
    
}

- (NSString *)description {
    return @"Nand Gate";
}


- (BOOL)isContentsUnderPoint:(CGPoint)point {
    
    // Just check to see if the point is in the path.
    return [[self bezierPathForDrawing] containsPoint:point];
    
}

@end
