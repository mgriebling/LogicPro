//
//  LPAnd.m
//  LogicPro
//
//  Created by Michael Griebling on 9Dec2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPAnd.h"
#import "LPGraphicPrimitives.h"
#import "LPPin.h"

@implementation LPAnd

const CGFloat IWIDTH_AND = 277.0;
const CGFloat IHEIGHT_AND = 217.0;

- (NSArray *)pins {
    if (!super.pins) {
        NSMutableArray *pins = [NSMutableArray array];
        
        // create pins for this gate
        LPPin *pin = [[LPPin alloc] initWithPosition:CGPointMake(0, 0)];
        [pins addObject:pin];
        super.pins = pins;
    }
    return super.pins;
}

- (BOOL)canMakeNaturalSize {
    return YES;
}

- (void)makeNaturalSize {
    [self setBounds:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, IWIDTH_AND/5, IHEIGHT_AND/5)];
}

- (UIBezierPath *)bezierPathForDrawing {
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat scale = MIN(self.bounds.size.width/IWIDTH_AND, self.bounds.size.height/IHEIGHT_AND);
    
    [path setLineWidth:[self strokeWidth]];
    [LPGraphicPrimitives drawAndAtPoint:self.bounds.origin withPath:path atScale:scale];
    
    return path;
    
}

- (NSString *)description {
    return @"And Gate";
}


- (BOOL)isContentsUnderPoint:(CGPoint)point {
    
    // Just check to see if the point is in the path.
    return [[self bezierPathForDrawing] containsPoint:point];
    
}

@end
