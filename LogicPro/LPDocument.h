//
//  LPDocument.h
//  LogicPro
//
//  Created by Michael Griebling on 2Dec2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LPMetadata;

// The keys described down below.
extern NSString *LPDocumentCanvasSizeKey;
extern NSString *LPDocumentGraphicsKey;

@interface LPDocument : UIDocument

// Data
@property (nonatomic, strong)NSArray *gates;

// Metadata
@property (nonatomic, strong)LPMetadata *metadata;

- (NSString *)description;

@end
