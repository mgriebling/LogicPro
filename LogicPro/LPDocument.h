//
//  LPDocument.h
//  LogicPro
//
//  Created by Michael Griebling on 2Dec2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import <UIKit/UIKit.h>

// The keys described down below.
extern NSString *LPDocumentCanvasSizeKey;
extern NSString *LPDocumentGraphicsKey;

@interface LPDocument : UIDocument <NSFilePresenter> {

@private

    // The value underlying the key-value coding (KVC) and observing (KVO) compliance described below.
    NSMutableArray *_graphics;
    
    // State that's used by the undo machinery. It all gets cleared out each time the undo manager sends a checkpoint notification. _undoGroupInsertedGraphics is the set of graphics that have been inserted, if any have been inserted. _undoGroupOldPropertiesPerGraphic is a dictionary whose keys are graphics and whose values are other dictionaries, each of which contains old values of graphic properties, if graphic properties have changed. It uses an NSMapTable instead of an NSMutableDictionary so we can set it up not to copy the graphics that are used as keys, something not possible with NSMutableDictionary. And then because NSMapTables were not objects in Mac OS 10.4 and earlier we have to wrap them in NSObjects that can be reference-counted by NSUndoManager, hence SKTMapTableOwner. _undoGroupPresentablePropertyName is the result of invoking +[SKTGraphic presentablePropertyNameForKey:] for changed graphics, if the result of each invocation has been the same so far, nil otherwise. _undoGroupHasChangesToMultipleProperties is YES if changes have been made to more than one property, as determined by comparing the results of invoking +[SKTGraphic presentablePropertyNameForKey:] for changed graphics, NO otherwise.
    NSMutableSet *_undoGroupInsertedGraphics;
//    SKTMapTableOwner *_undoGroupOldPropertiesPerGraphic;
    NSString *_undoGroupPresentablePropertyName;
    BOOL _undoGroupHasChangesToMultipleProperties;
}

/* This class is KVC and KVO compliant for these keys:
 
 "canvasSize" (an NSSize-containing NSValue; read-only) - The size of the document's canvas. This is derived from the currently selected paper size and document margins.
 
 "graphics" (an NSArray of SKTGraphics; read-write) - the graphics of the document.
 
 In Sketch the graphics property of each SKTGraphicView is bound to the graphics property of the document whose contents its presented. Also, the graphics relationship of an SKTDocument is scriptable.
 
 */

// Return the current value of the property.
- (CGSize)canvasSize;

@end
