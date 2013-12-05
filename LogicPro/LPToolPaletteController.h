//
//  GateCollectionViewController.h
//  LogicPro
//
//  Created by Mike Griebling on 16.1.2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    LPOrGate = 0,
    LPNorGate,
    LPAndGate,
    LPNandGate,
    LPXOrGate,
    LPXNorGate,
    LPBufferGate,
    LPInverterGate,
    LPLine
};

@interface LPToolPaletteController : UICollectionViewController
@property (nonatomic) Class currentGateClass;
@property (nonatomic, strong)NSArray *gates;
@end

extern NSString *LPSelectedToolDidChangeNotification;
