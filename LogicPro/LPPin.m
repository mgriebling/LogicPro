//
//  LPPin.m
//  LogicPro
//
//  Created by Michael Griebling on 16Dec2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPPin.h"

@implementation LPPin {
    CGPoint _point;
    PinType _pinType;
}

- (id)initWithPosition:(CGPoint)position andType:(PinType)pinType {
    self = [super init];
    if (self) {
        _point = position;
        _pinType = pinType;
    }
    return self;
}

- (id)initWithPosition:(CGPoint)position {
    return [self initWithPosition:position andType:PIN_INPUT];
}

- (CGPoint)position {
    return _point;
}

- (PinType)pinType {
    return _pinType;
}

@end
