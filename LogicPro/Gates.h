//
//  Gates.h
//  LogicPro
//
//  Created by Michael Griebling on 16Jan2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Gate : NSObject

typedef enum {OR_GATE, NOR_GATE, AND_GATE, NAND_GATE, XOR_GATE, XNOR_GATE, BUFFER_GATE, INVERTER_GATE, MAX_GATES} GateType;

- (id)initWithGate:(GateType)gate andLocation:(CGPoint)location;

@property(nonatomic)CGPoint location;
@property(nonatomic)GateType gate;
@property(nonatomic)BOOL selected;

@end

@interface Gates : NSObject

+ (NSString *)getNameForGate:(GateType)gate;
+ (NSInteger)total;

- (Gate *)findMatch:(CGPoint)position;

@property (strong, nonatomic) NSMutableArray *list;

@end

