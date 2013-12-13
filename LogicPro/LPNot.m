//
//  LPNot.m
//  LogicPro
//
//  Created by Mike Griebling on 10 Dec 2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPNot.h"

@implementation LPNot

const CGFloat IWIDTH_NOT = 185.0;
const CGFloat IHEIGHT_NOT = 180.0;

- (BOOL)canMakeNaturalSize {
    return YES;
}

- (void)makeNaturalSize {
    [self setBounds:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, IWIDTH_NOT/5, IHEIGHT_NOT/5)];
}

- (UIBezierPath *)bezierPathForDrawing {
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint point = self.bounds.origin;
    CGFloat x = point.x;
    CGFloat y = point.y;
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat scale = MIN(w/IWIDTH_NOT, h/IHEIGHT_NOT);
    
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
