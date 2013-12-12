//
//  LPXNor.m
//  LogicPro
//
//  Created by Mike Griebling on 10 Dec 2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPXNor.h"

@implementation LPXNor

const CGFloat IWIDTH = 403.0;
const CGFloat IHEIGHT = 221.0;

- (BOOL)canMakeNaturalSize {
    return YES;
}

- (void)makeNaturalSize {
    [self setBounds:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, IWIDTH/5, IHEIGHT/5)];
}

- (UIBezierPath *)bezierPathForDrawing {
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint point = self.bounds.origin;
    CGFloat x = point.x;
    CGFloat y = point.y;
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat scale = MIN(w/IWIDTH, h/IHEIGHT);
    
    [path setLineWidth:[self strokeWidth]];
    [path moveToPoint:point];
    [path addCurveToPoint:CGPointMake(x+31.0*scale, y+112.0*scale) controlPoint1:CGPointMake(x+15.5*scale, y+24.5*scale) controlPoint2:CGPointMake(x+34.0*scale, y+73.5*scale)];
    [path addCurveToPoint:CGPointMake(x+1.0*scale, y+218.0*scale) controlPoint1:CGPointMake(x+38.0*scale, y+145.5*scale) controlPoint2:CGPointMake(x+11.0*scale, y+205.5*scale)];
    [path addCurveToPoint:CGPointMake(x+141.1*scale, y+220.3*scale) controlPoint1:CGPointMake(x+142.0*scale, y+215.0*scale) controlPoint2:CGPointMake(x+0.5*scale, y+221.1*scale)];
    [path addCurveToPoint:CGPointMake(x+303.0*scale, y+111.0*scale) controlPoint1:CGPointMake(x+218.0*scale, y+214.0*scale) controlPoint2:CGPointMake(x+301.0*scale, y+135.5*scale)];
    [path addCurveToPoint:CGPointMake(x+141.0*scale, y+4.0*scale) controlPoint1:CGPointMake(x+284.5*scale, y+69.5*scale) controlPoint2:CGPointMake(x+214.0*scale, y+14.5*scale)];
    [path addCurveToPoint:point controlPoint1:CGPointMake(x+141.0*scale, y) controlPoint2:point];
    
    //    [self drawShieldInContext:context atPoint:CGPointMake(point.x-50.0*scale, point.y) withScale:scale];
    [path moveToPoint:CGPointMake(x-50.0*scale, y)];
    [path addCurveToPoint:CGPointMake(x-19.0*scale, y+112.0*scale) controlPoint1:CGPointMake(x-34.5*scale, y+24.5*scale) controlPoint2:CGPointMake(x-16.0*scale, y+73.5*scale)];
    [path addCurveToPoint:CGPointMake(x-49.0*scale, y+218.0*scale) controlPoint1:CGPointMake(x-12.0*scale, y+145.5*scale) controlPoint2:CGPointMake(x-39.0*scale, y+205.5*scale)];
    
    //    [self drawNotInContext:context atPoint:CGPointMake(point.x+303.0*scale, point.y+86.0*scale) withScale:scale];
    CGPathRef circle = path.CGPath;
    CGMutablePathRef mcircle = CGPathCreateMutableCopy(circle);
    CGPathAddEllipseInRect(mcircle, NULL, CGRectMake(x+303.0*scale, y+86.0*scale, 50*scale, 50*scale));
    path.CGPath = mcircle;
    CGPathRelease(mcircle);
    
    return path;
    
}

- (NSString *)description {
    return @"XNor Gate";
}


- (BOOL)isContentsUnderPoint:(CGPoint)point {
    
    // Just check to see if the point is in the path.
    return [[self bezierPathForDrawing] containsPoint:point];
    
}

@end
