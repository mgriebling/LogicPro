//
//  GateCollectionViewController.m
//  LogicPro
//
//  Created by Mike Griebling on 16.1.2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPToolPaletteController.h"
#import "UIBezierPath+Image.h"
#import "LPAnd.h"
#import "LPOr.h"
#import "LPXOr.h"
#import "LPNand.h"
#import "LPNor.h"
#import "LPBuffer.h"
#import "LPNot.h"
#import "LPXNor.h"

@interface LPToolPaletteController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@end

NSString *LPSelectedToolDidChangeNotification = @"LPSelectedToolDidChange";

static LPToolPaletteController *sharedToolPaletteController = nil;

@implementation LPToolPaletteController {
    NSUInteger _currentSelection;
}

+ (id)sharedToolPaletteController {
    if (!sharedToolPaletteController) {
        sharedToolPaletteController = [[LPToolPaletteController allocWithZone:NULL] init];
    }
    return sharedToolPaletteController;
}

- (Class)classForIndex:(NSUInteger)index {
    Class theClass = nil;
    //    LPOrGate = 0,
    //    LPNorGate,
    //    LPAndGate,
    //    LPNandGate,
    //    LPXOrGate,
    //    LPXNorGate,
    //    LPBufferGate,
    //    LPInverterGate,
    //    LPLine
    switch (index) {
        case LPAndGate:      theClass = [LPAnd class]; break;
        case LPOrGate:       theClass = [LPOr class];  break;
        case LPXOrGate:      theClass = [LPXOr class]; break;
        case LPNandGate:     theClass = [LPNand class]; break;
        case LPNorGate:      theClass = [LPNor class];  break;
        case LPXNorGate:     theClass = [LPXNor class]; break;
        case LPBufferGate:   theClass = [LPBuffer class];  break;
        case LPInverterGate: theClass = [LPNot class]; break;
        default: break;
    }

    return theClass;
}

- (Class)currentGateClass {
    return [self classForIndex:_currentSelection];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	sharedToolPaletteController = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return LPMAXGATES;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"GateCell" forIndexPath:indexPath];
    UIImageView *gateView = (UIImageView *)[cell viewWithTag:10];
    LPGate *gate = [[[self classForIndex:indexPath.item] alloc] init];
    [gate setBounds:gateView.bounds];
    UIBezierPath *gatePath = [gate bezierPathForDrawing];
    gateView.image = [gatePath strokeImageWithColor:[UIColor redColor]];
    
    UILabel *label = (UILabel *)[cell viewWithTag:20];
    label.text = gate.description;
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    _currentSelection = indexPath.item;
    [[NSNotificationCenter defaultCenter] postNotificationName:LPSelectedToolDidChangeNotification object:self];
    [self performSegueWithIdentifier:@"ExitGateSelection" sender:self];
}


@end
