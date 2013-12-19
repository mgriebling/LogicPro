//
//  LPPin.h
//  LogicPro
//
//  Created by Michael Griebling on 16Dec2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    PIN_INPUT = 0,
    PIN_OUTPUT = 1,
    PIN_TRISTATE = 2,
    PIN_OPENCOLLECTOR = 3
} PinType;


@interface LPPin : NSObject

- (PinType)pinType;
- (id)initWithPosition:(CGPoint)position;
- (id)initWithPosition:(CGPoint)position andType:(PinType)pinType;
- (CGPoint)position;

@end
