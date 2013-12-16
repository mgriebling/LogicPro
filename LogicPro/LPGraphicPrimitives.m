//
//  LPGraphicPrimitives.m
//  LogicPro
//
//  Created by Mike Griebling on 16 Dec 2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPGraphicPrimitives.h"

@implementation LPGraphicPrimitives

+ (void)drawShieldAtPoint:(CGPoint)pt withPath:(UIBezierPath *)path atScale:(CGFloat)scale  {
    CGFloat x = pt.x;
    CGFloat y = pt.y;
    [path moveToPoint:CGPointMake(x-50.0*scale, y)];
    [path addCurveToPoint:CGPointMake(x-15.0*scale, y+112.0*scale) controlPoint1:CGPointMake(x-34.5*scale, y+24.5*scale) controlPoint2:CGPointMake(x-16.0*scale, y+73.5*scale)];
    [path addCurveToPoint:CGPointMake(x-50.0*scale, y+218.0*scale) controlPoint1:CGPointMake(x-12.0*scale, y+145.5*scale) controlPoint2:CGPointMake(x-39.0*scale, y+205.5*scale)];
}

+ (void)drawOrAtPoint:(CGPoint)pt withPath:(UIBezierPath *)path atScale:(CGFloat)scale {
    CGFloat x = pt.x;
    CGFloat y = pt.y;
    [path moveToPoint:pt];
    [path addCurveToPoint:CGPointMake(x+35.0*scale, y+112.0*scale) controlPoint1:CGPointMake(x+15.5*scale, y+24.5*scale) controlPoint2:CGPointMake(x+34.0*scale, y+73.5*scale)];
    [path addCurveToPoint:CGPointMake(x, y+218.0*scale) controlPoint1:CGPointMake(x+38.0*scale, y+145.5*scale) controlPoint2:CGPointMake(x+11.0*scale, y+205.5*scale)];
    [path addCurveToPoint:CGPointMake(x+142.0*scale, y+218.0*scale) controlPoint1:CGPointMake(x+142.0*scale, y+218.0*scale) controlPoint2:CGPointMake(x, y+218.0*scale)];
    [path addCurveToPoint:CGPointMake(x+303.0*scale, y+111.0*scale) controlPoint1:CGPointMake(x+218.0*scale, y+214.0*scale) controlPoint2:CGPointMake(x+301.0*scale, y+135.5*scale)];
    [path addCurveToPoint:CGPointMake(x+141.0*scale, y+4.0*scale) controlPoint1:CGPointMake(x+284.5*scale, y+69.5*scale) controlPoint2:CGPointMake(x+214.0*scale, y+14.5*scale)];
    [path addCurveToPoint:pt controlPoint1:CGPointMake(x+141.0*scale, y) controlPoint2:pt];
}

+ (void)drawAndAtPoint:(CGPoint)pt withPath:(UIBezierPath *)path atScale:(CGFloat)scale  {
    CGFloat x = pt.x;
    CGFloat y = pt.y;
    [path moveToPoint:pt];
    [path addCurveToPoint:CGPointMake(x, y+216.0*scale) controlPoint1:pt controlPoint2:CGPointMake(x, y+216.0*scale)];
    [path addCurveToPoint:CGPointMake(x+173.0*scale, y+217.0*scale) controlPoint1:CGPointMake(x, y+216.0*scale) controlPoint2:CGPointMake(x+173.0*scale, y+217.0*scale)];
    [path addCurveToPoint:CGPointMake(x+275.0*scale, y+106.0*scale) controlPoint1:CGPointMake(x+231.0*scale, y+217.0*scale) controlPoint2:CGPointMake(x+277.0*scale, y+156.0*scale)];
    [path addCurveToPoint:CGPointMake(x+174.0*scale, y) controlPoint1:CGPointMake(x+271.0*scale, y+83.75*scale) controlPoint2:CGPointMake(x+249.0*scale, y+11.0*scale)];
    [path addCurveToPoint:pt controlPoint1:CGPointMake(x+174.0*scale, y) controlPoint2:pt];
}

+ (void)drawNotAtPoint:(CGPoint)pt withPath:(UIBezierPath *)path atScale:(CGFloat)scale  {
    CGPathRef circle = path.CGPath;
    CGMutablePathRef mcircle = CGPathCreateMutableCopy(circle);
    CGPathAddEllipseInRect(mcircle, NULL, CGRectMake(pt.x, pt.y, 50*scale, 50*scale));
    path.CGPath = mcircle;
    CGPathRelease(mcircle);
}

+ (void)drawBufferAtPoint:(CGPoint)pt withPath:(UIBezierPath *)path atScale:(CGFloat)scale {
    CGFloat x = pt.x;
    CGFloat y = pt.y;
    [path moveToPoint:pt];
    [path addLineToPoint:CGPointMake(x, y+180.0*scale)];
    [path addLineToPoint:CGPointMake(x+132.5*scale, y+90.0*scale)];
    [path addLineToPoint:pt];
}

@end
