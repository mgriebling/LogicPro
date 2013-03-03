//
//  GateView.m
//  LogicPro
//
//  Created by Michael Griebling on 16Jan2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "GateView.h"
#import "Gates.h"

@implementation GateView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    for (Gate *gate in _gates.list) {
        UIImage *gateImage = [Gates getImageForGate:gate.gate];
        CGRect gateRect = CGRectMake(gate.location.x - gateImage.size.width/4, gate.location.y - gateImage.size.height/4, gateImage.size.width/2, gateImage.size.height/2);
        
        // overlay the image with a colour
        if (gate.selected) {
            CGContextSaveGState(context);
            CGContextClipToMask(context, gateRect, gateImage.CGImage);
            CGContextSetFillColor(context, CGColorGetComponents([UIColor redColor].CGColor));
            CGContextFillRect(context, gateRect);
            CGContextSetBlendMode(context, kCGBlendModeOverlay);
            CGContextDrawImage(context, gateRect, gateImage.CGImage);
            CGContextRestoreGState(context);
        } else {
            CGContextDrawImage(context, gateRect, gateImage.CGImage);
        }
    }
}

//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    NSInteger arg = 1;
//    NSLog(@"Swallowing touches...");
//}
//
//- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
//    NSLog(@"pointInside executed");
//    return NO;
//}
//
//- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
//    NSLog(@"hitTest executed");
//    return self;
//}

@end
