//
//  LPNand.m
//  LogicPro
//
//  Created by Mike Griebling on 10 Dec 2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPNand.h"
#import "LPGraphicPrimitives.h"

@implementation LPNand

const CGFloat IWIDTH_NAND = 325.0;
const CGFloat IHEIGHT_NAND = 217.0;

- (BOOL)canMakeNaturalSize {
    return YES;
}

- (void)makeNaturalSize {
    [self setBounds:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, IWIDTH_NAND/5, IHEIGHT_NAND/5)];
}

- (UIBezierPath *)bezierPathForDrawing {
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint point = self.bounds.origin;
    CGFloat scale = MIN(self.bounds.size.width/IWIDTH_NAND, self.bounds.size.height/IHEIGHT_NAND);
    
    [path setLineWidth:[self strokeWidth]];
    [LPGraphicPrimitives drawAndAtPoint:point withPath:path atScale:scale];

    //    [self drawNotInContext:context atPoint:CGPointMake(point.x+275.0*scale, point.y+81.0*scale) withScale:scale];
    [LPGraphicPrimitives drawNotAtPoint:CGPointMake(point.x+275.0*scale, point.y+81.0*scale) withPath:path atScale:scale];
    
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
