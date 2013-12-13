//
//  LPOr.m
//  LogicPro
//
//  Created by Mike Griebling on 10 Dec 2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPOr.h"

@implementation LPOr

const CGFloat IWIDTH_OR = 303.0;
const CGFloat IHEIGHT_OR = 221.1;

- (BOOL)canMakeNaturalSize {
    return YES;
}

- (void)makeNaturalSize {
    [self setBounds:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, IWIDTH_OR/5, IHEIGHT_OR/5)];
}

- (UIBezierPath *)bezierPathForDrawing {
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint point = self.bounds.origin;
    CGFloat x = point.x;
    CGFloat y = point.y;
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat scale = MIN(w/IWIDTH_OR, h/IHEIGHT_OR);
    
    [path setLineWidth:[self strokeWidth]];
    [path moveToPoint:point];
    [path addCurveToPoint:CGPointMake(x+31.0*scale, y+112.0*scale) controlPoint1:CGPointMake(x+15.5*scale, y+24.5*scale) controlPoint2:CGPointMake(x+34.0*scale, y+73.5*scale)];
    [path addCurveToPoint:CGPointMake(x+1.0*scale, y+218.0*scale) controlPoint1:CGPointMake(x+38.0*scale, y+145.5*scale) controlPoint2:CGPointMake(x+11.0*scale, y+205.5*scale)];
    [path addCurveToPoint:CGPointMake(x+141.1*scale, y+220.3*scale) controlPoint1:CGPointMake(x+142.0*scale, y+215.0*scale) controlPoint2:CGPointMake(x+0.5*scale, y+221.1*scale)];
    [path addCurveToPoint:CGPointMake(x+303.0*scale, y+111.0*scale) controlPoint1:CGPointMake(x+218.0*scale, y+214.0*scale) controlPoint2:CGPointMake(x+301.0*scale, y+135.5*scale)];
    [path addCurveToPoint:CGPointMake(x+141.0*scale, y+4.0*scale) controlPoint1:CGPointMake(x+284.5*scale, y+69.5*scale) controlPoint2:CGPointMake(x+214.0*scale, y+14.5*scale)];    
    [path addCurveToPoint:CGPointMake(x, y) controlPoint1:CGPointMake(x+141.0*scale, y) controlPoint2:CGPointMake(x, y)];
    
    return path;
    
}

- (NSString *)description {
    return @"Or Gate";
}


- (BOOL)isContentsUnderPoint:(CGPoint)point {
    
    // Just check to see if the point is in the path.
    return [[self bezierPathForDrawing] containsPoint:point];
    
}

@end
