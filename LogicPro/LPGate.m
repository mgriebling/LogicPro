//
//  Gates.m
//  LogicPro
//
//  Created by Michael Griebling on 16Jan2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPGate.h"

//@implementation Gates
//
//- (id)init {
//    self = [super init];
//    if (self) _list = [NSMutableArray array];
//    return self;
//}
//
//+ (NSString *)getNameForGate:(GateType)gate {
//    switch (gate) {
//        case AND_GATE:      return @"And Gate";
//        case NAND_GATE:     return @"Nand Gate";
//        case OR_GATE:       return @"Or Gate";
//        case NOR_GATE:      return @"Nor Gate";
//        case BUFFER_GATE:   return @"Buffer Gate";
//        case INVERTER_GATE: return @"Inverter Gate";
//        case XOR_GATE:      return @"Xor Gate";
//        case XNOR_GATE:     return @"XNor Gate";
//        default:            return @"";
//    }
//}
//
//+ (NSInteger)total {
//    return MAX_GATES;
//}
//
//- (LPGate *)findMatch:(CGPoint)position {
////    for (Gate *gate in self.list) {
////        CGSize gsize = [Gates getImageForGate:gate.gate].size;
////        CGRect grect = CGRectMake(gate.location.x - gsize.width/4, gate.location.y - gsize.height/4, gsize.width/2, gsize.height/2);;
////        if (CGRectContaiCGPoint(grect, position)) {
////            return gate;
////        } 
////    }
//    return nil;
//}
//
//@end


// String constants declared in the header. A lot of them aren't used by any other class in the project, but it's a good idea to provide and use them, if only to help prevent typos in source code.
// Why are there @"drawingFill" and @"drawingStroke" keys here when @"isDrawingFill" and @"isDrawingStroke" would be a little more consistent with Cocoa convention for boolean values? Because we might want to add setter methods for these properties some day, and key-value coding isn't smart enough to ignore "is" when looking for setter methods, and having to give methods ugly names -setIsDrawingFill: and -setIsDrawingStroke: would be irritating. In general it's best to leave the "is" off the front of keys that identify boolean values.
NSString *LPGateCanSetDrawingFillKey = @"canSetDrawingFill";
NSString *LPGateCanSetDrawingStrokeKey = @"canSetDrawingStroke";
NSString *LPGateIsDrawingFillKey = @"drawingFill";
NSString *LPGateFillColorKey = @"fillColor";
NSString *LPGateIsDrawingStrokeKey = @"drawingStroke";
NSString *LPGateStrokeColorKey = @"strokeColor";
NSString *LPGateStrokeWidthKey = @"strokeWidth";
NSString *LPGateXPositionKey = @"xPosition";
NSString *LPGateYPositionKey = @"yPosition";
NSString *LPGateWidthKey = @"width";
NSString *LPGateHeightKey = @"height";
NSString *LPGateBoundsKey = @"bounds";
NSString *LPGateDrawingBoundsKey = @"drawingBounds";
NSString *LPGateDrawingContentsKey = @"drawingContents";
NSString *LPGateKeysForValuesToObserveForUndoKey = @"keysForValuesToObserveForUndo";

// Another constant that's declared in the header.
const NSInteger LPGateNoHandle = 0;

// A key that's used in Sketch's property-list-based file and pasteboard formats.
static NSString *LPGateClassNameKey = @"className";

// The values that might be returned by -[LPGate creationSizingHandle] and -[LPGate handleUnderPoint:], and that are understood by -[LPGate resizeByMovingHandle:toPoint:]. We provide specific indexes in this enumeration so make sure none of them are zero (that's LPGateNoHandle) and to make sure the flipping arrays in -[LPGate resizeByMovingHandle:toPoint:] work.
/*enum {
 LPGateUpperLeftHandle = 1,
 LPGateUpperMiddleHandle = 2,
 LPGateUpperRightHandle = 3,
 LPGateMiddleLeftHandle = 4,
 LPGateMiddleRightHandle = 5,
 LPGateLowerLeftHandle = 6,
 LPGateLowerMiddleHandle = 7,
 LPGateLowerRightHandle = 8,
 };*/

// The handles that graphics draw on themselves are 6 point by 6 point rectangles.
CGFloat LPGateHandleWidth = 6.0f;
CGFloat LPGateHandleHalfWidth = 6.0f / 2.0f;


@implementation LPGate

// An override of the superclass' designated initializer.
- (id)init {
    
    // Do the regular Cocoa thing.
    self = [super init];
    if (self) {
        
        // Set up decent defaults for a new graphic.
        _bounds = CGRectZero;
        _isDrawingFill = NO;
        _fillColor = [UIColor whiteColor];
        _isDrawingStroke = YES;
        _strokeColor = [UIColor blackColor];
        _strokeWidth = 1.0f;
        
    }
    return self;
    
}


// Conformance to the NSCopying protocol. LPGates are copyable for the sake of scriptability.
- (id)copyWithZone:(NSZone *)zone {
    
    // Pretty simple, but there's plenty of opportunity for mistakes. We use [self class] instead of LPGate so that overrides of this method can invoke super. We copy instead of retaining the fill and stroke color even though it probably doesn't make a difference because that's the correct thing to do for attributes (to-one relationships, that's another story). We don't copy _scriptingContainer because the copy doesn't have any scripting container until it's added to one.
    LPGate *copy = [[[self class] alloc] init];
    copy->_bounds = _bounds;
    copy->_isDrawingFill = _isDrawingFill;
    copy->_fillColor = [_fillColor copy];
    copy->_isDrawingStroke = _isDrawingStroke;
    copy->_strokeColor = [_strokeColor copy];
    copy->_strokeWidth = _strokeWidth;
    return copy;
    
}


- (void)dealloc {
    // Do the regular Cocoa thing.
    _strokeColor = nil;
    _fillColor = nil;
}


#pragma mark *** Private KVC-Compliance for Public Properties ***


// An override of the NSObject(NSKeyValueObservingCustomization) method.
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    
    // We don't want KVO autonotification for these properties. Because the setters for all of them invoke -setBounds:, and this class is KVO-compliant for "bounds," and we declared that the values of these properties depend on "bounds," we would up end up with double notifications for them. That would probably be unnoticable, but it's a little wasteful. Something you have to think about with codependent mutable properties like these (regardless of what notification mechanism you're using).
    BOOL automaticallyNotifies;
    if ([[NSSet setWithObjects:LPGateXPositionKey, LPGateYPositionKey, LPGateWidthKey, LPGateHeightKey, nil] containsObject:key]) {
        automaticallyNotifies = NO;
    } else {
        automaticallyNotifies = [super automaticallyNotifiesObserversForKey:key];
    }
    return automaticallyNotifies;
    
}


// In Mac OS 10.5 and newer KVO's dependency mechanism invokes class methods to find out what properties affect properties being observed, like these.
+ (NSSet *)keyPathsForValuesAffectingXPosition {
    return [NSSet setWithObject:LPGateBoundsKey];
}
+ (NSSet *)keyPathsForValuesAffectingYPosition {
    return [NSSet setWithObject:LPGateBoundsKey];
}
+ (NSSet *)keyPathsForValuesAffectingWidth {
    return [NSSet setWithObject:LPGateBoundsKey];
}
+ (NSSet *)keyPathsForValuesAffectingHeight {
    return [NSSet setWithObject:LPGateBoundsKey];
}
- (CGFloat)xPosition {
    return [self bounds].origin.x;
}
- (CGFloat)yPosition {
    return [self bounds].origin.y;
}
- (CGFloat)width {
    return [self bounds].size.width;
}
- (CGFloat)height {
    return [self bounds].size.height;
}
- (void)setXPosition:(CGFloat)xPosition {
    CGRect bounds = [self bounds];
    bounds.origin.x = xPosition;
    [self setBounds:bounds];
}
- (void)setYPosition:(CGFloat)yPosition {
    CGRect bounds = [self bounds];
    bounds.origin.y = yPosition;
    [self setBounds:bounds];
}
- (void)setWidth:(CGFloat)width {
    CGRect bounds = [self bounds];
    bounds.size.width = width;
    [self setBounds:bounds];
}
- (void)setHeight:(CGFloat)height {
    CGRect bounds = [self bounds];
    bounds.size.height = height;
    [self setBounds:bounds];
}


#pragma mark *** Convenience ***


+ (CGRect)boundsOfGraphics:(NSArray *)graphics {
    
    // The bounds of an array of graphics is the union of all of their bounds.
    CGRect bounds = CGRectZero;
    NSUInteger graphicCount = [graphics count];
    if (graphicCount>0) {
        bounds = [[graphics objectAtIndex:0] bounds];
        for (NSUInteger index = 1; index<graphicCount; index++) {
            bounds = CGRectUnion(bounds, [[graphics objectAtIndex:index] bounds]);
        }
    }
    return bounds;
    
}


+ (CGRect)drawingBoundsOfGraphics:(NSArray *)graphics {
    
    // The drawing bounds of an array of graphics is the union of all of their drawing bounds.
    CGRect drawingBounds = CGRectZero;
    NSUInteger graphicCount = [graphics count];
    if (graphicCount>0) {
        drawingBounds = [[graphics objectAtIndex:0] drawingBounds];
        for (NSUInteger index = 1; index<graphicCount; index++) {
            drawingBounds = CGRectUnion(drawingBounds, [[graphics objectAtIndex:index] drawingBounds]);
        }
    }
    return drawingBounds;
    
}


+ (void)translateGraphics:(NSArray *)graphics byX:(CGFloat)deltaX y:(CGFloat)deltaY {
    
    // Pretty simple.
    NSUInteger graphicCount = [graphics count];
    for (NSUInteger index = 0; index<graphicCount; index++) {
        LPGate *graphic = [graphics objectAtIndex:index];
        [graphic setBounds:CGRectOffset([graphic bounds], deltaX, deltaY)];
    }
    
}


#pragma mark *** Persistence ***


+ (NSArray *)graphicsWithPasteboardData:(NSData *)data error:(NSError **)outError {
    
    // Because this data may have come from outside this process, don't assume that any property list object we get back is the right type.
    NSArray *graphics = nil;
    NSArray *propertiesArray = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
    if (![propertiesArray isKindOfClass:[NSArray class]]) {
        propertiesArray = nil;
    }
    if (propertiesArray) {
        
        // Convert the array of graphic property dictionaries into an array of graphics.
        graphics = [self graphicsWithProperties:propertiesArray];
        
    } else if (outError) {
        
        // If property list parsing fails we have no choice but to admit that we don't know what went wrong. The error description returned by +[NSPropertyListSerialization propertyListFromData:mutabilityOption:format:errorDescription:] would be pretty technical, and not the sort of thing that we should show to a user.
//        *outError = SKTErrorWithCode(SKTUnknownPasteboardReadError);
        
    }
    return graphics;
    
}


+ (NSArray *)graphicsWithProperties:(NSArray *)propertiesArray {
    
    // Convert the array of graphic property dictionaries into an array of graphics. Again, don't assume that property list objects are the right type.
    NSUInteger graphicCount = [propertiesArray count];
    NSMutableArray *graphics = [[NSMutableArray alloc] initWithCapacity:graphicCount];
    for (NSUInteger index = 0; index<graphicCount; index++) {
        NSDictionary *properties = [propertiesArray objectAtIndex:index];
        if ([properties isKindOfClass:[NSDictionary class]]) {
            
            // Figure out the class of graphic to instantiate. The value of the LPGateClassNameKey entry must be an Objective-C class name. Don't trust the type of something you get out of a property list unless you know your process created it or it was read from your application or framework's resources.
            NSString *className = [properties objectForKey:LPGateClassNameKey];
            if ([className isKindOfClass:[NSString class]]) {
                Class class = NSClassFromString(className);
                if (class) {
                    // Create a new graphic. If it doesn't work then just do nothing. We could return an NSError, but doing things this way 1) means that a user might be able to rescue graphics from a partially corrupted document, and 2) is easier.
                    LPGate *graphic = [[class alloc] initWithProperties:properties];
                    if (graphic) {
                        [graphics addObject:graphic];
                    }
                    
                }
                
            }
            
        }
    }
    return graphics;
    
}


+ (NSData *)pasteboardDataWithGraphics:(NSArray *)graphics {
    
    // Convert the contents of the document to a property list and then flatten the property list.
//    return [NSPropertyListSerialization dataFromPropertyList:[self propertiesWithGraphics:graphics] format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
    return nil;
}


//+ (NSArray *)propertiesWithGraphics:(NSArray *)graphics {
//    
//    // Convert the array of graphics dictionaries into an array of graphic property dictionaries.
//    NSUInteger graphicCount = [graphics count];
//    NSMutableArray *propertiesArray = [[NSMutableArray alloc] initWithCapacity:graphicCount];
//    for (NSUInteger index = 0; index<graphicCount; index++) {
//        LPGate *graphic = [graphics objectAtIndex:index];
//        
//        // Get the properties of the graphic, add the class name that can be used by +graphicsWithProperties: to it, and add the properties to the array we're building.
//        NSMutableDictionary *properties = [graphic properties];
//        [properties setObject:NSStringFromClass([graphic class]) forKey:LPGateClassNameKey];
//        [propertiesArray addObject:properties];
//        
//    }
//    return propertiesArray;
//    
//}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        _bounds = [decoder decodeCGRectForKey:LPGateBoundsKey];
        _isDrawingFill = [decoder decodeBoolForKey:LPGateIsDrawingFillKey];
        _fillColor = [decoder decodeObjectForKey:LPGateFillColorKey];
        _isDrawingStroke = [decoder decodeBoolForKey:LPGateIsDrawingStrokeKey];
        _strokeColor = [decoder decodeObjectForKey:LPGateStrokeColorKey];
        _strokeWidth = [decoder decodeDoubleForKey:LPGateStrokeWidthKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeCGRect:_bounds forKey:LPGateBoundsKey];
    [encoder encodeBool:_isDrawingFill forKey:LPGateIsDrawingFillKey];
    [encoder encodeObject:_fillColor forKey:LPGateFillColorKey];
    [encoder encodeBool:_isDrawingStroke forKey:LPGateIsDrawingStrokeKey];
    [encoder encodeObject:_strokeColor forKey:LPGateStrokeColorKey];
    [encoder encodeDouble:_strokeWidth forKey:LPGateStrokeWidthKey];
}


//- (id)initWithProperties:(NSDictionary *)properties {
//    
//    // Invoke the designated initializer.
//    self = [self init];
//    if (self) {
//        
//        // The dictionary entries are all instances of the classes that can be written in property lists. Don't trust the type of something you get out of a property list unless you know your process created it or it was read from your application or framework's resources. We don't have to worry about KVO-compliance in initializers like this by the way; no one should be observing an unitialized object.
//        Class dataClass = [NSData class];
//        Class numberClass = [NSNumber class];
//        Class stringClass = [NSString class];
//        NSString *boundsString = [properties objectForKey:LPGateBoundsKey];
//        if ([boundsString isKindOfClass:stringClass]) {
//            _bounds = CGRectFromString(boundsString);
//        }
//        NSNumber *isDrawingFillNumber = [properties objectForKey:LPGateIsDrawingFillKey];
//        if ([isDrawingFillNumber isKindOfClass:numberClass]) {
//            _isDrawingFill = [isDrawingFillNumber boolValue];
//        }
//        NSData *fillColorData = [properties objectForKey:LPGateFillColorKey];
//        if ([fillColorData isKindOfClass:dataClass]) {
//            _fillColor = [NSUnarchiver unarchiveObjectWithData:fillColorData];
//        }
//        NSNumber *isDrawingStrokeNumber = [properties objectForKey:LPGateIsDrawingStrokeKey];
//        if ([isDrawingStrokeNumber isKindOfClass:numberClass]) {
//            _isDrawingStroke = [isDrawingStrokeNumber boolValue];
//        }
//        NSData *strokeColorData = [properties objectForKey:LPGateStrokeColorKey];
//        if ([strokeColorData isKindOfClass:dataClass]) {
//            _strokeColor = [NSUnarchiver unarchiveObjectWithData:strokeColorData];
//        }
//        NSNumber *strokeWidthNumber = [properties objectForKey:LPGateStrokeWidthKey];
//        if ([strokeWidthNumber isKindOfClass:numberClass]) {
//            _strokeWidth = [strokeWidthNumber doubleValue];
//        }
//        
//    }
//    return self;
//    
//}


- (NSMutableDictionary *)properties {
    
    // Return a dictionary that contains nothing but values that can be written in property lists.
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    CFDictionaryRef ref = CGRectCreateDictionaryRepresentation([self bounds]);
    [properties setObject:nil forKey:LPGateBoundsKey];
    [properties setObject:[NSNumber numberWithBool:[self isDrawingFill]] forKey:LPGateIsDrawingFillKey];
    UIColor *fillColor = [self fillColor];
    if (fillColor) {
        [properties setObject:fillColor forKey:LPGateFillColorKey];
    }
    [properties setObject:[NSNumber numberWithBool:[self isDrawingStroke]] forKey:LPGateIsDrawingStrokeKey];
    UIColor *strokeColor = [self strokeColor];
    if (strokeColor) {
        [properties setObject:strokeColor forKey:LPGateStrokeColorKey];
    }
    [properties setObject:[NSNumber numberWithDouble:[self strokeWidth]] forKey:LPGateStrokeWidthKey];
    return properties;
    
}


#pragma mark *** Simple Property Getting ***


// Do the regular Cocoa thing.
- (CGRect)bounds {
    return _bounds;
}
- (BOOL)isDrawingFill {
    return _isDrawingFill;
}
- (UIColor *)fillColor {
    return _fillColor;
}
- (BOOL)isDrawingStroke {
    return _isDrawingStroke;
}
- (UIColor *)strokeColor {
    return _strokeColor;
}
- (CGFloat)strokeWidth {
    return _strokeWidth;
}


#pragma mark *** Drawing ***


+ (NSSet *)keyPathsForValuesAffectingDrawingBounds {
    
    // The only properties managed by LPGate that affect the drawing bounds are the bounds and the the stroke width.
    return [NSSet setWithObjects:LPGateBoundsKey, LPGateStrokeWidthKey, nil];
    
}


+ (NSSet *)keyPathsForValuesAffectingDrawingContents {
    
    // The only properties managed by LPGate that affect drawing but not the drawing bounds are the fill and stroke parameters.
    return [NSSet setWithObjects:LPGateIsDrawingFillKey, LPGateFillColorKey, LPGateIsDrawingStrokeKey, LPGateStrokeColorKey, nil];
    
}


- (CGRect)drawingBounds {
    
    // Assume that -[LPGate drawContentsInView:] and -[LPGate drawHandlesInView:] will be doing the drawing. Start with the plain bounds of the graphic, then take drawing of handles at the corners of the bounds into account, then optional stroke drawing.
    CGFloat outset = LPGateHandleHalfWidth;
    if ([self isDrawingStroke]) {
        CGFloat strokeOutset = [self strokeWidth] / 2.0f;
        if (strokeOutset>outset) {
            outset = strokeOutset;
        }
    }
    CGFloat inset = 0.0f - outset;
    CGRect drawingBounds = CGRectInset([self bounds], inset, inset);
    
    // -drawHandleInView:atPoint: draws a one-unit drop shadow too.
    drawingBounds.size.width += 1.0f;
    drawingBounds.size.height += 1.0f;
    return drawingBounds;
    
}


- (void)drawContentsInView:(UIView *)view isBeingCreateOrEdited:(BOOL)isBeingCreatedOrEditing {
    
    // If the graphic is so so simple that it can be boiled down to a bezier path then just draw a bezier path. It's -bezierPathForDrawing's responsibility to return a path with the current stroke width.
    UIBezierPath *path = [self bezierPathForDrawing];
    if (path) {
        if ([self isDrawingFill]) {
            [[self fillColor] set];
            [path fill];
        }
        if ([self isDrawingStroke]) {
            [[self strokeColor] set];
            [path stroke];
        }
    }
    
}

- (UIBezierPath *)bezierPathForDrawing {
    
    // Live to be overriden.
    [NSException raise:NSInternalInconsistencyException format:@"Neither -drawContentsInView: nor -bezierPathForDrawing has been overridden."];
    return nil;
    
}


- (void)drawHandlesInView:(UIView *)view {
    
    // Draw handles at the corners and on the sides.
    CGRect bounds = [self bounds];
    [self drawHandleInView:view atPoint:CGPointMake(CGRectGetMinX(bounds), CGRectGetMinY(bounds))];
    [self drawHandleInView:view atPoint:CGPointMake(CGRectGetMidX(bounds), CGRectGetMinY(bounds))];
    [self drawHandleInView:view atPoint:CGPointMake(CGRectGetMaxX(bounds), CGRectGetMinY(bounds))];
    [self drawHandleInView:view atPoint:CGPointMake(CGRectGetMinX(bounds), CGRectGetMidY(bounds))];
    [self drawHandleInView:view atPoint:CGPointMake(CGRectGetMaxX(bounds), CGRectGetMidY(bounds))];
    [self drawHandleInView:view atPoint:CGPointMake(CGRectGetMinX(bounds), CGRectGetMaxY(bounds))];
    [self drawHandleInView:view atPoint:CGPointMake(CGRectGetMidX(bounds), CGRectGetMaxY(bounds))];
    [self drawHandleInView:view atPoint:CGPointMake(CGRectGetMaxX(bounds), CGRectGetMaxY(bounds))];
    
}


- (void)drawHandleInView:(UIView *)view atPoint:(CGPoint)point {
    
    // Figure out a rectangle that's centered on the point but lined up with device pixels.
    CGRect handleBounds;
    handleBounds.origin.x = point.x - LPGateHandleHalfWidth;
    handleBounds.origin.y = point.y - LPGateHandleHalfWidth;
    handleBounds.size.width = LPGateHandleWidth;
    handleBounds.size.height = LPGateHandleWidth;
//    handleBounds = [view centerScanRect:handleBounds];
    
    // Draw the shadow of the handle.
    CGRect handleShadowBounds = CGRectOffset(handleBounds, 1.0f, 1.0f);
    [[UIColor darkGrayColor] set];   // [UIColor controlDarkShadowColor] set];
    UIRectFill(handleShadowBounds);
    
    // Draw the handle itself.
    [[UIColor redColor] set];
    UIRectFill(handleBounds);
    
}


#pragma mark *** Editing ***


//+ (NSCursor *)creationCursor {
//    
//    // By default we use the crosshairs cursor.
//    static NSCursor *crosshairsCursor = nil;
//    if (!crosshairsCursor) {
//        NSImage *crosshairsImage = [NSImage imageNamed:@"Cross"];
//        NSSize crosshairsImageSize = [crosshairsImage size];
//        crosshairsCursor = [[NSCursor alloc] initWithImage:crosshairsImage hotSpot:CGPointMake((crosshairsImageSize.width / 2.0), (crosshairsImageSize.height / 2.0))];
//    }
//    return crosshairsCursor;
//    
//}


+ (NSInteger)creationSizingHandle {
    
    // Return the number of the handle for the lower-right corner. If the user drags it so that it's no longer in the lower-right, -resizeByMovingHandle:toPoint: will deal with it.
    return LPGateLowerRightHandle;
    
}


- (BOOL)canSetDrawingFill {
    
    // The default implementation of -drawContentsInView: can draw fills.
    return YES;
    
}


- (BOOL)canSetDrawingStroke {
    
    // The default implementation of -drawContentsInView: can draw strokes.
    return YES;
    
}


- (BOOL)canMakeNaturalSize {
    
    // Only return YES if -makeNaturalSize would actually do something.
    CGRect bounds = [self bounds];
    return bounds.size.width!=bounds.size.height;
    
}


- (BOOL)isContentsUnderPoint:(CGPoint)point {
    
    // Just check against the graphic's bounds.
    return CGRectContainsPoint([self bounds], point);
//    return CGPointInRect(point, [self bounds]);
    
}


- (NSInteger)handleUnderPoint:(CGPoint)point {
    
    // Check handles at the corners and on the sides.
    NSInteger handle = LPGateNoHandle;
    CGRect bounds = [self bounds];
    if ([self isHandleAtPoint:CGPointMake(CGRectGetMinX(bounds), CGRectGetMinY(bounds)) underPoint:point]) {
        handle = LPGateUpperLeftHandle;
    } else if ([self isHandleAtPoint:CGPointMake(CGRectGetMidX(bounds), CGRectGetMinY(bounds)) underPoint:point]) {
        handle = LPGateUpperMiddleHandle;
    } else if ([self isHandleAtPoint:CGPointMake(CGRectGetMaxX(bounds), CGRectGetMinY(bounds)) underPoint:point]) {
        handle = LPGateUpperRightHandle;
    } else if ([self isHandleAtPoint:CGPointMake(CGRectGetMinX(bounds), CGRectGetMidY(bounds)) underPoint:point]) {
        handle = LPGateMiddleLeftHandle;
    } else if ([self isHandleAtPoint:CGPointMake(CGRectGetMaxX(bounds), CGRectGetMidY(bounds)) underPoint:point]) {
        handle = LPGateMiddleRightHandle;
    } else if ([self isHandleAtPoint:CGPointMake(CGRectGetMinX(bounds), CGRectGetMaxY(bounds)) underPoint:point]) {
        handle = LPGateLowerLeftHandle;
    } else if ([self isHandleAtPoint:CGPointMake(CGRectGetMidX(bounds), CGRectGetMaxY(bounds)) underPoint:point]) {
        handle = LPGateLowerMiddleHandle;
    } else if ([self isHandleAtPoint:CGPointMake(CGRectGetMaxX(bounds), CGRectGetMaxY(bounds)) underPoint:point]) {
        handle = LPGateLowerRightHandle;
    }
    return handle;
    
}


- (BOOL)isHandleAtPoint:(CGPoint)handlePoint underPoint:(CGPoint)point {
    
    // Check a handle-sized rectangle that's centered on the handle point.
    CGRect handleBounds;
    handleBounds.origin.x = handlePoint.x - LPGateHandleHalfWidth;
    handleBounds.origin.y = handlePoint.y - LPGateHandleHalfWidth;
    handleBounds.size.width = LPGateHandleWidth;
    handleBounds.size.height = LPGateHandleWidth;
    return CGRectContainsPoint(handleBounds, point); // CGPointInRect(point, handleBounds);
    
}


- (NSInteger)resizeByMovingHandle:(NSInteger)handle toPoint:(CGPoint)point {
    
    // Start with the original bounds.
    CGRect bounds = [self bounds];
    
    // Is the user changing the width of the graphic?
    if (handle==LPGateUpperLeftHandle || handle==LPGateMiddleLeftHandle || handle==LPGateLowerLeftHandle) {
        
        // Change the left edge of the graphic.
        bounds.size.width = CGRectGetMaxX(bounds) - point.x;
        bounds.origin.x = point.x;
        
    } else if (handle==LPGateUpperRightHandle || handle==LPGateMiddleRightHandle || handle==LPGateLowerRightHandle) {
        
        // Change the right edge of the graphic.
        bounds.size.width = point.x - bounds.origin.x;
        
    }
    
    // Did the user actually flip the graphic over?
    if (bounds.size.width<0.0f) {
        
        // The handle is now playing a different role relative to the graphic.
        static NSInteger flippings[9];
        static BOOL flippingsInitialized = NO;
        if (!flippingsInitialized) {
            flippings[LPGateUpperLeftHandle] = LPGateUpperRightHandle;
            flippings[LPGateUpperMiddleHandle] = LPGateUpperMiddleHandle;
            flippings[LPGateUpperRightHandle] = LPGateUpperLeftHandle;
            flippings[LPGateMiddleLeftHandle] = LPGateMiddleRightHandle;
            flippings[LPGateMiddleRightHandle] = LPGateMiddleLeftHandle;
            flippings[LPGateLowerLeftHandle] = LPGateLowerRightHandle;
            flippings[LPGateLowerMiddleHandle] = LPGateLowerMiddleHandle;
            flippings[LPGateLowerRightHandle] = LPGateLowerLeftHandle;
            flippingsInitialized = YES;
        }
        handle = flippings[handle];
        
        // Make the graphic's width positive again.
        bounds.size.width = 0.0f - bounds.size.width;
        bounds.origin.x -= bounds.size.width;
        
        // Tell interested subclass code what just happened.
        [self flipHorizontally];
        
    }
    
    // Is the user changing the height of the graphic?
    if (handle==LPGateUpperLeftHandle || handle==LPGateUpperMiddleHandle || handle==LPGateUpperRightHandle) {
        
        // Change the top edge of the graphic.
        bounds.size.height = CGRectGetMaxY(bounds) - point.y;
        bounds.origin.y = point.y;
        
    } else if (handle==LPGateLowerLeftHandle || handle==LPGateLowerMiddleHandle || handle==LPGateLowerRightHandle) {
        
        // Change the bottom edge of the graphic.
        bounds.size.height = point.y - bounds.origin.y;
        
    }
    
    // Did the user actually flip the graphic upside down?
    if (bounds.size.height<0.0f) {
        
        // The handle is now playing a different role relative to the graphic.
        static NSInteger flippings[9];
        static BOOL flippingsInitialized = NO;
        if (!flippingsInitialized) {
            flippings[LPGateUpperLeftHandle] = LPGateLowerLeftHandle;
            flippings[LPGateUpperMiddleHandle] = LPGateLowerMiddleHandle;
            flippings[LPGateUpperRightHandle] = LPGateLowerRightHandle;
            flippings[LPGateMiddleLeftHandle] = LPGateMiddleLeftHandle;
            flippings[LPGateMiddleRightHandle] = LPGateMiddleRightHandle;
            flippings[LPGateLowerLeftHandle] = LPGateUpperLeftHandle;
            flippings[LPGateLowerMiddleHandle] = LPGateUpperMiddleHandle;
            flippings[LPGateLowerRightHandle] = LPGateUpperRightHandle;
            flippingsInitialized = YES;
        }
        handle = flippings[handle];
        
        // Make the graphic's height positive again.
        bounds.size.height = 0.0f - bounds.size.height;
        bounds.origin.y -= bounds.size.height;
        
        // Tell interested subclass code what just happened.
        [self flipVertically];
        
    }
    
    // Done.
    [self setBounds:bounds];
    return handle;
    
}


- (void)flipHorizontally {
    
    // Live to be overridden.
    
}


- (void)flipVertically {
    
    // Live to be overridden.
    
}


- (void)makeNaturalSize {
    
    // Just make the graphic square.
    CGRect bounds = [self bounds];
    if (bounds.size.width<bounds.size.height) {
        bounds.size.height = bounds.size.width;
        [self setBounds:bounds];
    } else if (bounds.size.width>bounds.size.height) {
        bounds.size.width = bounds.size.height;
        [self setBounds:bounds];
    }
    
}


- (void)setBounds:(CGRect)bounds {
    
    // Simple.
    _bounds = bounds;
    
}


- (void)setColor:(UIColor *)color {
    
    // This method demonstrates something interesting: we haven't bothered to provide setter methods for the properties we want to change, but we can still change them using KVC. KVO autonotification will make sure observers hear about the change (it works with -setValue:forKey: as well as -set<Key>:). Of course, if we found ourselvings doing this a little more often we would go ahead and just add the setter methods. The point is that KVC direct instance variable access very often makes boilerplate accessors unnecessary but if you want to just put them in right away, eh, go ahead.
    
    // Can we fill the graphic?
    if ([self canSetDrawingFill]) {
        
        // Are we filling it? If not, start, using the new color.
        if (![self isDrawingFill]) {
            [self setValue:[NSNumber numberWithBool:YES] forKey:LPGateIsDrawingFillKey];
        }
        [self setValue:color forKey:LPGateFillColorKey];
        
    }
    
}


- (UIView *)newEditingViewWithSuperviewBounds:(CGRect)superviewBounds {
    
    // Live to be overridden.
    return nil;
    
}


- (void)finalizeEditingView:(UIView *)editingView {
    
    // Live to be overridden.
    
}


#pragma mark *** Undo ***


- (NSSet *)keysForValuesToObserveForUndo {
    
    // Of the properties managed by LPGate, "drawingingBounds," "drawingContents," "canSetDrawingFill," and "canSetDrawingStroke" aren't anything that the user changes, so changes of their values aren't registered undo operations. "xPosition," "yPosition," "width," and "height" are all derived from "bounds," so we don't need to register those either. Changes of any other property are undoable.
    return [NSSet setWithObjects:LPGateIsDrawingFillKey, LPGateFillColorKey, LPGateIsDrawingStrokeKey, LPGateStrokeColorKey, LPGateStrokeWidthKey, LPGateBoundsKey, nil];
    
}


+ (NSString *)presentablePropertyNameForKey:(NSString *)key {
    
    // Pretty simple. Don't be surprised if you never see "Bounds" appear in an undo action name in Sketch. LPGateView invokes -[NSUndoManager setActionName:] for things like moving, resizing, and aligning, thereby overwriting whatever SKTDocument sets with something more specific.
    static NSDictionary *presentablePropertyNamesByKey = nil;
    if (!presentablePropertyNamesByKey) {
        presentablePropertyNamesByKey = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                         NSLocalizedStringFromTable(@"Filling", @"UndoStrings", @"Action name part for LPGateIsDrawingFillKey."), LPGateIsDrawingFillKey,
                                         NSLocalizedStringFromTable(@"Fill Color", @"UndoStrings",@"Action name part for LPGateFillColorKey."), LPGateFillColorKey,
                                         NSLocalizedStringFromTable(@"Stroking", @"UndoStrings", @"Action name part for LPGateIsDrawingStrokeKey."), LPGateIsDrawingStrokeKey,
                                         NSLocalizedStringFromTable(@"Stroke Color", @"UndoStrings", @"Action name part for LPGateStrokeColorKey."), LPGateStrokeColorKey,
                                         NSLocalizedStringFromTable(@"Stroke Width", @"UndoStrings", @"Action name part for LPGateStrokeWidthKey."), LPGateStrokeWidthKey,
                                         NSLocalizedStringFromTable(@"Bounds", @"UndoStrings", @"Action name part for LPGateBoundsKey."), LPGateBoundsKey,
                                         nil];
    }
    return [presentablePropertyNamesByKey objectForKey:key];
    
}


#pragma mark *** Scripting ***


- (void)setScriptingContainer:(NSObject *)scriptingContainer {
    
    // Don't retain the container. It's supposed to be retaining this object.
    _scriptingContainer = scriptingContainer;
    
}


//// Conformance to the NSObject(NSScriptObjectSpecifiers) informal protocol.
//- (NSScriptObjectSpecifier *)objectSpecifier {
//    
//    // This object can't create an object specifier for itself, so ask its scriptable container to do it.
//    NSScriptObjectSpecifier *objectSpecifier = [_scriptingContainer objectSpecifierForGraphic:self];
//    if (!objectSpecifier) {
//        [NSException raise:NSInternalInconsistencyException format:@"A scriptable graphic has no scriptable container, or one that doesn't implement -objectSpecifierForGraphic: correctly."];
//    }
//    return objectSpecifier;
//    
//}


- (UIColor *)scriptingFillColor {
    
    // Return nil if the graphic is not filled. The scripter will see that as "missing value."
    return [self isDrawingFill] ? [self fillColor] : nil;
    
}


- (UIColor *)scriptingStrokeColor {
    
    // Return nil if the graphic is not stroked. The scripter will see that as "missing value."
    return [self isDrawingStroke] ? [self strokeColor] : nil;
    
}


- (NSNumber *)scriptingStrokeWidth {
    
    // Return nil if the graphic is not stroked. The scripter will see that as "missing value."
    return [self isDrawingStroke] ? [NSNumber numberWithDouble:[self strokeWidth]] : nil;
    
}


- (void)setScriptingFillColor:(UIColor *)fillColor {
    
    // See the comment in -setColor: about using KVC like we do here.
    
    // For the convenience of scripters, turn filling on or off if necessary, if that's allowed. Don't forget that -isDrawingFill can return YES or NO regardless of what -canSetDrawingFill is returning.
    if (fillColor) {
        BOOL canSetFillColor = YES;
        if (![self isDrawingFill]) {
            if ([self canSetDrawingFill]) {
                [self setValue:[NSNumber numberWithBool:YES] forKey:LPGateIsDrawingFillKey];
            } else {
                
                // Not allowed. Tell the scripter what happened.
//                NSScriptCommand *currentScriptCommand = [NSScriptCommand currentCommand];
//                [currentScriptCommand setScriptErrorNumber:errAEEventFailed];
//                [currentScriptCommand setScriptErrorString:NSLocalizedStringFromTable(@"You can't set the fill color of this kind of graphic.", @"LPGate", @"A scripting error message.")];
                canSetFillColor = NO;
                
            }
        }
        if (canSetFillColor) {
            [self setValue:fillColor forKey:LPGateFillColorKey];
        }
    } else {
        if ([self isDrawingFill]) {
            if ([self canSetDrawingFill]) {
                [self setValue:[NSNumber numberWithBool:NO] forKey:LPGateIsDrawingFillKey];
            } else {
                
                // Not allowed. Tell the scripter what happened.
//                NSScriptCommand *currentScriptCommand = [NSScriptCommand currentCommand];
//                [currentScriptCommand setScriptErrorNumber:errAEEventFailed];
//                [currentScriptCommand setScriptErrorString:NSLocalizedStringFromTable(@"You can't remove the fill from this kind of graphic.", @"LPGate", @"A scripting error message.")];
                
            }
        }
    }
    
}


// The same as above, but for stroke color instead of fill color.
- (void)setScriptingStrokeColor:(UIColor *)strokeColor {
    if (strokeColor) {
        BOOL canSetStrokeColor = YES;
        if (![self isDrawingStroke]) {
            if ([self canSetDrawingStroke]) {
                [self setValue:[NSNumber numberWithBool:YES] forKey:LPGateIsDrawingStrokeKey];
            } else {
//                NSScriptCommand *currentScriptCommand = [NSScriptCommand currentCommand];
//                [currentScriptCommand setScriptErrorNumber:errAEEventFailed];
//                [currentScriptCommand setScriptErrorString:NSLocalizedStringFromTable(@"You can't set the stroke color of this kind of graphic.", @"LPGate", @"A scripting error message.")];
//                canSetStrokeColor = NO;
            }
        }
        if (canSetStrokeColor) {
            [self setValue:strokeColor forKey:LPGateStrokeColorKey];
        }
    } else {
        if ([self isDrawingStroke]) {
            if ([self canSetDrawingStroke]) {
                [self setValue:[NSNumber numberWithBool:NO] forKey:LPGateIsDrawingStrokeKey];
            } else {
//                NSScriptCommand *currentScriptCommand = [NSScriptCommand currentCommand];
//                [currentScriptCommand setScriptErrorNumber:errAEEventFailed];
//                [currentScriptCommand setScriptErrorString:NSLocalizedStringFromTable(@"You can't remove the stroke from this kind of graphic.", @"LPGate", @"A scripting error message.")];
            }
        }
    }
}


- (void)setScriptingStrokeWidth:(NSNumber *)strokeWidth {
    
    // See the comment in -setColor: about using KVC like we do here.
    
    // For the convenience of scripters, turn stroking on or off if necessary, if that's allowed. Don't forget that -isDrawingStroke can return YES or NO regardless of what -canSetDrawingStroke is returning.
    if (strokeWidth) {
        BOOL canSetStrokeWidth = YES;
        if (![self isDrawingStroke]) {
            if ([self canSetDrawingStroke]) {
                [self setValue:[NSNumber numberWithBool:YES] forKey:LPGateIsDrawingStrokeKey];
            } else {
                
                // Not allowed. Tell the scripter what happened.
//                NSScriptCommand *currentScriptCommand = [NSScriptCommand currentCommand];
//                [currentScriptCommand setScriptErrorNumber:errAEEventFailed];
//                [currentScriptCommand setScriptErrorString:NSLocalizedStringFromTable(@"You can't set the stroke thickness of this kind of graphic.", @"LPGate", @"A scripting error message.")];
                canSetStrokeWidth = NO;
                
            }
        }
        if (canSetStrokeWidth) {
            [self setValue:strokeWidth forKey:LPGateStrokeWidthKey];
        }
    } else {
        if ([self isDrawingStroke]) {
            if ([self canSetDrawingStroke]) {
                [self setValue:[NSNumber numberWithBool:NO] forKey:LPGateIsDrawingStrokeKey];
            } else {
                
                // Not allowed. Tell the scripter what happened.
//                NSScriptCommand *currentScriptCommand = [NSScriptCommand currentCommand];
//                [currentScriptCommand setScriptErrorNumber:errAEEventFailed];
//                [currentScriptCommand setScriptErrorString:NSLocalizedStringFromTable(@"You can't remove the stroke from this kind of graphic.", @"LPGate", @"A scripting error message.")];
                
            }
        }
    }
    
}

#pragma mark *** Debugging ***


// An override of the NSObject method.
- (NSString *)description {
    
    // Make 'po aGraphic' do something useful in gdb.
    return [[self properties] description];
    
}


@end