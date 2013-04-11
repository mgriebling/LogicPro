//
//  GateCollectionViewController.m
//  LogicPro
//
//  Created by Mike Griebling on 16.1.2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "GateCollectionViewController.h"
#import "Gates.h"
#import "GateView.h"

@interface GateCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@end

@implementation GateCollectionViewController {
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [Gates total];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"GateCell" forIndexPath:indexPath];
    GateView *gateView = (GateView *)[cell viewWithTag:10];
    Gate *gate = [[Gate alloc] initWithGate:indexPath.item andLocation:CGPointMake(0, 0)];
    gateView.gates = [[Gates alloc] init];
    [gateView.gates.list addObject:gate];
    UILabel *label = (UILabel *)[cell viewWithTag:20];
    label.text = [Gates getNameForGate:indexPath.row];
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    _currentSelection = indexPath.item;
    [self performSegueWithIdentifier:@"ExitGateSelection" sender:self];
}


@end
