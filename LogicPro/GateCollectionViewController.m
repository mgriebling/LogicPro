//
//  GateCollectionViewController.m
//  LogicPro
//
//  Created by Mike Griebling on 16.1.2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "GateCollectionViewController.h"
#import "Gates.h"

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
    UIImageView *image = (UIImageView *)[cell viewWithTag:10];
    UILabel *label = (UILabel *)[cell viewWithTag:20];
    image.image = [Gates getImageForGate:indexPath.row];
    label.text = [Gates getNameForGate:indexPath.row];
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    _currentSelection = indexPath.row;
    [self performSegueWithIdentifier:@"ExitGateSelection" sender:self];
}


@end
