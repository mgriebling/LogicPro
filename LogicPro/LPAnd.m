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

- (CGFloat)naturalHeight {
    return IHEIGHT_AND;
}

- (CGFloat)naturalWidth {
    return IWIDTH_AND;
}

- (NSArray *)pins {
    if (!super.pins) {
        NSMutableArray *pins = [NSMutableArray array];
        
        // create pins for this gate
        CGFloat spacing = self.bounds.size.height / 4.0;
        [pins addObject:[[LPPin alloc] initWithPosition:CGPointMake(0, spacing)]];
        [pins addObject:[[LPPin alloc] initWithPosition:CGPointMake(0, 3*spacing)]];
        [pins addObject:[[LPPin alloc] initWithPosition:CGPointMake(self.bounds.size.width, 2*spacing)]];
        super.pins = pins;
    }
    return super.pins;
}

- (UIBezierPath *)bezierPathForDrawing {
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat scale = MIN(self.bounds.size.width/IWIDTH_AND, self.bounds.size.height/IHEIGHT_AND);
    
    [path setLineWidth:[self strokeWidth]];
    [LPGraphicPrimitives drawAndAtPoint:self.bounds.origin withPath:path atScale:scale];
    
    return path;
    
}

- (NSString *)description {
    NSString *text = [NSString stringWithFormat:@"%d-Input And", self.pins.count-1];
    return text;
}


@end
