//
//  LPXOr.m
//  LogicPro
//
//  Created by Mike Griebling on 10 Dec 2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPXOr.h"
#import "LPGraphicPrimitives.h"

@implementation LPXOr

const CGFloat IWIDTH_XOR = 352.0;
const CGFloat IHEIGHT_XOR = 221.0;

- (BOOL)canMakeNaturalSize {
    return YES;
}

- (void)makeNaturalSize {
    [self setBounds:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, IWIDTH_XOR/5, IHEIGHT_XOR/5)];
}

- (CGRect)drawingBounds {
    CGRect bounds = [super drawingBounds];
    CGFloat scale = MIN(bounds.size.width/IWIDTH_XOR, bounds.size.height/IHEIGHT_XOR);
    
    // adjust bounds to account for shield
    bounds = CGRectInset(bounds, -50.0*scale, 0.0);
    return bounds;
}

- (UIBezierPath *)bezierPathForDrawing {
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat scale = MIN(self.bounds.size.width/IWIDTH_XOR, self.bounds.size.height/IHEIGHT_XOR);
    
    // essentially this is an Or gate
    [path setLineWidth:[self strokeWidth]];
    [LPGraphicPrimitives drawOrAtPoint:self.bounds.origin withPath:path atScale:scale];
    
    // draw shield portion of XOr
    [LPGraphicPrimitives drawShieldAtPoint:self.bounds.origin withPath:path atScale:scale];
    
    return path;
    
}

- (NSString *)description {
    return @"XOr Gate";
}


- (BOOL)isContentsUnderPoint:(CGPoint)point {
    
    // Just check to see if the point is in the path.
    return [[self bezierPathForDrawing] containsPoint:point];
    
}

@end
