//
//  LPOr.m
//  LogicPro
//
//  Created by Mike Griebling on 10 Dec 2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPOr.h"
#import "LPGraphicPrimitives.h"
#import "LPPin.h"

@implementation LPOr

- (CGFloat)naturalHeight {
    return 221.1;
}

- (CGFloat)naturalWidth {
    return 303.0;
}

- (NSArray *)pins {
    if (!super.pins) {
        NSMutableArray *pins = [NSMutableArray array];
        
        // create input/output pins for this gate
        CGFloat spacing = self.bounds.size.height / 4.0;
        CGFloat wSpace = self.bounds.size.width / 12.0;
        [pins addObject:[[LPPin alloc] initWithPosition:CGPointMake(wSpace, spacing)]];
        [pins addObject:[[LPPin alloc] initWithPosition:CGPointMake(wSpace, 3*spacing)]];
        [pins addObject:[[LPPin alloc] initWithPosition:CGPointMake(self.bounds.size.width, 2*spacing) andType:PIN_OUTPUT]];
        super.pins = pins;
    }
    return super.pins;
}

- (UIBezierPath *)bezierPathForDrawing {
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat scale = MIN(self.bounds.size.width/[self naturalWidth], self.bounds.size.height/[self naturalHeight]);
    
    [path setLineWidth:[self strokeWidth]];
    [LPGraphicPrimitives drawOrAtPoint:self.bounds.origin withPath:path atScale:scale];
    
    return path;
    
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%d-Input Or", self.pins.count-1];
}

@end

@implementation LPOr3

- (NSArray *)pins {
    if (super.pins.count == 3) {
        NSMutableArray *pins = [NSMutableArray array];
        
        // create input/output pins for this gate
        CGFloat spacing = self.bounds.size.height / 6.0;
        CGFloat wSpace = self.bounds.size.width / 12.0;
        [pins addObject:[[LPPin alloc] initWithPosition:CGPointMake(wSpace*0.7, spacing)]];
        [pins addObject:[[LPPin alloc] initWithPosition:CGPointMake(wSpace*1.4, 3*spacing)]];
        [pins addObject:[[LPPin alloc] initWithPosition:CGPointMake(wSpace*0.7, 5*spacing)]];
        [pins addObject:[[LPPin alloc] initWithPosition:CGPointMake(self.bounds.size.width, 3*spacing) andType:PIN_OUTPUT]];
        super.pins = pins;
    }
    return super.pins;
}

@end

@implementation LPOr4

- (NSArray *)pins {
    if (super.pins.count == 3) {
        NSMutableArray *pins = [NSMutableArray array];
        
        // create input/output pins for this gate
        CGFloat spacing = self.bounds.size.height / 8.0;
        CGFloat wSpace = self.bounds.size.width / 12.0;
        [pins addObject:[[LPPin alloc] initWithPosition:CGPointMake(wSpace*0.6, spacing)]];
        [pins addObject:[[LPPin alloc] initWithPosition:CGPointMake(wSpace*1.4, 3*spacing)]];
        [pins addObject:[[LPPin alloc] initWithPosition:CGPointMake(wSpace*1.4, 5*spacing)]];
        [pins addObject:[[LPPin alloc] initWithPosition:CGPointMake(wSpace*0.6, 7*spacing)]];
        [pins addObject:[[LPPin alloc] initWithPosition:CGPointMake(self.bounds.size.width, 4*spacing) andType:PIN_OUTPUT]];
        super.pins = pins;
    }
    return super.pins;
}

@end
