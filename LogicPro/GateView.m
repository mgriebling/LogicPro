//
//  GateView.m
//  LogicPro
//
//  Created by Michael Griebling on 16Jan2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "GateView.h"
#import "Gates.h"

@implementation GateView

@synthesize scale = _scale;

#define NICE_SIZE  (0.25)

- (void)setScale:(CGFloat)scale {
    // redraw when the scale changes
    if (scale != _scale) {
        _scale = scale * NICE_SIZE;      // scale by 0.25 so 1.0 give a nice size
        [self setNeedsDisplay];
    }
}

- (CGFloat)scale {
    if (!_scale) _scale = NICE_SIZE;
    return _scale;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawBufferInContext:(CGContextRef)context atPoint:(CGPoint)point withScale:(CGFloat)scale {
    CGContextMoveToPoint(context, point.x, point.y);
    CGContextAddLineToPoint(context, point.x,             point.y+180.0*scale);
    CGContextAddLineToPoint(context, point.x+132.5*scale, point.y+90.0*scale);
    CGContextAddLineToPoint(context, point.x-5.0*scale,   point.y-5.0*scale);
    CGContextDrawPath(context, kCGPathStroke);
}

- (void)drawAndInContext:(CGContextRef)context atPoint:(CGPoint)point withScale:(CGFloat)scale {
    CGContextMoveToPoint(context,     point.x,             point.y);
    CGContextAddCurveToPoint(context, point.x,             point.y,             point.x,             point.y+216.0*scale, point.x,             point.y+216.0*scale);
    CGContextAddCurveToPoint(context, point.x,             point.y+216.0*scale, point.x+173.0*scale, point.y+217.0*scale, point.x+173.0*scale, point.y+217.0*scale);
    CGContextAddCurveToPoint(context, point.x+231.0*scale, point.y+217.0*scale, point.x+277.0*scale, point.y+156.0*scale, point.x+275.0*scale, point.y+106.0*scale);
    CGContextAddCurveToPoint(context, point.x+271.0*scale, point.y+83.75*scale, point.x+249.0*scale, point.y+11.0*scale,  point.x+174.0*scale, point.y);
    CGContextAddCurveToPoint(context, point.x+174.0*scale, point.y,             point.x-7.0*scale,   point.y,             point.x-7.0*scale,   point.y);
    CGContextDrawPath(context, kCGPathStroke);
}

- (void)drawOrInContext:(CGContextRef)context atPoint:(CGPoint)point withScale:(CGFloat)scale {
    CGContextMoveToPoint(context,     point.x,             point.y);
    CGContextAddCurveToPoint(context, point.x+15.5*scale,  point.y+24.5*scale,  point.x+34.0*scale,  point.y+73.5*scale,  point.x+31.0*scale,  point.y+112.0*scale);
    CGContextAddCurveToPoint(context, point.x+38.0*scale,  point.y+145.5*scale, point.x+11.0*scale,  point.y+205.5*scale, point.x+1.0*scale,   point.y+218.0*scale);
    CGContextAddCurveToPoint(context, point.x+0.5*scale,   point.y+221.1*scale, point.x+141.1*scale, point.y+220.3*scale, point.x+142.0*scale, point.y+215.0*scale);
    CGContextAddCurveToPoint(context, point.x+218.0*scale, point.y+214.0*scale, point.x+301.0*scale, point.y+135.5*scale, point.x+303.0*scale, point.y+111.0*scale);
    CGContextAddCurveToPoint(context, point.x+284.5*scale, point.y+69.5*scale,  point.x+214.0*scale, point.y+14.5*scale,  point.x+141.0*scale, point.y+4.0*scale);
    CGContextAddCurveToPoint(context, point.x+141.0*scale, point.y,             point.x-5.0*scale,   point.y,             point.x-5.0*scale,   point.y);
    CGContextDrawPath(context, kCGPathStroke);
}

- (void)drawShieldInContext:(CGContextRef)context atPoint:(CGPoint)point withScale:(CGFloat)scale {
    CGContextMoveToPoint(context,     point.x,             point.y);
    CGContextAddCurveToPoint(context, point.x+15.5*scale,  point.y+24.5*scale,  point.x+34.0*scale,  point.y+73.5*scale,  point.x+31.0*scale,  point.y+112.0*scale);
    CGContextAddCurveToPoint(context, point.x+38.0*scale,  point.y+145.5*scale, point.x+11.0*scale,  point.y+205.5*scale, point.x+1.0*scale,   point.y+218.0*scale);
    CGContextDrawPath(context, kCGPathStroke);
}

- (void)drawXorInContext:(CGContextRef)context atPoint:(CGPoint)point withScale:(CGFloat)scale {
    [self drawOrInContext:context atPoint:point withScale:scale];
    [self drawShieldInContext:context atPoint:CGPointMake(point.x-50.0*scale, point.y) withScale:scale];
}

- (void)drawXNorInContext:(CGContextRef)context atPoint:(CGPoint)point withScale:(CGFloat)scale {
    [self drawNorInContext:context atPoint:point withScale:scale];
    [self drawShieldInContext:context atPoint:CGPointMake(point.x-50.0*scale, point.y) withScale:scale];    
}

- (void)drawNotInContext:(CGContextRef)context atPoint:(CGPoint)point withScale:(CGFloat)scale {
    CGContextAddEllipseInRect(context, CGRectMake(point.x, point.y, 50*scale, 50*scale));
    CGContextDrawPath(context, kCGPathStroke);
}

- (void)drawNorInContext:(CGContextRef)context atPoint:(CGPoint)point withScale:(CGFloat)scale {
    [self drawOrInContext:context atPoint:point withScale:scale];
    [self drawNotInContext:context atPoint:CGPointMake(point.x+303.0*scale, point.y+86.0*scale) withScale:scale];
}

- (void)drawNandInContext:(CGContextRef)context atPoint:(CGPoint)point withScale:(CGFloat)scale {
    [self drawAndInContext:context atPoint:point withScale:scale];
    [self drawNotInContext:context atPoint:CGPointMake(point.x+275.0*scale, point.y+81.0*scale) withScale:scale];
}

- (void)drawInverterInContext:(CGContextRef)context atPoint:(CGPoint)point withScale:(CGFloat)scale {
    [self drawBufferInContext:context atPoint:point withScale:scale];
    [self drawNotInContext:context atPoint:CGPointMake(point.x+135.0*scale, point.y+65.0*scale) withScale:scale];
}

- (void)drawShape:(Gate *)gate inContext:(CGContextRef)context withScale:(CGFloat)scale {
    switch (gate.gate) {
        case OR_GATE:       [self drawOrInContext:context atPoint:gate.location withScale:scale]; break;
        case NOR_GATE:      [self drawNorInContext:context atPoint:gate.location withScale:scale]; break;
        case AND_GATE:      [self drawAndInContext:context atPoint:gate.location withScale:scale]; break;
        case NAND_GATE:     [self drawNandInContext:context atPoint:gate.location withScale:scale]; break;
        case XOR_GATE:      [self drawXorInContext:context atPoint:gate.location withScale:scale]; break;
        case XNOR_GATE:     [self drawXNorInContext:context atPoint:gate.location withScale:scale]; break;
        case BUFFER_GATE:   [self drawBufferInContext:context atPoint:gate.location withScale:scale]; break;
        case INVERTER_GATE: [self drawInverterInContext:context atPoint:gate.location withScale:scale]; break;
        default: break;
    }
}

- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    NSLog(@"Scale = %f", self.scale);
    CGContextSetLineWidth(context, MAX(1,12*self.scale));
    for (Gate *gate in self.gates.list) {
        if (gate.selected) {
            CGContextSaveGState(context);
            CGContextSetRGBStrokeColor(context, 1, 0, 0, 1);
            [self drawShape:gate inContext:context withScale:self.scale];
            CGContextRestoreGState(context);
        } else {
            [self drawShape:gate inContext:context withScale:self.scale];
        }
    }
}

//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    NSInteger arg = 1;
//    NSLog(@"Swallowing touches...");
//}
//
//- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
//    NSLog(@"pointInside executed");
//    return NO;
//}
//
//- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
//    NSLog(@"hitTest executed");
//    return self;
//}

@end
