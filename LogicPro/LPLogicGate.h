//
//  LPLogicGate.h
//  LogicPro
//
//  Created by Mike Griebling on 19 Dec 2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPGate.h"

@interface LPLogicGate : LPGate

- (void)setNumberOfInputs:(NSUInteger)numberOfInputs;
- (CGFloat)naturalWidth;
- (CGFloat)naturalHeight;

@end
