//
//  Gates.h
//  LogicPro
//
//  Created by Michael Griebling on 16Jan2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import <Foundation/Foundation.h>

// The keys described down below.
extern NSString *LPGateCanSetDrawingFillKey;
extern NSString *LPGateCanSetDrawingStrokeKey;
extern NSString *LPGateIsDrawingFillKey;
extern NSString *LPGateFillColorKey;
extern NSString *LPGateIsDrawingStrokeKey;
extern NSString *LPGateStrokeColorKey;
extern NSString *LPGateStrokeWidthKey;
extern NSString *LPGateXPositionKey;
extern NSString *LPGateYPositionKey;
extern NSString *LPGateWidthKey;
extern NSString *LPGateHeightKey;
extern NSString *LPGateBoundsKey;
extern NSString *LPGateDrawingBoundsKey;
extern NSString *LPGateDrawingContentsKey;
extern NSString *LPGateKeysForValuesToObserveForUndoKey;

// The value that is returned by -handleUnderPoint: to indicate that no selection handle is under the point.
extern const NSInteger LPGateNoHandle;

enum {
    LPGateUpperLeftHandle = 1,
    LPGateUpperMiddleHandle = 2,
    LPGateUpperRightHandle = 3,
    LPGateMiddleLeftHandle = 4,
    LPGateMiddleRightHandle = 5,
    LPGateLowerLeftHandle = 6,
    LPGateLowerMiddleHandle = 7,
    LPGateLowerRightHandle = 8,
};

extern CGFloat LPGateHandleWidth;
extern CGFloat LPGateHandleHalfWidth;

@interface LPGate : NSObject <NSCopying> {
@private
    
    // The values underlying some of the key-value coding (KVC) and observing (KVO) compliance described below. Any corresponding getter or setter methods are there for invocation by code in subclasses, not for KVC or KVO compliance. KVC's direct instance variable access, KVO's autonotifying, and KVO's property dependency mechanism makes them unnecessary for the latter purpose.
    // If you look closely, you'll notice that LPGate itself never touches these instance variables directly except in initializers, -copyWithZone:, and public accessors. LPGate is following a good rule: if a class publishes getters and setters it should itself invoke them, because people who override methods to customize behavior are right to expect their overrides to actually be invoked.
    CGRect  _bounds;
    BOOL    _isDrawingFill;
    UIColor *_fillColor;
    BOOL    _isDrawingStroke;
    UIColor *_strokeColor;
    CGFloat _strokeWidth;
    
    // The object that contains the graphic (unretained), from the point of view of scriptability. This is here only for use by this class' override of scripting's -objectSpecifier method. In Sketch this is an SKTDocument.
    NSObject *_scriptingContainer;
}

#pragma mark *** Convenience ***

/* You can override these class methods in your subclass of LPGate, but it would be a waste of time, because no one invokes these on any class other than LPGate itself. Really these could just be functions if we didn't have such a syntactic sweet tooth. */

// Move each graphic in the array by the same amount.
+ (void)translateGraphics:(NSArray *)graphics byX:(CGFloat)deltaX y:(CGFloat)deltaY;

// Return the total "bounds" of all of the graphics in the array.
+ (CGRect)boundsOfGraphics:(NSArray *)graphics;

// Return the total drawing bounds of all of the graphics in the array.
+ (CGRect)drawingBoundsOfGraphics:(NSArray *)graphics;

#pragma mark *** Persistence ***

/* You can override these class methods in your subclass of LPGate, but it would be a waste of time, because no one invokes these on any class other than LPGate itself. Really these could just be functions if we didn't have such a syntactic sweet tooth. */

// Return an array of graphics created from flattened data of the sort returned by +pasteboardDataWithGraphics: or, if that's not possible, return nil and set *outError to an NSError that can be presented to the user to explain what went wrong.
+ (NSArray *)graphicsWithPasteboardData:(NSData *)data error:(NSError **)outError;

// Given an array of property list dictionaries whose validity has not been determined, return an array of graphics.
+ (NSArray *)graphicsWithProperties:(NSArray *)propertiesArray;

// Return the array of graphics as flattened data that is appropriate for passing to +graphicsWithPasteboardData:error:.
+ (NSData *)pasteboardDataWithGraphics:(NSArray *)graphics;

// Given an array of graphics, return an array of property list dictionaries.
+ (NSArray *)propertiesWithGraphics:(NSArray *)graphics;

/* Subclasses of LPGate might have reason to override any of the rest of this class' methods, starting here. */

// Given a dictionary having the sort of entries that would be in a dictionary returned by -properties, but whose validity has not been determined, initialize, setting the values of as many properties as possible from it. Ignore unrecognized dictionary entries. Use default values for missing dictionary entries. This is not the designated initializer for this class (-init is).
- (id)initWithProperties:(NSDictionary *)properties;

// Return a dictionary that can be used as property list object and contains enough information to recreate the graphic (except for its class, which is handled by +propertiesWithGraphics:). The returned dictionary must be mutable so that it can be added to efficiently, but the receiver must ignore any mutations made to it after it's been returned.
- (NSMutableDictionary *)properties;

#pragma mark *** Simple Property Getting ***

// Accessors for properties that this class stores as instance variables. These methods provide readable KVC-compliance for several of the keys mentioned in comments above, but that's not why they're here (KVC direct instance variable access makes them unnecessary for that). They're here just for invoking and overriding by subclass code.
- (CGRect)bounds;
- (BOOL)isDrawingFill;
- (UIColor *)fillColor;
- (BOOL)isDrawingStroke;
- (UIColor *)strokeColor;
- (CGFloat)strokeWidth;


#pragma mark *** Drawing ***

// Return the keys of all of the properties whose values affect the appearance of an instance of the receiving subclass of LPGate (even properties declared in a superclass). The first method should return the keys for such properties that affect the drawing bounds of graphics. The second method should return the keys for such properties that do not. Most subclasses of LPGate should override one or both of these, and be KVO-compliant for the properties identified by keys in the returned set. Implementations of these methods don't have to be fast, at least not in the context of Sketch, because their results are cached. In Mac OS 10.5 and later these methods are invoked automatically by KVO because their names match the result of applying to "drawingBounds" and "drawingContents" the naming pattern used by the default implementation of +[NSObject(NSKeyValueObservingCustomization) keyPathsForValuesAffectingValueForKey:].
+ (NSSet *)keyPathsForValuesAffectingDrawingBounds;
+ (NSSet *)keyPathsForValuesAffectingDrawingContents;

// Return the bounding box of everything the receiver might draw when sent a -draw...InView: message. The default implementation of this method returns a bounds that assumes the default implementations of -drawContentsInView: and -drawHandlesInView:. Subclasses that override this probably have to override +keyPathsForValuesAffectingDrawingBounds too.
- (CGRect)drawingBounds;

// Draw the contents the receiver in a specific view. Use isBeingCreatedOrEditing if the graphic draws differently during its creation or while it's being edited. The default implementation of this method just draws the result of invoking -bezierPathForDrawing using the current fill and stroke parameters. Subclasses have to override either this method or -bezierPathForDrawing. Subclasses that override this may have to override +keyPathsForValuesAffectingDrawingBounds, +keyPathsForValuesAffectingDrawingContents, and -drawingBounds too.
- (void)drawContentsInView:(UIView *)view isBeingCreateOrEdited:(BOOL)isBeingCreatedOrEditing;

// Return a bezier path that can be stroked and filled to draw the graphic, if the graphic can be drawn so simply, nil otherwise. The default implementation of this method returns nil. Subclasses have to override either this method or -drawContentsInView:. Any returned bezier path should already have the graphic's current stroke width set in it.
- (UIBezierPath *)bezierPathForDrawing;

// Draw the handles of the receiver in a specific view. The default implementation of this method just invokes -drawHandleInView:atPoint: for each point at the corners and on the sides of the rectangle returned by -bounds. Subclasses that override this probably have to override -handleUnderPoint: too.
- (void)drawHandlesInView:(UIView *)view;

// Draw handle at a specific point in a specific view. Subclasses that override -drawHandlesInView: can invoke this to easily draw handles whereever they like.
- (void)drawHandleInView:(UIView *)view atPoint:(CGPoint)point;


#pragma mark *** Editing ***

// Return a cursor that can be used when the user has clicked using the creation tool and is dragging the mouse to size a new instance of the receiving class.
//+ (NSCursor *)creationCursor;

// Return the number of the handle that the user is dragging when they move the mouse after clicking to create a new instance of the receiving class. The default implementation of this method returns a number that corresponds to one of the corners of the graphic's bounds. Subclasses that override this should probably override -resizeByMovingHandle:toPoint: too.
+ (NSInteger)creationSizingHandle;

// Return YES if it's useful to let the user toggle drawing of the fill or stroke, NO otherwise. The default implementations of these methods return YES.
- (BOOL)canSetDrawingFill;
- (BOOL)canSetDrawingStroke;

// Return YES if sending -makeNaturalSize to the receiver would do something noticable by the user, NO otherwise. The default implementation of this method returns YES if the defaultimplementation of -makeNaturalSize would actually do something, NO otherwise.
- (BOOL)canMakeNaturalSize;

// Return YES if the point is in the contents of the receiver, NO otherwise. The default implementation of this method returns YES if the point is inside [self bounds].
- (BOOL)isContentsUnderPoint:(CGPoint)point;

// If the point is in one of the handles of the receiver return its number, LPGateNoHandle otherwise. The default implementation of this method invokes -isHandleAtPoint:underPoint: for the corners and on the sides of the rectangle returned by -bounds. Subclasses that override this probably have to override several other methods too.
- (NSInteger)handleUnderPoint:(CGPoint)point;

// Return YES if the handle at a point is under another point. Subclasses that override -handleUnderPoint: can invoke this to hit-test the sort of handles that would be drawn by -drawHandleInView:atPoint:.
- (BOOL)isHandleAtPoint:(CGPoint)handlePoint underPoint:(CGPoint)point;

// Given that one of the receiver's handles has been dragged by the user, resize to match, and return the handle number that should be passed into subsequent invocations of this same method. The default implementation of this method assumes that the passed-in handle number was returned by a previous invocation of +creationSizingHandle or -handleUnderPoint:, so subclasses that override this should probably override +creationSizingHandle and -handleUnderPoint: too. It also invokes -flipHorizontally and -flipVertically when the user flips the graphic.
- (NSInteger)resizeByMovingHandle:(NSInteger)handle toPoint:(CGPoint)point;

// Given that -resizeByMovingHandle:toPoint: is being invoked and sensed that the user has flipped the graphic one way or the other, change the graphic to accomodate, whatever that means. Subclasses that represent asymmetrical graphics can override these to accomodate the user's dragging of handles without having to override and mostly reimplement -resizeByMovingHandle:toPoint:.
- (void)flipHorizontally;
- (void)flipVertically;

// Given that [[self class] canMakeNaturalSize] would return YES, set the the bounds of the receiver to whatever is "natural" for its particular subclass of LPGate. The default implementation of this method just squares the bounds.
- (void)makeNaturalSize;

// Set the bounds of the graphic, doing whatever scaling and translation is necessary.
- (void)setBounds:(CGRect)bounds;

// Set the color of the graphic, whatever that means. The default implementation of this method just sets isDrawingFill to YES and fillColor to the passed-in color. In Sketch this method is invoked when the user drops a color chip on the graphic or uses the color panel to change the color of all of the selected graphics.
- (void)setColor:(UIColor *)color;

// Given that the receiver has just been created or double-clicked on or something, create and return a view that can present its editing interface to the user, or return nil. The returned view should be suitable for becoming a subview of a view whose bounds is passed in. Its frame should match the bounds of the receiver. The receiver should not assume anything about the lifetime of the returned editing view; it may remain in use even after subsequent invocations of this method, which should, again, create a new editing view each time. In other words, overrides of this method should be prepared for a graphic to have more than editing view outstanding. The default implementation of this method returns nil. In Sketch SKTText overrides it.
- (UIView *)newEditingViewWithSuperviewBounds:(CGRect)superviewBounds;

// Given an editing view that was returned by a previous invocation of -newEditingViewWithSuperviewBounds:, tear down whatever connections exist between it and the receiver.
- (void)finalizeEditingView:(UIView *)editingView;


#pragma mark *** Undo ***

// Return the keys of all of the properties for which value changes are undoable. In Sketch SKTDocument observes the value for each key in the set returned by invoking this method on each graphic in the document, and registers undo operations when the values change. It also observes this "keysForValuesToObserveForUndo" property itself and reacts accordingly, because the value can change dynamically. For example, SKTText overrides this (and KVO-notifies about changes to what the override would return) for a couple of reasons.
- (NSSet *)keysForValuesToObserveForUndo;

// Given a key from the set returned by a previous invocation of -keysForValuesToObserveForUndo, return the human-readable, title-capitalized, localized, name of the property identified by the key, or nil for invalid keys (invokers should throw exceptions if nil is returned, because nil indicates a programming mistake). In Sketch SKTDocument uses this to create an undo action name when the user has changed the value of the property.
+ (NSString *)presentablePropertyNameForKey:(NSString *)key;

#pragma mark *** Scripting ***

//// Given that the receiver is now contained by some other object, or is no longer contained by another, take a pointer to its container, but do not retain it.
//- (void)setScriptingContainer:(NSObject *)scriptingContainer;


@end


//@interface Gates : NSObject
//
//+ (NSString *)getNameForGate:(GateType)gate;
//+ (NSInteger)total;
//
//- (Gate *)findMatch:(CGPoint)position;
//
//@property (strong, nonatomic) NSMutableArray *list;
//
//@end

