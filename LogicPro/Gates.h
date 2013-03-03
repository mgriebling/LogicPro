//
//  Gates.h
//  LogicPro
//
//  Created by Michael Griebling on 16Jan2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Gate : NSObject

- (id)initWithGate:(NSInteger)gate andLocation:(CGPoint)location;

@property(nonatomic)CGPoint location;
@property(nonatomic)NSInteger gate;
@property(nonatomic)BOOL selected;

@end

@interface Gates : NSObject

+ (UIImage *)getImageForGate:(NSInteger)gate;
+ (NSString *)getNameForGate:(NSInteger)gate;
+ (NSInteger)total;

- (Gate *)findMatch:(CGPoint)position;

@property (strong, nonatomic) NSMutableArray *list;

@end

