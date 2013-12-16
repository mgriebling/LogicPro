//
//  LPPin.m
//  LogicPro
//
//  Created by Michael Griebling on 16Dec2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPPin.h"

@implementation LPPin {
    CGPoint point;
}

- (id)initWithPosition:(CGPoint)position {
    self = [super init];
    if (self) {
        point = position;
    }
    return self;
}

- (CGPoint)position {
    return point;
}

@end
