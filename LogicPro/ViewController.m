//
//  ViewController.m
//  LogicPro
//
//  Created by Mike Griebling on 28.9.2012.
//  Copyright (c) 2012 Computer Inspirations. All rights reserved.
//

#import "ViewController.h"
#import "LPBlock.h"
#import "LPToolPaletteController.h"
#import "LPGateView.h"
#import "UIBezierPath+Image.h"
#import "LPZoomingScrollView.h"
#import "LPScalingViewController.h"
#import "LPPin.h"

@interface ViewController () <UIScrollViewDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate>


@property (weak, nonatomic) IBOutlet UIButton *gateButton;
@property (strong, nonatomic) LPGateView *gateView;
@property (strong, nonatomic) IBOutlet LPZoomingScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *textScaleButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *titleButton;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;

@end

@implementation ViewController {

    NSUInteger lastGateType;
    LPBlock *activeObject;
}

- (void) setScrollView:(UIScrollView *)scrollView {
    _scrollView = (LPZoomingScrollView *)scrollView;
    _scrollView.delegate = self;
    [_scrollView addSubview:self.gateView];
    _scrollView.contentSize = self.gateView.frame.size;
    
    // panning with two fingers
//    UIPanGestureRecognizer *panGR = _scrollView.panGestureRecognizer;
//    panGR.minimumNumberOfTouches = 2;
//    panGR.maximumNumberOfTouches = 2;
//    _scrollView.pagingEnabled = NO;
    
    // tap gesture for selecting and creating objects
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedView:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [_scrollView addGestureRecognizer:tapGesture];
    
    // single-finger pan to move active objects
//    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragInView:)];
//    panGesture.minimumNumberOfTouches = 1;
//    panGesture.maximumNumberOfTouches = 1;
//    panGesture.delegate = self;
//    [_scrollView addGestureRecognizer:panGesture];
    
    // stroke gesture to delete object
    UISwipeGestureRecognizer *swipGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swippedView:)];
    swipGesture.numberOfTouchesRequired = 1;
    swipGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    swipGesture.delegate = self;
    [_scrollView addGestureRecognizer:swipGesture];
}

- (LPGateView *)gateView {
    if (!_gateView) {
        _gateView = [[LPGateView alloc] initWithFrame:CGRectMake(0, 0, 1000.0, 1000.0)];
        [_gateView setContentMode:UIViewContentModeRedraw];
        [_gateView setContentScaleFactor:1.0];
    }
    return _gateView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.scrollView.minimumZoomScale = 0.25;
    self.scrollView.maximumZoomScale = 12.0;
    self.scrollView.zoomScale = 1.0;
    [self scrollViewDidZoom:self.scrollView];
    lastGateType = LPNandGate;
    [self.gateButton setImage:[self imageForGate:lastGateType] forState:UIControlStateNormal];
}

- (void)setTitle:(NSString *)title {
    if (self.titleButton) {
        self.titleButton.title = [NSString stringWithFormat:@"LogicPro™ (%@)", title];
    } else {
        self.navigationItem.title = [NSString stringWithFormat:@"LogicPro™ (%@)", title];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    CGRect scrollViewFrame = self.scrollView.frame;
//    CGFloat scaleWidth = scrollViewFrame.size.width / self.scrollView.contentSize.width;
//    CGFloat scaleHeight = scrollViewFrame.size.height / self.scrollView.contentSize.height;
//    CGFloat minScale = MIN(scaleHeight, scaleWidth);
//    self.drawingScale.text = [NSString stringWithFormat:@"%.0f%%", self.scrollView.zoomScale*100.0];
    [self setTitle:@"Unnamed1"];
}

- (UIImage *)imageForGate:(NSUInteger)gateID {
    LPBlock *gate = [[[LPToolPaletteController classForGate:gateID] alloc] init];
    [gate makeNaturalSize];
    return [[gate bezierPathForDrawingWithPinLines] strokeImageWithColor:[UIColor blueColor]];
}

- (IBAction)exitGateSelection:(UIStoryboardSegue *)segue {
    if ([segue.identifier isEqualToString:@"ExitGateSelection"]) {
        LPToolPaletteController *gateSelection = segue.sourceViewController;
        if (gateSelection.currentGate != lastGateType) {
            lastGateType = gateSelection.currentGate;
            [self.gateButton setImage:[self imageForGate:lastGateType] forState:UIControlStateNormal];
        }
    }
}

- (IBAction)exitScaleSelection:(UIStoryboardSegue *)segue {
    if ([segue.identifier isEqualToString:@"ExitScaleSelection"]) {
        LPScalingViewController *scaleSelection = segue.sourceViewController;
        if (scaleSelection.scaling != self.scrollView.zoomScale) {
            self.scrollView.zoomScale = scaleSelection.scaling;
            [self scrollViewDidZoom:self.scrollView];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showGates"]) {
        LPToolPaletteController *gateSelection = segue.destinationViewController;
        gateSelection.currentGate = lastGateType;
    } else if ([segue.identifier isEqualToString:@"showScales"]) {
        
    }
}

#pragma mark - Alertview delegate method

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView cancelButtonIndex] != buttonIndex) {
//        [self.gates.list removeObject:activeObject];
        [self.gateView setNeedsDisplay];
        activeObject = nil;
    }
}

- (void)swippedView:(UISwipeGestureRecognizer *)sender {
//    CGPoint position = [sender locationInView:_drawView];
    NSLog(@"swipped");
    LPBlock *gate = nil;  //[self.gates findMatch:position];
    if (gate) {
//        gate.selected = YES;
        activeObject = gate;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete Gate?" message:@"Are you sure you want to delete the selected gate?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
        [alert show];
    }
}

- (void)tappedView:(UITapGestureRecognizer *)sender {
    [self.gateView insertGateWithClass:[LPToolPaletteController classForGate:lastGateType] andEvent:sender];

//    if (gate.selected) activeObject = gate;
    [self.gateView setNeedsDisplay];
}

- (void)dragInView:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateChanged || sender.state == UIGestureRecognizerStateBegan) {
//        CGPoint position = [sender locationInView:self.drawView];
        if (activeObject) {
//            activeObject.location = position;
            [self.gateView setNeedsDisplay];
        }
    } else if (sender.state == UIGestureRecognizerStateEnded) {
//        activeObject.selected = NO;
        activeObject = nil;
        [self.gateView setNeedsDisplay];
    }
}

#pragma mark - UIScrollView Delegate methods
- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.gateView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    self.textScaleButton.title = [NSString stringWithFormat:@"%.0f%%", scrollView.zoomScale*100.0];
    [self.gateView setContentScaleFactor:scrollView.zoomScale];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    return NO;
}

#pragma mark - UIGestureRecognizer delegate method

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

@end
