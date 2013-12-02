//
//  Gates.m
//  LogicPro
//
//  Created by Michael Griebling on 16Jan2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPGate.h"

//@implementation Gates
//
//- (id)init {
//    self = [super init];
//    if (self) _list = [NSMutableArray array];
//    return self;
//}
//
//+ (NSString *)getNameForGate:(GateType)gate {
//    switch (gate) {
//        case AND_GATE:      return @"And Gate";
//        case NAND_GATE:     return @"Nand Gate";
//        case OR_GATE:       return @"Or Gate";
//        case NOR_GATE:      return @"Nor Gate";
//        case BUFFER_GATE:   return @"Buffer Gate";
//        case INVERTER_GATE: return @"Inverter Gate";
//        case XOR_GATE:      return @"Xor Gate";
//        case XNOR_GATE:     return @"XNor Gate";
//        default:            return @"";
//    }
//}
//
//+ (NSInteger)total {
//    return MAX_GATES;
//}
//
//- (LPGate *)findMatch:(CGPoint)position {
////    for (Gate *gate in self.list) {
////        CGSize gsize = [Gates getImageForGate:gate.gate].size;
////        CGRect grect = CGRectMake(gate.location.x - gsize.width/4, gate.location.y - gsize.height/4, gsize.width/2, gsize.height/2);;
////        if (CGRectContainsPoint(grect, position)) {
////            return gate;
////        } 
////    }
//    return nil;
//}
//
//@end


@implementation LPGate

- (id)initWithLocation:(CGPoint)location {
//    _location = location;
//    _selected = NO;
//    UIImage *image;
    return self;
}

@end