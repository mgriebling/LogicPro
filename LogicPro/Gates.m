//
//  Gates.m
//  LogicPro
//
//  Created by Michael Griebling on 16Jan2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "Gates.h"

@implementation Gates

- (id)init {
    self = [super init];
    if (self) {
        _list = [[NSMutableArray alloc] initWithCapacity:50];
    }
    return self;
}

+ (UIImage *)getImageForGate:(NSInteger)gate {
    switch (gate) {
        case 0:
            return [UIImage imageNamed:@"And.png"];
            break;
            
        case 1:
            return [UIImage imageNamed:@"Or.png"];
            break;
            
        case 2:
            return [UIImage imageNamed:@"Not.png"];
            break;
            
        case 3:
            return [UIImage imageNamed:@"XOr.png"];
            break;
            
        default:
            return nil;
            break;
    }
}

+ (NSString *)getNameForGate:(NSInteger)gate {
    switch (gate) {
        case 0:
            return @"And Gate";
            break;
            
        case 1:
            return @"Or Gate";
            break;
            
        case 2:
            return @"Not Gate";
            break;
            
        case 3:
            return @"Xor Gate";
            break;
            
        default:
            return @"";
            break;
    }
}

+ (NSInteger)total {
    return 4;
}

- (Gate *)findMatch:(CGPoint)position {
    for (Gate *gate in _list) {
        CGSize gsize = [Gates getImageForGate:gate.gate].size;
        CGRect grect = CGRectMake(gate.location.x - gsize.width/4, gate.location.y - gsize.height/4, gsize.width/2, gsize.height/2);;
        if (CGRectContainsPoint(grect, position)) {
            return gate;
        } 
    }
    return nil;
}

@end


@implementation Gate

- (id)initWithGate:(NSInteger)gate andLocation:(CGPoint)location {
    _gate = gate;
    _location = location;
    _selected = NO;
    return self;
}

@end