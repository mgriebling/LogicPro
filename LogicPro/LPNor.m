//
//  LPNor.m
//  LogicPro
//
//  Created by Mike Griebling on 10 Dec 2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPNor.h"
#import "LPGraphicPrimitives.h"

@implementation LPNor

const CGFloat IWIDTH_NOR = 353.0;
const CGFloat IHEIGHT_NOR = 221.0;

- (BOOL)canMakeNaturalSize {
    return YES;
}

- (void)makeNaturalSize {
    [self setBounds:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, IWIDTH_NOR/5, IHEIGHT_NOR/5)];
}

- (UIBezierPath *)bezierPathForDrawing {
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint point = self.bounds.origin;
    CGFloat x = point.x;
    CGFloat y = point.y;
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat scale = MIN(w/IWIDTH_NOR, h/IHEIGHT_NOR);
    
    [path setLineWidth:[self strokeWidth]];
    [LPGraphicPrimitives drawOrAtPoint:self.bounds.origin withPath:path atScale:scale];
 
    //    [self drawNotInContext:context atPoint:CGPointMake(point.x+303.0*scale, point.y+86.0*scale) withScale:scale];
    [LPGraphicPrimitives drawNotAtPoint:CGPointMake(x+303.0*scale, y+86.0*scale) withPath:path atScale:scale];
    
    return path;
    
}

- (NSString *)description {
    return @"Nor Gate";
}


- (BOOL)isContentsUnderPoint:(CGPoint)point {
    
    // Just check to see if the point is in the path.
    return [[self bezierPathForDrawing] containsPoint:point];
    
}

@end
