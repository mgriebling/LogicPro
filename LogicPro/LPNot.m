//
//  LPNot.m
//  LogicPro
//
//  Created by Mike Griebling on 10 Dec 2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPNot.h"

@implementation LPNot

- (UIBezierPath *)bezierPathForDrawing {
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint point = self.bounds.origin;
    CGFloat x = point.x;
    CGFloat y = point.y;
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat scale = MIN(w/132.5, h/180.0);
    
    //    CGContextAddEllipseInRect(context, CGRectMake(point.x, point.y, 50*scale, 50*scale));
    //    CGContextDrawPath(context, kCGPathStroke);
    
    //    CGContextMoveToPoint(context, point.x, point.y);    
    //    CGContextAddLineToPoint(context, point.x,             point.y+180.0*scale);
    //    CGContextAddLineToPoint(context, point.x+132.5*scale, point.y+90.0*scale);
    //    CGContextAddLineToPoint(context, point.x-5.0*scale,   point.y-5.0*scale);
    
    [path setLineWidth:[self strokeWidth]];
    [path moveToPoint:point];
    [path addLineToPoint:CGPointMake(x, y+180.0*scale)];
    [path addLineToPoint:CGPointMake(x+132.5*scale, y+90.0*scale)];
    [path addLineToPoint:point];
    
    //    [self drawNotInContext:context atPoint:CGPointMake(point.x+135.0*scale, point.y+65.0*scale) withScale:scale];
    CGPathRef circle = path.CGPath;
    CGMutablePathRef mcircle = CGPathCreateMutableCopy(circle);
    CGPathAddEllipseInRect(mcircle, NULL, CGRectMake(x+135.0*scale, y+65.0*scale, 50*scale, 50*scale));
    path.CGPath = mcircle;
    CGPathRelease(mcircle);
    return path;
    
}

- (NSString *)description {
    return @"Inverter Gate";
}


- (BOOL)isContentsUnderPoint:(CGPoint)point {
    
    // Just check to see if the point is in the path.
    return [[self bezierPathForDrawing] containsPoint:point];
    
}

@end
