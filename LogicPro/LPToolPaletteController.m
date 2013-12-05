//
//  GateCollectionViewController.m
//  LogicPro
//
//  Created by Mike Griebling on 16.1.2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPToolPaletteController.h"
#import "LPGate.h"
#import "LPGateView.h"

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
    //    LPOrGate = 0,
    //    LPNorGate,
    //    LPAndGate,
    //    LPNandGate,
    //    LPXOrGate,
    //    LPXNorGate,
    //    LPBufferGate,
    //    LPInverterGate,
    //    LPLine
    Class theClass = nil;
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
    LPGateView *gateView = (LPGateView *)[cell viewWithTag:10];
    LPGate *gate = [[[self classForIndex:indexPath.item] alloc] init];
//    gateView.scale = 0.6;
//    LPGate *gate = [[LPGate alloc] initWithGate:indexPath.item andLocation:CGPointMake(25, 5)];
//    gateView.gates = [[Gates alloc] init];
//    [gateView.gates.list addObject:gate];
    UILabel *label = (UILabel *)[cell viewWithTag:20];
//    label.text = [Gates getNameForGate:indexPath.row];
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    _currentSelection = indexPath.item;
    [[NSNotificationCenter defaultCenter] postNotificationName:LPSelectedToolDidChangeNotification object:self];
    [self performSegueWithIdentifier:@"ExitGateSelection" sender:self];
}


@end
