//
//  LPOr.m
//  LogicPro
//
//  Created by Mike Griebling on 10 Dec 2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPOr.h"
#import "LPGraphicPrimitives.h"

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
    CGFloat scale = MIN(self.bounds.size.width/IWIDTH_OR, self.bounds.size.height/IHEIGHT_OR);
    
    [path setLineWidth:[self strokeWidth]];
    [LPGraphicPrimitives drawOrAtPoint:self.bounds.origin withPath:path atScale:scale];
    
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
