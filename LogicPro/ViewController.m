//
//  ViewController.m
//  LogicPro
//
//  Created by Mike Griebling on 28.9.2012.
//  Copyright (c) 2012 Computer Inspirations. All rights reserved.
//

#import "ViewController.h"
#import "Gates.h"
#import "GateCollectionViewController.h"
#import "GateView.h"

@interface ViewController () <UIScrollViewDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *gateSymbol;
@property (strong, nonatomic) GateView *drawView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *drawingScale;
@property (strong, nonatomic) Gates *gates;

@end

@implementation ViewController {

    NSInteger lastGateType;
    Gate *activeObject;
}

- (Gates *)gates {
    if (!_gates) _gates = [[Gates alloc] init];
    return _gates;
}

- (void) setScrollView:(UIScrollView *)scrollView {
    _scrollView = scrollView;
    _scrollView.delegate = self;
    [_scrollView addSubview:self.drawView];
    _scrollView.contentSize = self.drawView.frame.size;
    
    // panning with two fingers
    UIPanGestureRecognizer *panGR = _scrollView.panGestureRecognizer;
    panGR.minimumNumberOfTouches = 2;
    panGR.maximumNumberOfTouches = 2;
    _scrollView.pagingEnabled = NO;
    
    // tap gesture for selecting and creating objects
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedView:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [_scrollView addGestureRecognizer:tapGesture];
    
    // single-finger pan to move active objects
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragInView:)];
    panGesture.minimumNumberOfTouches = 1;
    panGesture.maximumNumberOfTouches = 1;
    panGesture.delegate = self;
    [_scrollView addGestureRecognizer:panGesture];
    
    // stroke gesture to delete object
    UISwipeGestureRecognizer *swipGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swippedView:)];
    swipGesture.numberOfTouchesRequired = 1;
    swipGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    swipGesture.delegate = self;
    [_scrollView addGestureRecognizer:swipGesture];
}

- (GateView *)drawView {
    if (!_drawView) {
        _drawView = [[GateView alloc] init];
        _drawView.frame = (CGRect){.origin=CGPointMake(0, 0), .size=CGSizeMake(1000, 1000)};
        _drawView.backgroundColor = [UIColor whiteColor];
    }
    return _drawView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    lastGateType = 0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGRect scrollViewFrame = self.scrollView.frame;
    CGFloat scaleWidth = scrollViewFrame.size.width / self.scrollView.contentSize.width;
    CGFloat scaleHeight = scrollViewFrame.size.height / self.scrollView.contentSize.height;
    CGFloat minScale = MIN(scaleHeight, scaleWidth);
    self.scrollView.minimumZoomScale = minScale;
    
    self.scrollView.maximumZoomScale = 5.0;
    self.scrollView.zoomScale = 1.0;
    self.drawingScale.text = [NSString stringWithFormat:@"%.0f%%", self.scrollView.zoomScale*100.0];
    self.drawView.gates = self.gates;
}

- (IBAction)exitGateSelection:(UIStoryboardSegue *)segue {
    if ([segue.identifier isEqualToString:@"ExitGateSelection"]) {
        GateCollectionViewController *gateSelection = segue.sourceViewController;
        if (gateSelection.currentSelection >= 0) {
            lastGateType = gateSelection.currentSelection;
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showGates"]) {
        GateCollectionViewController *gateSelection = segue.destinationViewController;
        gateSelection.currentSelection = lastGateType;
    }
}

#pragma mark - Alertview delegate method

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView cancelButtonIndex] != buttonIndex) {
        [self.gates.list removeObject:activeObject];
        [self.drawView setNeedsDisplay];
        activeObject = nil;
    }
}

- (void)swippedView:(UISwipeGestureRecognizer *)sender {
    CGPoint position = [sender locationInView:_drawView];
    NSLog(@"swipped");
    Gate *gate = [self.gates findMatch:position];
    if (gate) {
        gate.selected = YES;
        activeObject = gate;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete Gate?" message:@"Are you sure you want to delete the selected gate?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
        [alert show];
    }
}

- (void)tappedView:(UITapGestureRecognizer *)sender {
    CGPoint position = [sender locationInView:self.drawView];
    Gate *gate = [self.gates findMatch:position];
    
    if (gate == nil) {
        gate = [[Gate alloc] initWithGate:lastGateType andLocation:position];
        [self.gates.list addObject:gate];
        gate.selected = YES;
    } else {
        gate.selected = !gate.selected;
    }

    if (gate.selected) activeObject = gate;
    [self.drawView setNeedsDisplay];
}

- (void)dragInView:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateChanged || sender.state == UIGestureRecognizerStateBegan) {
        CGPoint position = [sender locationInView:self.drawView];
        if (activeObject) {
            activeObject.location = position;
            [self.drawView setNeedsDisplay];
        }
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        activeObject.selected = NO;
        activeObject = nil;
        [self.drawView setNeedsDisplay];
    }
}

#pragma mark - UIScrollView Delegate methods
- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.drawView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    self.drawingScale.text = [NSString stringWithFormat:@"%.0f%%", scrollView.zoomScale*100.0];
    self.drawView.scale = scrollView.zoomScale;
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    return NO;
}

#pragma mark - UIGestureRecognizer delegate method

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

@end
