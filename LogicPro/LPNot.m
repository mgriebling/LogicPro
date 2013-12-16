//
//  LPNot.m
//  LogicPro
//
//  Created by Mike Griebling on 10 Dec 2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPNot.h"
#import "LPGraphicPrimitives.h"

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
    CGFloat scale = MIN(self.bounds.size.width/IWIDTH_NOT, self.bounds.size.height/IHEIGHT_NOT);
    
    [path setLineWidth:[self strokeWidth]];
    [LPGraphicPrimitives drawBufferAtPoint:self.bounds.origin withPath:path atScale:scale];
    
    //    [self drawNotInContext:context atPoint:CGPointMake(point.x+135.0*scale, point.y+65.0*scale) withScale:scale];
    [LPGraphicPrimitives drawNotAtPoint:CGPointMake(self.bounds.origin.x+135.0*scale, self.bounds.origin.y+65.0*scale) withPath:path atScale:scale];
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
