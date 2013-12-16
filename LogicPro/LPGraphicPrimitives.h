//
//  LPGraphicPrimitives.h
//  LogicPro
//
//  Created by Mike Griebling on 16 Dec 2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LPGraphicPrimitives : NSObject

+ (void)drawShieldAtPoint:(CGPoint)pt withPath:(UIBezierPath *)path atScale:(CGFloat)scale;
+ (void)drawOrAtPoint:(CGPoint)pt withPath:(UIBezierPath *)path atScale:(CGFloat)scale;
+ (void)drawAndAtPoint:(CGPoint)pt withPath:(UIBezierPath *)path atScale:(CGFloat)scale;
+ (void)drawNotAtPoint:(CGPoint)pt withPath:(UIBezierPath *)path atScale:(CGFloat)scale;
+ (void)drawBufferAtPoint:(CGPoint)pt withPath:(UIBezierPath *)path atScale:(CGFloat)scale;

@end
