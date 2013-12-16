//
//  LPBuffer.m
//  LogicPro
//
//  Created by Mike Griebling on 10 Dec 2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPBuffer.h"
#import "LPGraphicPrimitives.h"

@implementation LPBuffer

const CGFloat IWIDTH_BUFFER = 132.5;
const CGFloat IHEIGHT_BUFFER = 180.0;

- (BOOL)canMakeNaturalSize {
    return YES;
}

- (void)makeNaturalSize {
    [self setBounds:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, IWIDTH_BUFFER/5, IHEIGHT_BUFFER/5)];
}

- (UIBezierPath *)bezierPathForDrawing {
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat scale = MIN(self.bounds.size.width/IWIDTH_BUFFER, self.bounds.size.height/IHEIGHT_BUFFER);
    
    [path setLineWidth:[self strokeWidth]];
    [LPGraphicPrimitives drawBufferAtPoint:self.bounds.origin withPath:path atScale:scale];

    return path;
    
}

- (NSString *)description {
    return @"Buffer Gate";
}


- (BOOL)isContentsUnderPoint:(CGPoint)point {
    
    // Just check to see if the point is in the path.
    return [[self bezierPathForDrawing] containsPoint:point];
    
}

@end
