//
//  LPZoomingScrollView.m
//  LogicPro
//
//  Created by Michael Griebling on 10Dec2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPZoomingScrollView.h"

// The name of the binding supported by this class, in addition to the ones whose support is inherited from NSView.
NSString *LPZoomingScrollViewFactor = @"factor";

@interface LPZoomingScrollView ()

@property (nonatomic)CGFloat factor;

@end

@implementation LPZoomingScrollView {
    // The current zoom factor. This instance variable isn't actually read by any SKTZoomingScrollView code and wouldn't be necessary if it weren't for an oddity in the default implementation of key-value binding (KVB): -[NSObject(NSKeyValueBindingCreation) bind:toObject:withKeyPath:options:] sends the receiver a -valueForKeyPath: message, even though the returned value is typically not interesting. With this here key-value coding (KVC) direct instance variable access makes -valueForKeyPath: happy.
    CGFloat _factor;
}


- (void)setFactor:(CGFloat)factor {
    
    //The default implementation of key-value binding is informing this object that the value to which our "factor" property is bound has changed. Record the value, and apply the zoom factor by fooling with the bounds of the clip view that every scroll view has. (We leave its frame alone.)
    _factor = factor;
    UIView *clipView = [[self documentView] superview];
    CGSize clipViewFrameSize = [clipView frame].size;
    [clipView setBoundsSize:CGMakeSize((clipViewFrameSize.width / factor), (clipViewFrameSize.height / factor))];
    
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


// An override of the NSScrollView method.
//- (void)tile {
//    
//    // This class lives to put a popup button next to a horizontal scroll bar.
//    NSAssert([self hasHorizontalScroller], @"SKTZoomingScrollView doesn't support use without a horizontal scroll bar.");
//    
//    // Do NSScrollView's regular tiling, and find out where it left the horizontal scroller.
//    [super tile];
//    NSScroller *horizontalScroller = [self horizontalScroller];
//    NSRect horizontalScrollerFrame = [horizontalScroller frame];
//    
//    // Place the zoom factor popup button to the left of where the horizontal scroller will go, creating it first if necessary, and leaving its width alone.
//    [self validateFactorPopUpButton];
//    NSRect factorPopUpButtonFrame = [_factorPopUpButton frame];
//    factorPopUpButtonFrame.origin.x = horizontalScrollerFrame.origin.x;
//    factorPopUpButtonFrame.origin.y = horizontalScrollerFrame.origin.y;
//    factorPopUpButtonFrame.size.height = horizontalScrollerFrame.size.height;
//    [_factorPopUpButton setFrame:factorPopUpButtonFrame];
//    
//    // Adjust the scroller's frame to make room for the zoom factor popup button next to it.
//    horizontalScrollerFrame.origin.x += factorPopUpButtonFrame.size.width;
//    horizontalScrollerFrame.size.width -= factorPopUpButtonFrame.size.width;
//    [horizontalScroller setFrame:horizontalScrollerFrame];
//    
//}

@end
