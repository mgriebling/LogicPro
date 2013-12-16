//
//  LPXNor.m
//  LogicPro
//
//  Created by Mike Griebling on 10 Dec 2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPXNor.h"
#import "LPGraphicPrimitives.h"

@implementation LPXNor

const CGFloat IWIDTH_XNOR = 403.0;
const CGFloat IHEIGHT_XNOR = 221.0;

- (BOOL)canMakeNaturalSize {
    return YES;
}

- (void)makeNaturalSize {
    [self setBounds:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, IWIDTH_XNOR/5, IHEIGHT_XNOR/5)];
}

- (CGRect)drawingBounds {
    CGRect bounds = [super drawingBounds];
    CGFloat scale = MIN(bounds.size.width/IWIDTH_XNOR, bounds.size.height/IHEIGHT_XNOR);
    
    // adjust bounds to account for shield
    bounds = CGRectInset(bounds, -50.0*scale, 0.0);
    return bounds;
}

- (UIBezierPath *)bezierPathForDrawing {
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint point = self.bounds.origin;
    CGFloat x = point.x;
    CGFloat y = point.y;
    CGFloat scale = MIN(self.bounds.size.width/IWIDTH_XNOR, self.bounds.size.height/IHEIGHT_XNOR);
    
    [path setLineWidth:[self strokeWidth]];
    [LPGraphicPrimitives drawOrAtPoint:self.bounds.origin withPath:path atScale:scale];
    
    //    [self drawShieldInContext:context atPoint:CGPointMake(point.x-50.0*scale, point.y) withScale:scale];
    [LPGraphicPrimitives drawShieldAtPoint:self.bounds.origin withPath:path atScale:scale];
    
    //    [self drawNotInContext:context atPoint:CGPointMake(point.x+303.0*scale, point.y+86.0*scale) withScale:scale];
    [LPGraphicPrimitives drawNotAtPoint:CGPointMake(x+303.0*scale, y+86.0*scale) withPath:path atScale:scale];
    
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
