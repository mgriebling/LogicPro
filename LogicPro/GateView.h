//
//  GateView.h
//  LogicPro
//
//  Created by Michael Griebling on 16Jan2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Gates;

@interface GateView : UIView

@property (strong, nonatomic) Gates *gates;
@property (nonatomic) CGFloat scale;

@end
