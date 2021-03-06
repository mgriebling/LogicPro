//
//  GateView.m
//  LogicPro
//
//  Created by Michael Griebling on 16Jan2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPGateView.h"
#import "LPBlock.h"
#import "LPToolPaletteController.h"
#import "LPGrid.h"

// The names of the bindings supported by this class, in addition to the ones whose support is inherited from NSView.
NSString *LPGateViewGatesBindingName = @"Gates";
NSString *LPGateViewSelectionIndexesBindingName = @"selectionIndexes";
NSString *LPGateViewGridBindingName = @"grid";

// The values that are used as contexts by this class' invocations of KVO observer registration methods. When an object like this one receives an -observeValueForKeyPath:ofObject:change:context: message it has to figure out why it's getting the message. It could distinguish based on the observed object and key path, but that's not perfectly safe, because code in the superclass might be observing the same thing for a different reason, and there's a danger of intercepting observer notifications that are meant for superclass code. The way to make sure that doesn't happen is to use a context, and make sure it's unlikely to be used as a context by superclass or subclass code. Strings like these whose pointers are not available to other compiled modules are pretty unlikely to be used by superclass or subclass code. In practice this is not a common problem, especially in a simple application like Sketch, but you should know how to do things like this the perfect way even if you decide it's not worth the hassle in your application.
static NSString *LPGateViewGatesObservationContext = @"com.c-inspirations.LPGateView.Gates";
static NSString *LPGateViewIndividualGateObservationContext = @"com.c-inspirations.LPGateView.individualGate";
static NSString *LPGateViewSelectionIndexesObservationContext = @"com.c-inspirations.LPGateView.selectionIndexes";
static NSString *LPGateViewAnyGridPropertyObservationContext = @"com.c-inspirations.LPGateView.anyGridProperty";

// The type name that this class uses when putting flattened Gates on the pasteboard during cut, copy, and paste operations. The format that's identified by it is not the exact same thing as the native document format used by SKTDocument, because SKTDocuments store NSPrintInfos (and maybe other stuff too in the future). We could easily use the exact same format for pasteboard data and document files if we decide it's worth it, but so far we haven't.
static NSString *LPGateViewPasteboardType = @"Apple Sketch 2 pasteboard type";

// The default value by which repetitively pasted sets of Gates are offset from each other, so the user can paste repeatedly and not end up with a pile of Gates that overlay each other so perfectly only the top set can be selected with the mouse.
static CGFloat LPGateViewDefaultPasteCascadeDelta = 10.0;


// Some methods that are invoked by methods above them in this file.
@interface LPGateView()
@property (nonatomic, strong) NSMutableArray *gates;

- (void)stopEditing;
- (void)stopObservingGates:(NSArray *)gates;
@end


@implementation LPGateView {
    // Information that is recorded when the "graphics" and "selectionIndexes" bindings are established. Notice that we don't keep around copies of the actual graphics array and selection indexes. Those would just be unnecessary (as far as we know, so far, without having ever done any relevant performance measurement) caches of values that really live in the bound-to objects.
    //    NSObject *_graphicsContainer;
    NSString *_gatesKeyPath;
    NSObject *_selectionIndexesContainer;
    NSString *_selectionIndexesKeyPath;
    
    // The grid that is drawn in the view and used to constrain graphics as they're created and moved. In Sketch this is just a cache of a value that canonically lives in the SKTWindowController to which this view's grid property is bound (see SKTWindowController's comments for an explanation of why the grid lives there).
    LPGrid *_grid;
    
    // The bounds of moved objects that is echoed in the ruler, if objects are being moved right now.
    CGRect _rulerEchoedBounds;
    
    // The graphic that is being created right now, if a graphic is being created right now (not explicitly retained, because it's always allocated and forgotten about in the same method).
    LPBlock *_creatingGate;
    
    // The graphic that is being edited right now, the view that it gave us to present its editing interface, and the last known frame of that view, if a graphic is being edited right now. We have to record the editing view frame because when it changes we need its old value, and the old value isn't available when this view gets the NSViewFrameDidChangeNotification. Also, the reserved thickness for the horizontal ruler accessory view before editing began, so we can restore it after editing is done. (We could do the same for the vertical ruler, but so far in Sketch there are no vertical ruler accessory views.)
    LPBlock *_editingGate;
    UIView *_editingView;
    CGRect _editingViewFrame;
    CGFloat _oldReservedThicknessForRulerAccessoryView;
    
    // The bounds of the marquee selection, if marquee selection is being done right now, NSZeroRect otherwise.
    CGRect _marqueeSelectionBounds;
    
    // Whether or not selection handles are being hidden while the user moves graphics.
    BOOL _isHidingPins;
    
    // Sometimes we temporarily hide the selection handles when the user moves graphics using the keyboard. When we do that this is the timer to start showing them again.
    NSTimer *_pinShowingTimer;
    
    // The state of the cascading of graphics that we do during repeated pastes.
    NSInteger _pasteboardChangeCount;
    NSInteger _pasteCascadeNumber;
    CGPoint _pasteCascadeDelta;
    
    // Applications are supposed to update the selection during undo and redo operations. These are the indexes of the graphics that are going to be selected at the end of an undo or redo operation.
    NSMutableIndexSet *_undoSelectionIndexes;
    
}

// An override of the superclass' designated initializer.
- (id)initWithFrame:(CGRect)frame {
    
    // Do the regular Cocoa thing.
    self = [super initWithFrame:frame];
    if (self) {
        
        // Specify what kind of pasteboard types this view can Pin being dropped on it.
//        [self registerForDraggedTypes:[[NSArray arrayWithObjects:UIColorPboardType, NSFilenamesPboardType, nil] arrayByAddingObjectsFromArray:[UIImage imagePasteboardTypes]]];
        
        // Initalize the cascading of pasted Gates.
        _pasteboardChangeCount = -1;
        _pasteCascadeNumber = 0;
        _pasteCascadeDelta = CGPointMake(LPGateViewDefaultPasteCascadeDelta, LPGateViewDefaultPasteCascadeDelta);
        _grid = [[LPGrid alloc] init];
        
    }
    return self;
}


- (void)dealloc {
    
    // If we've set a timer to show Pins invalidate it so it doesn't send a message to this object's zombie.
    [_pinShowingTimer invalidate];
    
    // Make sure any outstanding editing view doesn't cause leaks.
    [self stopEditing];
    
    // Stop observing grid changes.
    [_grid removeObserver:self forKeyPath:LPGridAnyKey];
    
    // Stop observing objects for the bindings whose support isn't implemented using NSObject's default implementations.
    [self unbind:LPGateViewGatesBindingName];
    [self unbind:LPGateViewSelectionIndexesBindingName];
    
    // Do the regular Cocoa thing.
    _grid = nil;
//    [_grid release];
//    [super dealloc];
    
}


#pragma mark *** Bindings ***


- (NSArray *)gates {
    
    // A Gate view doesn't hold onto an array of the Gates it's presenting. That would be a cache that hasn't been justified by performance measurement (not yet anyway). Get the array of Gates from the bound-to object (an array controller, in Sketch's case). It's poor practice for a method that returns a collection to return nil, so never return nil.
    if (!_gates) {
        _gates = [NSMutableArray array];
    }
    return _gates;
    
}


//- (NSMutableArray *)mutableGates {
//    
//    // Get a mutable array of Gates from the bound-to object (an array controller, in Sketch's case). The bound-to object is responsible for being KVO-compliant enough that all observers of the bound-to property get notified of whatever mutation we perform on the returned array. Trying to mutate the Gates of a Gate view whose Gates aren't bound to anything is a programming error.
////    NSAssert((_GatesContainer && _GatesKeyPath), @"An LPGateView's 'Gates' property is not bound to anything.");
//    NSMutableArray *mutableGates = [self.Gates mutableCopy];  // [_GatesContainer mutableArrayValueForKeyPath:_GatesKeyPath];
//    return mutableGates;
//    
//}


- (NSIndexSet *)selectionIndexes {
    
    // A Gate view doesn't hold onto the selection indexes. That would be a cache that hasn't been justified by performance measurement (not yet anyway). Get the selection indexes from the bound-to object (an array controller, in Sketch's case). It's poor practice for a method that returns a collection (and an index set is a collection) to return nil, so never return nil.
    NSIndexSet *selectionIndexes = [_selectionIndexesContainer valueForKeyPath:_selectionIndexesKeyPath];
    if (!selectionIndexes) {
        selectionIndexes = [NSIndexSet indexSet];
    }
    return selectionIndexes;
    
}


/* Why isn't this method called -setSelectionIndexes:? Mostly to encourage a naming convention that's useful for a few reasons:
 
 NSObject's default implementation of key-value binding (KVB) uses key-value coding (KVC) to invoke methods like -set<BindingName>: on the bound object when the bound-to property changes, to make it simple to support binding in the simple case of a view property that affects the way a view is drawn but whose value isn't directly manipulated by the user. If NSObject's default implementation of KVB were good enough to use for this "selectionIndexes" property maybe we _would_ implement a -setSelectionIndexes: method instead of stuffing so much code in -observeValueForKeyPath:ofObject:change:context: down below (but it's not, because it doesn't provide a way to get at the old and new selection indexes when they change). So, this method isn't here to take advantage of NSObject's default implementation of KVB. It's here to centralize the bindings work that must be done when the user changes the selection (check out all of the places it's invoked down below). Hopefully the different verb in this method name is a good reminder of the distinction.
 
 A person who assumes that a -set... method always succeeds, and always sets the exact value that was passed in (or throws an exception for invalid values to signal the need for some debugging), isn't assuming anything unreasonable. Setters that invalidate that assumption make a class' interface unnecessarily unpredictable and hard to program against. Sometimes they require people to write code that sets a value and then gets it right back again to keep multiple copies of the value synchronized, in case the setting didn't "take." So, avoid that. When validation is appropriate don't put it in your setter. Instead, implement a separate validation method. Follow the naming pattern established by KVC's -validateValue:forKey:error: when applicable. Now, _this_ method can't guarantee that, when it's invoked, an immediately subsequent invocation of -selectionIndexes will return the passed-in value. It's supposed to set the value of a property in the bound-to object using KVC, but only after asking the bound-to object to validate the value. So, again, -setSelectionIndexes: wouldn't be a very good name for it.
 
 */
- (void)changeSelectionIndexes:(NSIndexSet *)indexes {
    
    // After all of that talk, this method isn't invoking -validateValue:forKeyPath:error:. It will, once we come up with an example of invalid selection indexes for this case.
    
    // It will also someday take any value transformer specified as a binding option into account, so you have an example of how to do that.
    
    // Set the selection index set in the bound-to object (an array controller, in Sketch's case). The bound-to object is responsible for being KVO-compliant enough that all observers of the bound-to property get notified of the setting. Trying to set the selection indexes of a Gate view whose selection indexes aren't bound to anything is a programming error.
    NSAssert((_selectionIndexesContainer && _selectionIndexesKeyPath), @"An LPGateView's 'selectionIndexes' property is not bound to anything.");
    [_selectionIndexesContainer setValue:indexes forKeyPath:_selectionIndexesKeyPath];
    
}


- (void)setGrid:(LPGrid *)grid {
    
    // Weed out redundant invocations.
    if (grid!=_grid) {
        
        // Stop observing changes in the old grid.
        [_grid removeObserver:self forKeyPath:LPGridAnyKey];
        
        // Do the regular Cocoa thing.
        _grid = grid;
        
        // Start observing changes in the new grid so we know when to redraw it.
//        [_grid addObserver:self forKeyPath:LPGridAnyKey options:0 context:LPGateViewAnyGridPropertyObservationContext];
        
    }
    
}


- (void)startObservingGates:(NSArray *)Gates {
    
    // Start observing "drawingBounds" in each of the Gates. Use KVO's options for getting the old and new values in change notifications so we can invalidate just the old and new drawing bounds of changed Gates when they move or change size, instead of the whole view. (The new drawing bounds is easy to otherwise get using regular KVC, but the old one would otherwise have been forgotten by the time we get the notification.) Instances of LPGateView must therefore be KVC- and KVO-compliant for drawingBounds. LPGates's use of KVO's dependency mechanism means that being KVO-compliant for drawingBounds when subclassing is as easy as overriding -drawingBounds (to compute an accurate value) and +keyPathsForValuesAffectingDrawingBounds (to trigger KVO's dependency mechanism) though.
    NSIndexSet *allGateIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [Gates count])];
    [Gates addObserver:self toObjectsAtIndexes:allGateIndexes forKeyPath:LPGateDrawingBoundsKey options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *)(LPGateViewIndividualGateObservationContext)];
    
    // Start observing "drawingContents" in each of the Gates. Don't bother using KVO's options for getting the old and new values because there is no value for drawingContents. It's just something that depends on all of the properties that affect drawing of a Gate but don't affect the drawing bounds of the Gate. Similar to what we do for drawingBounds, LPGates' use of KVO's dependency mechanism means that being KVO-compliant for drawingContents when subclassing is as easy as overriding +keyPathsForValuesAffectingDrawingContents (there is no -drawingContents method to override).
    [Gates addObserver:self toObjectsAtIndexes:allGateIndexes forKeyPath:LPGateDrawingContentsKey options:0 context:(__bridge void *)(LPGateViewIndividualGateObservationContext)];
    
}


- (void)stopObservingGates:(NSArray *)Gates {
    
    // Undo what we do in -startObservingGates:.
    NSIndexSet *allGateIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [Gates count])];
    [Gates removeObserver:self fromObjectsAtIndexes:allGateIndexes forKeyPath:LPGateDrawingContentsKey];
    [Gates removeObserver:self fromObjectsAtIndexes:allGateIndexes forKeyPath:LPGateDrawingBoundsKey];
    
}


// An override of the NSObject(NSKeyValueBindingCreation) method.
//- (void)bind:(NSString *)bindingName toObject:(id)observableObject withKeyPath:(NSString *)observableKeyPath options:(NSDictionary *)options {
//    
//    // LPGateView supports several different bindings.
//    if ([bindingName isEqualToString:LPGateViewGatesBindingName]) {
//        
//        // We don't have any options to support for our custom "Gates" binding.
//        NSAssert(([options count]==0), @"LPGateView doesn't support any options for the 'Gates' binding.");
//        
//        // Rebinding is just as valid as resetting.
//        if (_GatesContainer || _GatesKeyPath) {
//            [self unbind:LPGateViewGatesBindingName];
//        }
//        
//        // Record the information about the binding.
//        _GatesContainer = observableObject;
//        _GatesKeyPath = [observableKeyPath copy];
//        
//        // Start observing changes to the array of Gates to which we're bound, and also start observing properties of the Gates themselves that might require redrawing.
//        [_GatesContainer addObserver:self forKeyPath:_GatesKeyPath options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *)(LPGateViewGatesObservationContext)];
//        [self startObservingGates:[_GatesContainer valueForKeyPath:_GatesKeyPath]];
//        
//        // Redraw the whole view to make the binding take immediate visual effect. We could be much cleverer about this and just redraw the part of the view that needs it, but in typical usage the view isn't even visible yet, so that would probably be a waste of time (the programmer's and the computer's). If this view ever gets reused in some wildly dynamic situation where the bindings come and go we can reconsider optimization decisions like this then.
//        [self setNeedsDisplay];
//        
//    } else if ([bindingName isEqualToString:LPGateViewSelectionIndexesBindingName]) {
//        
//        // We don't have any options to support for our custom "selectionIndexes" binding either. Maybe in the future someone will imagine a use for a value transformer on this, and we'll add support for it then.
//        NSAssert(([options count]==0), @"LPGateView doesn't support any options for the 'selectionIndexes' binding.");
//        
//        // Rebinding is just as valid as resetting.
//        if (_selectionIndexesContainer || _selectionIndexesKeyPath) {
//            [self unbind:LPGateViewSelectionIndexesBindingName];
//        }
//        
//        // Record the information about the binding.
//        _selectionIndexesContainer = observableObject;
//        _selectionIndexesKeyPath = [observableKeyPath copy];
//        
//        // Start observing changes to the selection indexes to which we're bound.
//        [_selectionIndexesContainer addObserver:self forKeyPath:_selectionIndexesKeyPath options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *)(LPGateViewSelectionIndexesObservationContext)];
//        
//        // Same comment as above.
//        [self setNeedsDisplay];
//        
//    } else {
//        
//        // For every binding except "Gates" and "selectionIndexes" just use NSObject's default implementation. It will start observing the bound-to property. When a KVO notification is sent for the bound-to property, this object will be sent a [self setValue:theNewValue forKey:theBindingName] message, so this class just has to be KVC-compliant for a key that is the same as the binding name, like "grid." That's why this class has a -setGrid: method. Also, NSView supports a few simple bindings of its own, and there's no reason to get in the way of those.
////        [super bind:bindingName toObject:observableObject withKeyPath:observableKeyPath options:options];
//        
//    }
//    
//}


// An override of the NSObject(NSKeyValueBindingCreation) method.
- (void)unbind:(NSString *)bindingName {
    
    // LPGateView supports several different bindings. For the ones that don't use NSObject's default implementation of key-value binding, undo what we do in -bind:toObject:withKeyPath:options:, and then redraw the whole view to make the unbinding take immediate visual effect.
    if ([bindingName isEqualToString:LPGateViewGatesBindingName]) {
        [self stopObservingGates:[self gates]];
//        [_GatesContainer removeObserver:self forKeyPath:_GatesKeyPath];
//        _GatesContainer = nil;
        _gatesKeyPath = nil;
        [self setNeedsDisplay];
    } else if ([bindingName isEqualToString:LPGateViewSelectionIndexesBindingName]) {
        [_selectionIndexesContainer removeObserver:self forKeyPath:_selectionIndexesKeyPath];
        _selectionIndexesContainer = nil;
        _selectionIndexesKeyPath = nil;
        [self setNeedsDisplay];
    } else {
        
        // // For every binding except "Gates" and "selectionIndexes" just use NSObject's default implementation. Also, NSView supports a few simple bindings of its own, and there's no reason to get in the way of those.
//        [super unbind:bindingName];
        
    }
    
}


// An override of the NSObject(NSKeyValueObserving) method.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(NSObject *)observedObject change:(NSDictionary *)change context:(void *)context {
    
    // An LPGateView observes several different kinds of objects, for several different reasons. Use the observation context value to distinguish between them. We can do a simple pointer comparison because KVO doesn't do anything at all with the context value, not even retain or copy it.
    if (context==(__bridge void *)(LPGateViewGatesObservationContext)) {
        
        // The "old value" or "new value" in a change dictionary will be NSNull, instead of just not existing, if the corresponding option was specified at KVO registration time and the value for some key in the key path is nil. In Sketch's case there are times in an LPGateView's life cycle when it's bound to the Gates of a window controller's document, and the window controller's document is nil. Don't redraw the Gate view when we get notifications about that.
        
        // Have Gates been removed from the bound-to container?
        NSArray *oldGates = [change objectForKey:NSKeyValueChangeOldKey];
        if (![oldGates isEqual:[NSNull null]]) {
            
            // Yes. Stop observing them because we don't want to leave dangling observations.
            [self stopObservingGates:oldGates];
            
            // Redraw just the parts of the view that they used to occupy.
            NSUInteger GateCount = [oldGates count];
            for (NSUInteger index = 0; index<GateCount; index++) {
                [self setNeedsDisplayInRect:[[oldGates objectAtIndex:index] drawingBounds]];
            }
            
            // If a Gate is being edited right now, and the Gate is being removed, stop the editing. This way we don't strand an editing view whose Gate has been pulled out from under it. This situation can arise from undoing and scripting.
            if (_editingGate && [oldGates containsObject:_editingGate]) {
                [self stopEditing];
            }
            
        }
        
        // Have Gates been added to the bound-to container?
        NSArray *newGates = [change objectForKey:NSKeyValueChangeNewKey];
        if (![newGates isEqual:[NSNull null]]) {
            
            // Yes. Start observing them so we know when we need to redraw the parts of the view where they sit.
            [self startObservingGates:newGates];
            
            // Redraw just the parts of the view that they now occupy.
            NSUInteger GateCount = [newGates count];
            for (NSUInteger index = 0; index<GateCount; index++) {
                [self setNeedsDisplayInRect:[[newGates objectAtIndex:index] drawingBounds]];
            }
            
            // If undoing or redoing is being done we have to select the Gates that are being added. For NSKeyValueChangeSetting the change dictionary has no NSKeyValueChangeIndexesKey entry, so we have to figure out the indexes ourselves, which is easy. For NSKeyValueChangeRemoval the indexes are not the indexes of anything being added. You might notice that this is only place in this entire method that we check the value of the NSKeyValueChangeKindKey entry. In general, doing so should be pretty uncommon in overrides of -observeValueForKeyPath:ofObject:change:context:, because the values of the other entries are usually all you need, and handling all of the possible NSKeyValueChange values requires care. In Sketch we'll never see NSKeyValueChangeSetting or NSKeyValueChangeReplacement but we want to demonstrate a reusable class so we Pin them anyway.
            NSIndexSet *additionalUndoSelectionIndexes = nil;
            NSKeyValueChange changeKind = [[change objectForKey:NSKeyValueChangeKindKey] integerValue];
            if (changeKind==NSKeyValueChangeSetting) {
                additionalUndoSelectionIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [newGates count])];
            } else if (changeKind!=NSKeyValueChangeRemoval) {
                additionalUndoSelectionIndexes = [change objectForKey:NSKeyValueChangeIndexesKey];
            }
            if (additionalUndoSelectionIndexes) {
                
                // Use -[NSIndexSet addIndexes:] instead of just replacing the value of _undoSelectionIndexes because we don't know that a single undo action won't include more than one addition of Gates.
                [_undoSelectionIndexes addIndexes:additionalUndoSelectionIndexes];
                
            }
            
        }
        
    } else if (context==(__bridge void *)(LPGateViewIndividualGateObservationContext)) {
        
        // Has a Gate's drawing bounds changed, or some other value that affects how it appears?
        if ([keyPath isEqualToString:LPGateDrawingBoundsKey]) {
            
            // Redraw the part of the view that the Gate used to occupy, and the part that it now occupies.
//            CGRect oldGateDrawingBounds = [[change objectForKey:NSKeyValueChangeOldKey] rectValue];
//            [self setNeedsDisplayInRect:oldGateDrawingBounds];
//            CGRect newGateDrawingBounds = [[change objectForKey:NSKeyValueChangeNewKey] rectValue];
//            [self setNeedsDisplayInRect:newGateDrawingBounds];
            
        } else if ([keyPath isEqualToString:LPGateDrawingContentsKey]) {
            
            // The Gate's drawing bounds hasn't changed, so just redraw the part of the view that it occupies right now.
            CGRect GateDrawingBounds = [(LPBlock *)observedObject drawingBounds];
            [self setNeedsDisplayInRect:GateDrawingBounds];
            
        } // else something truly bizarre has happened.
        
        // If undoing or redoing is being done add this Gate to the set that will be selected at the end of the undo action. -[NSArray indexOfObject:] is a dangerous method from a performance standpoint. Maybe an undo action that affects many Gates at once will be slow. Maybe something else in this very simple-looking bit of code will be a problem. We just don't yet know whether there will be a performance problem that the user can notice here. We'll check when we do real performance measurement on Sketch someday. At least we've limited the potential problem to undoing and redoing by checking _undoSelectionIndexes!=nil. One thing we do know right now is that we're not using memory to record selection changes on the undo/redo stacks, and that's a good thing.
        if (_undoSelectionIndexes) {
            NSUInteger gateIndex = [[self gates] indexOfObject:observedObject];
            if (gateIndex!=NSNotFound) {
                [_undoSelectionIndexes addIndex:gateIndex];
            } // else something truly bizarre has happened.
        }
        
    } else if (context==(__bridge void *)(LPGateViewSelectionIndexesObservationContext)) {
        
        // Some selection indexes might have been removed, some might have been added. Redraw the selection Pins for any Gate whose selectedness has changed, unless the binding is changing completely (signalled by null old or new value), in which case just redraw the whole view.
        NSIndexSet *oldSelectionIndexes = [change objectForKey:NSKeyValueChangeOldKey];
        NSIndexSet *newSelectionIndexes = [change objectForKey:NSKeyValueChangeNewKey];
        if (![oldSelectionIndexes isEqual:[NSNull null]] && ![newSelectionIndexes isEqual:[NSNull null]]) {
            for (NSUInteger oldSelectionIndex = [oldSelectionIndexes firstIndex]; oldSelectionIndex!=NSNotFound; oldSelectionIndex = [oldSelectionIndexes indexGreaterThanIndex:oldSelectionIndex]) {
                if (![newSelectionIndexes containsIndex:oldSelectionIndex]) {
                    LPBlock *deselectedGate = [[self gates] objectAtIndex:oldSelectionIndex];
                    [self setNeedsDisplayInRect:[deselectedGate drawingBounds]];
                }
            }
            for (NSUInteger newSelectionIndex = [newSelectionIndexes firstIndex]; newSelectionIndex!=NSNotFound; newSelectionIndex = [newSelectionIndexes indexGreaterThanIndex:newSelectionIndex]) {
                if (![oldSelectionIndexes containsIndex:newSelectionIndex]) {
                    LPBlock *selectedGate = [[self gates] objectAtIndex:newSelectionIndex];
                    [self setNeedsDisplayInRect:[selectedGate drawingBounds]];
                }
            }
        } else {
            [self setNeedsDisplay];
        }
	    
    } else if (context==(__bridge void *)(LPGateViewAnyGridPropertyObservationContext)) {
        
        // Either a new grid is to be used (this only happens once in Sketch) or one of the properties of the grid has changed. Regardless, redraw everything.
        [self setNeedsDisplay];
        
    } else {
        
        // In overrides of -observeValueForKeyPath:ofObject:change:context: always invoke super when the observer notification isn't recognized. Code in the superclass is apparently doing observation of its own. NSObject's implementation of this method throws an exception. Such an exception would be indicating a programming error that should be fixed.
        [super observeValueForKeyPath:keyPath ofObject:observedObject change:change context:context];
        
    }
    
}


// This doesn't contribute to any KVC or KVO compliance. It's just a convenience method that's invoked down below.
- (NSArray *)selectedGates {
    
    // Simple, because we made sure -Gates and -selectionIndexes never return nil.
    return [[self gates] objectsAtIndexes:[self selectionIndexes]];
    
}


#pragma mark *** Drawing ***


// An override of the NSView method.
- (void)drawRect:(CGRect)rect {
    
    // Draw the background background.
    [[UIColor whiteColor] set];
    UIRectFill(rect);
    
    // Draw the grid.
    [_grid drawRect:rect inView:self];
    
    // Draw every Gate that intersects the rectangle to be drawn. In Sketch the frontmost Gates have the lowest indexes.
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    NSArray *gates = [self gates];
//    NSIndexSet *selectionIndexes = [self selectionIndexes];
    NSInteger gateCount = [gates count];
    for (NSInteger index = gateCount - 1; index>=0; index--) {
        LPBlock *gate = [gates objectAtIndex:index];
        CGRect gateDrawingBounds = [gate drawingBounds];
        if (CGRectIntersectsRect(rect, gateDrawingBounds)) {
            
            // Figure out whether or not to draw selection Pins on the Gate. Selection Pins are drawn for all selected objects except:
            // - While the selected objects are being moved.
            // - For the object actually being created or edited, if there is one.
            BOOL drawSelectionPins = YES;
//            if (!_isHidingPins && gate!=_creatingGate && gate!=_editingGate) {
//                drawSelectionPins = [selectionIndexes containsIndex:index];
//            }
            
            // Draw the Gate, possibly with selection Pins.
            CGContextSaveGState(currentContext);
            CGContextClipToRect(currentContext, gateDrawingBounds);
            [gate drawContentsInView:self isBeingCreateOrEdited:(gate==_creatingGate || gate==_editingGate)];
            if (drawSelectionPins) {
                [gate drawPinsInView:self];
            }
            CGContextRestoreGState(currentContext);
            
        }
    }
    
    // If the user is in the middle of selecting draw the selection rectangle.
    if (!CGRectEqualToRect(_marqueeSelectionBounds, CGRectZero)) {
        [[UIColor darkGrayColor] set];
        CGContextStrokeRect(currentContext, _marqueeSelectionBounds);
    }
    
}


- (void)beginEchoingMoveToRulers:(CGRect)echoRect {
//    NSRulerView *horizontalRuler = [[self enclosingScrollView] horizontalRulerView];
//    NSRulerView *verticalRuler = [[self enclosingScrollView] verticalRulerView];
//    
//    CGRect newHorizontalRect = [self convertRect:echoRect toView:horizontalRuler];
//    CGRect newVerticalRect = [self convertRect:echoRect toView:verticalRuler];
//    
//    [horizontalRuler moveRulerlineFromLocation:-1.0 toLocation:CGRectGetMinX(newHorizontalRect)];
//    [horizontalRuler moveRulerlineFromLocation:-1.0 toLocation:CGRectGetMidX(newHorizontalRect)];
//    [horizontalRuler moveRulerlineFromLocation:-1.0 toLocation:CGRectGetMaxX(newHorizontalRect)];
//    
//    [verticalRuler moveRulerlineFromLocation:-1.0 toLocation:CGRectGetMinY(newVerticalRect)];
//    [verticalRuler moveRulerlineFromLocation:-1.0 toLocation:CGRectGetMidY(newVerticalRect)];
//    [verticalRuler moveRulerlineFromLocation:-1.0 toLocation:CGRectGetMaxY(newVerticalRect)];
//    
//    _rulerEchoedBounds = echoRect;
}

- (void)continueEchoingMoveToRulers:(CGRect)echoRect {
//    NSRulerView *horizontalRuler = [[self enclosingScrollView] horizontalRulerView];
//    NSRulerView *verticalRuler = [[self enclosingScrollView] verticalRulerView];
//    
//    CGRect oldHorizontalRect = [self convertRect:_rulerEchoedBounds toView:horizontalRuler];
//    CGRect oldVerticalRect = [self convertRect:_rulerEchoedBounds toView:verticalRuler];
//    
//    CGRect newHorizontalRect = [self convertRect:echoRect toView:horizontalRuler];
//    CGRect newVerticalRect = [self convertRect:echoRect toView:verticalRuler];
//    
//    [horizontalRuler moveRulerlineFromLocation:CGRectGetMinX(oldHorizontalRect) toLocation:CGRectGetMinX(newHorizontalRect)];
//    [horizontalRuler moveRulerlineFromLocation:CGRectGetMidX(oldHorizontalRect) toLocation:CGRectGetMidX(newHorizontalRect)];
//    [horizontalRuler moveRulerlineFromLocation:CGRectGetMaxX(oldHorizontalRect) toLocation:CGRectGetMaxX(newHorizontalRect)];
//    
//    [verticalRuler moveRulerlineFromLocation:CGRectGetMinY(oldVerticalRect) toLocation:CGRectGetMinY(newVerticalRect)];
//    [verticalRuler moveRulerlineFromLocation:CGRectGetMidY(oldVerticalRect) toLocation:CGRectGetMidY(newVerticalRect)];
//    [verticalRuler moveRulerlineFromLocation:CGRectGetMaxY(oldVerticalRect) toLocation:CGRectGetMaxY(newVerticalRect)];
//    
//    _rulerEchoedBounds = echoRect;
}

- (void)stopEchoingMoveToRulers {
//    NSRulerView *horizontalRuler = [[self enclosingScrollView] horizontalRulerView];
//    NSRulerView *verticalRuler = [[self enclosingScrollView] verticalRulerView];
//    
//    CGRect oldHorizontalRect = [self convertRect:_rulerEchoedBounds toView:horizontalRuler];
//    CGRect oldVerticalRect = [self convertRect:_rulerEchoedBounds toView:verticalRuler];
//    
//    [horizontalRuler moveRulerlineFromLocation:CGRectGetMinX(oldHorizontalRect) toLocation:-1.0];
//    [horizontalRuler moveRulerlineFromLocation:CGRectGetMidX(oldHorizontalRect) toLocation:-1.0];
//    [horizontalRuler moveRulerlineFromLocation:CGRectGetMaxX(oldHorizontalRect) toLocation:-1.0];
//    
//    [verticalRuler moveRulerlineFromLocation:CGRectGetMinY(oldVerticalRect) toLocation:-1.0];
//    [verticalRuler moveRulerlineFromLocation:CGRectGetMidY(oldVerticalRect) toLocation:-1.0];
//    [verticalRuler moveRulerlineFromLocation:CGRectGetMaxY(oldVerticalRect) toLocation:-1.0];
//    
//    _rulerEchoedBounds = NSZeroRect;
}


#pragma mark *** Editing Subviews ***


- (void)setNeedsDisplayForEditingViewFrameChangeNotification:(NSNotification *)viewFrameDidChangeNotification {
    
    // If the editing view got smaller we have to redraw where it was or cruft will be left on the screen. If the editing view got larger we might be doing some redundant invalidation (not a big deal), but we're not doing any redundant drawing (which might be a big deal). If the editing view actually moved then we might be doing substantial redundant drawing, but so far that wouldn't happen in Sketch.
    // In Sketch this prevents cruft being left on the screen when the user 1) creates a great big text area and fills it up with text, 2) sizes the text area so not all of the text fits, 3) starts editing the text area but doesn't actually change it, so the text area hasn't been automatically resized and the text editing view is actually bigger than the text area, and 4) deletes so much text in one motion (Select All, then Cut) that the text editing view suddenly becomes smaller than the text area. In every other text editing situation the text editing view's invalidation or the fact that the SKTText's "drawingBounds" changes is enough to cause the proper redrawing.
    CGRect newEditingViewFrame = [[viewFrameDidChangeNotification object] frame];
    [self setNeedsDisplayInRect:CGRectUnion(_editingViewFrame, newEditingViewFrame)];
    _editingViewFrame = newEditingViewFrame;
    
}


- (void)startEditingGate:(LPBlock *)Gate {
    
    // It's the responsibility of invokers to not invoke this method when editing has already been started.
    NSAssert((!_editingGate && !_editingView), @"-[LPGateView startEditingGate:] is being mis-invoked.");
    
    // Can the Gate even provide an editing view?
    _editingView = [Gate newEditingViewWithSuperviewBounds:[self bounds]];
    if (_editingView) {
        
        // Keep a pointer to the Gate around so we can ask it to draw its "being edited" look, and eventually send it a -finalizeEditingView: message.
        _editingGate = Gate;
        
        // If the editing view adds a ruler accessory view we're going to remove it when editing is done, so we have to remember the old reserved accessory view thickness so we can restore it. Otherwise there will be a big blank space in the ruler.
//        _oldReservedThicknessForRulerAccessoryView = [[[self enclosingScrollView] horizontalRulerView] reservedThicknessForAccessoryView];
        
        // Make the editing view a subview of this one. It was the Gate's job to make sure that it was created with the right frame and bounds.
        [self addSubview:_editingView];
        
        // Make the editing view the first responder so it takes key events and relevant menu item commands.
        
//        [[self window] makeFirstResponder:_editingView];
        
        // Get notified if the editing view's frame gets smaller, because we may have to force redrawing when that happens. Record the view's frame because it won't be available when we get the notification.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setNeedsDisplayForEditingViewFrameChangeNotification:) name:UIScreenModeDidChangeNotification object:_editingView];
        _editingViewFrame = [_editingView frame];
        
        // Give the Gate being edited a chance to draw one more time. In Sketch, SKTText draws a focus ring.
        [self setNeedsDisplayInRect:[_editingGate drawingBounds]];
        
    }
    
}


- (void)stopEditing {
    
    // Make it harmless to invoke this method unnecessarily.
    if (_editingView) {
        
        // Undo what we did in -startEditingGate:.
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenModeDidChangeNotification object:_editingView];
        
        // Pull the editing view out of this one. When editing is being stopped because the user has clicked in this view, outside of the editing view, NSWindow will have already made this view the window's first responder, and that's good. However, when editing is being stopped because the edited Gate is being removed (by undoing or scripting, for example), the invocation of -[NSView removeFromSuperview] we do here will leave the window as its own first responder, and that would be bad, so also fix the window's first responder if appropriate. It wouldn't be appropriate to steal first-respondership from sibling views here.
        BOOL makeSelfFirstResponder = _editingView.isFirstResponder;
        [_editingView removeFromSuperview];
        if (makeSelfFirstResponder) {
//            [[self window] makeFirstResponder:self];
            [self becomeFirstResponder];
        }
        
        // If the editing view added a ruler accessory view then remove it because it's not applicable anymore, and get rid of the blank space in the ruler that would otherwise result. In Sketch the NSTextViews created by SKTTexts leave horizontal ruler accessory views.
//        NSRulerView *horizontalRulerView = [[self enclosingScrollView] horizontalRulerView];
//        [horizontalRulerView setAccessoryView:nil];
//        [horizontalRulerView setReservedThicknessForAccessoryView:_oldReservedThicknessForRulerAccessoryView];
	    
        // Give the Gate that created the editing view a chance to tear down their relationships and then forget about them both.
        [_editingGate finalizeEditingView:_editingView];
        _editingGate = nil;
        _editingView = nil;
        
    }
    
}


#pragma mark *** Mouse Event Handling ***


- (LPBlock *)gateUnderPoint:(CGPoint)point index:(NSUInteger *)outIndex isSelected:(BOOL *)outIsSelected pin:(LPPin **)outPin {
    
    // We don't touch *outIndex, *outIsSelected, or *outPin if we return nil. Those values are undefined if we don't return a match.
    
    // Search through all of the Gates, front to back, looking for one that claims that the point is on a selection Pin (if it's selected) or in the contents of the Gate itself.
    LPBlock *gateToReturn = nil;
    NSArray *gates = [self gates];
    NSIndexSet *selectionIndexes = [self selectionIndexes];
    NSUInteger gateCount = [gates count];
    for (NSUInteger index = 0; index<gateCount; index++) {
        LPBlock *gate = [gates objectAtIndex:index];
        
        // Do a quick check to weed out Gates that aren't even in the neighborhood.
        if (CGRectContainsPoint([gate drawingBounds], point)) {
            
            // Check the Gate's selection Pins first, because they take precedence when they overlap the Gate's contents.
            BOOL gateIsSelected = [selectionIndexes containsIndex:index];
            if (gateIsSelected) {
                LPPin *pin = [gate pinUnderPoint:point];
                if (pin!=LPGateNoPin) {
                    
                    // The user clicked on a Pin of a selected Gate.
                    gateToReturn = gate;
                    if (outPin) {
                        *outPin = pin;
                    }
                    
                }
            }
            if (!gateToReturn) {
                BOOL clickedOnGateContents = [gate isContentsUnderPoint:point];
                if (clickedOnGateContents) {
                    
                    // The user clicked on the contents of a Gate.
                    gateToReturn =gate;
                    if (outPin) {
                        *outPin = (LPPin *)LPGateNoPin;
                    }
                    
                }
            }
            if (gateToReturn) {
                
                // Return values and stop looking.
                if (outIndex) {
                    *outIndex = index;
                }
                if (outIsSelected) {
                    *outIsSelected = gateIsSelected;
                }
                break;
                
            }
            
        }
        
    }
    return gateToReturn;
    
}

- (void)moveSelectedGatesWithEvent:(UIPanGestureRecognizer *)event {
    CGPoint lastPoint, curPoint;
    NSArray *selGates = [self selectedGates];
    NSUInteger c;
    BOOL didMove = NO, isMoving = NO;
    BOOL echoToRulers = NO;  // [[self enclosingScrollView] rulersVisible];
    CGRect selBounds = [[LPBlock self] boundsOfGates:selGates];
    
    c = [selGates count];
    
    lastPoint = [event locationInView:self];
    CGPoint selOriginOffset = CGPointMake((lastPoint.x - selBounds.origin.x), (lastPoint.y - selBounds.origin.y));
    if (echoToRulers) {
        [self beginEchoingMoveToRulers:selBounds];
    }
    
    if ([event isKindOfClass:[UIPanGestureRecognizer class]]) {
//        event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
//        [self autoscroll:event];
        curPoint = [event locationInView:self];
        if (!isMoving && ((fabs(curPoint.x - lastPoint.x) >= 2.0) || (fabs(curPoint.y - lastPoint.y) >= 2.0))) {
            isMoving = YES;
            _isHidingPins = YES;
        }
        if (isMoving) {
            if (_grid) {
                CGPoint boundsOrigin;
                boundsOrigin.x = curPoint.x - selOriginOffset.x;
                boundsOrigin.y = curPoint.y - selOriginOffset.y;
                boundsOrigin  = [_grid constrainedPoint:boundsOrigin];
                curPoint.x = boundsOrigin.x + selOriginOffset.x;
                curPoint.y = boundsOrigin.y + selOriginOffset.y;
            }
            if (!CGPointEqualToPoint(lastPoint, curPoint)) {
                [[LPGateView class] translateGates:selGates byX:(curPoint.x - lastPoint.x) y:(curPoint.y - lastPoint.y)];
                didMove = YES;
//                if (echoToRulers) {
//                    [self continueEchoingMoveToRulers:CGRectMake(curPoint.x - selOriginOffset.x, curPoint.y - selOriginOffset.y, NSWidth(selBounds),NSHeight(selBounds))];
//                }
                // Adjust the delta that is used for cascading pastes.  Pasting and then moving the pasted Gate is the way you determine the cascade delta for subsequent pastes.
                _pasteCascadeDelta.x += (curPoint.x - lastPoint.x);
                _pasteCascadeDelta.y += (curPoint.y - lastPoint.y);
            }
            lastPoint = curPoint;
        }
    }
    
    if (echoToRulers)  {
        [self stopEchoingMoveToRulers];
    }
    if (isMoving) {
        _isHidingPins = NO;
        [self setNeedsDisplayInRect:[LPBlock drawingBoundsOfGates:selGates]];
        if (didMove) {
            // Only if we really moved.
            [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Move", @"UndoStrings", @"Action name for moves.")];
            
            // Post appropriate accessibility notification
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self);
        }
    }
}


//- (void)resizeGate:(LPGate *)Gate usingPin:(NSInteger)pin withEvent:(id)event {
//    
//    BOOL echoToRulers = NO; // [[self enclosingScrollView] rulersVisible];
//    if (echoToRulers) {
//        [self beginEchoingMoveToRulers:[Gate bounds]];
//    }
//    
//    if ([event isKindOfClass:[UIPanGestureRecognizer class]]) {
////        event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
////        [self autoscroll:event];
//        CGPoint pinLocation = [event locationInView:self];
//        if (_grid) {
//            pinLocation = [_grid constrainedPoint:pinLocation];
//        }
//        pin = [Gate resizeByMovingPin:pin toPoint:pinLocation];
//        if (echoToRulers) {
//            [self continueEchoingMoveToRulers:[Gate bounds]];
//        }
//    }
//    
//    if (echoToRulers) {
//        [self stopEchoingMoveToRulers];
//    }
//    
//    [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Resize", @"UndoStrings", @"Action name for resizes.")];
//    
//}


- (NSIndexSet *)indexesOfGatesIntersectingRect:(CGRect)rect {
    NSMutableIndexSet *indexSetToReturn = [NSMutableIndexSet indexSet];
    NSArray *gates = [self gates];
    NSUInteger gateCount = [gates count];
    for (NSUInteger index = 0; index<gateCount; index++) {
        LPBlock *gate = [gates objectAtIndex:index];
        if (CGRectIntersectsRect(rect, [gate drawingBounds])) {
            [indexSetToReturn addIndex:index];
        }
    }
    return indexSetToReturn;
}


- (void)createGateOfClass:(Class)GateClass withEvent:(UIGestureRecognizer *)event {
    
    // Before we invoke -[NSUndoManager beginUndoGrouping] turn off automatic per-event-loop group creation. If we don't turn it off now, -beginUndoGrouping will actually create _two_ undo groups: the top-level automatically-created one and then the nested one that we're explicitly creating. When we invoke -undoNestedGroup down below, the automatically-created undo group will be left on the undo stack. It will be ended automatically at the end of the event loop, which is good, and it will be empty, which is expected, but it will be left on the undo stack so the user will see a useless undo action in the Edit menu, which is bad. Is this a bug in NSUndoManager? Well it's certainly surprising that NSUndoManager isn't bright enough to ignore empty undo groups, especially ones that it itself created automatically, so NSUndoManager could definitely use a little improvement here.
    NSUndoManager *undoManager = [self undoManager];
    BOOL undoManagerWasGroupingByEvent = [undoManager groupsByEvent];
    [undoManager setGroupsByEvent:NO];
    
    // We will want to undo the creation of the Gate if the user sizes it to nothing, so create a new group for everything undoable that's going to happen during Gate creation.
    [undoManager beginUndoGrouping];
    
    // Clear the selection.
//    [self changeSelectionIndexes:[NSIndexSet indexSet]];
    
    CGPoint gateOrigin;
    CGSize gateSize;
    if (event!=nil) {
        // Where is the mouse pointer as Gate creation is starting? Should the location be constrained to the grid?
        gateOrigin = [event locationInView:self];
        gateSize = CGSizeMake(75.0f, 50.0f);
        if (_grid) {
            gateOrigin = [_grid constrainedPoint:gateOrigin];
        }
    } else {
        // If there is no event, then automatically add a Gate at (10,10). Should the location and size be constrained to the grid?
        gateOrigin = CGPointMake(10.0f, 10.0f);
        gateSize = CGSizeMake(100.0f, 100.0f);
        
        if (_grid) {
            gateOrigin = [_grid constrainedPoint:gateOrigin];
            
            CGPoint gateEndPoint = [_grid constrainedPoint:CGPointMake(gateOrigin.x+gateSize.width, gateOrigin.y+gateSize.height)];
            gateSize = CGSizeMake(gateEndPoint.x - gateOrigin.x, gateEndPoint.y - gateOrigin.y);
        }
    }
    
    // Create the new Gate and set what little we know of its location.
    _creatingGate = [[GateClass alloc] init];
    [_creatingGate setBounds:CGRectMake(gateOrigin.x, gateOrigin.y, gateSize.width, gateSize.height)];
    if ([_creatingGate canMakeNaturalSize]) [_creatingGate makeNaturalSize];
    
    // Add it to the set of Gates right away so that it will show up in other views of the same array of Gates as the user sizes it.
    [self.gates insertObject:_creatingGate atIndex:0];
    
    // If this was triggered by a user event then allow the user size the new Gate until they let go of the mouse. Because different kinds of Gates have different kinds of Pins, first ask the Gate class what Pin the user is dragging during this initial sizing.
//    if (event) {
//        [self resizeGate:_creatingGate usingPin:[GateClass creationSizingPin] withEvent:event];
//    }
    
    // Why don't we do [undoManager endUndoGrouping] here, once, instead of twice in the following paragraphs? Because of the [undoManager setGroupsByEvent:NO] game we're playing. If we invoke -[NSUndoManager setActionName:] down below after invoking [undoManager endUndoGrouping] there won't be any open undo group, and NSUndoManager will raise an exception. If we weren't playing the [undoManager setGroupsByEvent:NO] game then it would be OK to invoke -[NSUndoManager setActionName:] after invoking [undoManager endUndoGrouping] because the action name would apply to the top-level automatically-created undo group, which is fine.
    
    // Did we really create a Gate? Don't check with !NSIsEmptyRect(createdGateBounds) because the bounds of a perfectly horizontal or vertical line is "empty" but of course we want to let people create those.
    CGRect createdGateBounds = [_creatingGate bounds];
    
    if (CGRectGetWidth(createdGateBounds)!=0.0 || CGRectGetHeight(createdGateBounds)!=0.0) {
        
        // Select it.
//        [self changeSelectionIndexes:[NSIndexSet indexSetWithIndex:0]];
        
        // The Gate wasn't sized to nothing during mouse tracking. Present its editing interface it if it's that kind of Gate (like Sketch's SKTTexts). Invokers of the method we're in right now should have already cleared out _editingView.
        [self startEditingGate:_creatingGate];
        
        // Overwrite whatever undo action name was registered during all of that with a more specific one.
        [undoManager setActionName:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Create %@", @"UndoStrings", @"Action name for newly created Gates. Class name is inserted at the substitution."), [[NSBundle mainBundle] localizedStringForKey:NSStringFromClass(GateClass) value:@"" table:@"GateClassNames"]]];
        
        // Balance the invocation of -[NSUndoManager beginUndoGrouping] that we did up above.
        [undoManager endUndoGrouping];
        
    } else {
        
        // Balance the invocation of -[NSUndoManager beginUndoGrouping] that we did up above.
        [undoManager endUndoGrouping];
        
        // The Gate was sized to nothing during mouse tracking. Undo everything that was just done. Disable undo registration while undoing so that we don't create a spurious redo action.
        [undoManager disableUndoRegistration];
        [undoManager undoNestedGroup];
        [undoManager enableUndoRegistration];
        
    }
    
    // Balance the invocation of -[NSUndoManager setGroupsByEvent:] that we did up above. We're careful to restore the old value instead of merely invoking -setGroupsByEvent:YES because we don't know that the method we're in right now won't in the future be invoked by some other method that plays its own NSUndoManager games.
    [undoManager setGroupsByEvent:undoManagerWasGroupingByEvent];
    [self setNeedsDisplay];
    
    // Done.
    _creatingGate = nil;
    
}


- (void)marqueeSelectWithEvent:(UIGestureRecognizer *)event {
    
    // Dequeue and Pin mouse events until the user lets go of the mouse button.
    NSIndexSet *oldSelectionIndexes = [self selectionIndexes];
    CGPoint originalMouseLocation = [event locationInView:self];
    if ([event isKindOfClass:[UIPanGestureRecognizer class]]) {
//        event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
//        [self autoscroll:event];
        CGPoint currentMouseLocation = [event locationInView:self];
        
        // Figure out a new a selection rectangle based on the mouse location.
        CGRect newMarqueeSelectionBounds = CGRectMake(fmin(originalMouseLocation.x, currentMouseLocation.x), fmin(originalMouseLocation.y, currentMouseLocation.y), fabs(currentMouseLocation.x - originalMouseLocation.x), fabs(currentMouseLocation.y - originalMouseLocation.y));
        if (!CGRectEqualToRect(newMarqueeSelectionBounds, _marqueeSelectionBounds)) {
            
            // Erase the old selection rectangle and draw the new one.
            [self setNeedsDisplayInRect:_marqueeSelectionBounds];
            _marqueeSelectionBounds = newMarqueeSelectionBounds;
            [self setNeedsDisplayInRect:_marqueeSelectionBounds];
            
            // Either select or deselect all of the Gates that intersect the selection rectangle.
            NSIndexSet *indexesOfGatesInRubberBand = [self indexesOfGatesIntersectingRect:_marqueeSelectionBounds];
            NSMutableIndexSet *newSelectionIndexes = [oldSelectionIndexes mutableCopy];
            for (NSUInteger index = [indexesOfGatesInRubberBand firstIndex]; index!=NSNotFound; index = [indexesOfGatesInRubberBand indexGreaterThanIndex:index]) {
                if ([newSelectionIndexes containsIndex:index]) {
                    [newSelectionIndexes removeIndex:index];
                } else {
                    [newSelectionIndexes addIndex:index];
                }
            }
            [self changeSelectionIndexes:newSelectionIndexes];
            
        }
    }
    
    // Schedule the drawing of the place wherew the rubber band isn't anymore.
    [self setNeedsDisplayInRect:_marqueeSelectionBounds];
    
    // Make it not there.
    _marqueeSelectionBounds = CGRectZero;
    
}


- (void)selectAndTrackMouseWithEvent:(id)event {
    
    // Are we changing the existing selection instead of setting a new one?
    BOOL modifyingExistingSelection = NO; // ([event modifierFlags] & NSShiftKeyMask) ? YES : NO;
    
    // Has the user clicked on a Gate?
    CGPoint mouseLocation = [event locationInView:self];
    NSUInteger clickedGateIndex;
    BOOL clickedGateIsSelected;
    LPPin *clickedGatePin;
    LPBlock *clickedGate = [self gateUnderPoint:mouseLocation index:&clickedGateIndex isSelected:&clickedGateIsSelected pin:&clickedGatePin];
    if (clickedGate) {
        
        // Clicking on a Gate knob takes precedence.
        if (clickedGatePin!=LPGateNoPin) {
            
            // The user clicked on a Gate's Pin. Let the user drag it around.
//            [self resizeGate:clickedGate usingPin:clickedGatePin withEvent:event];
            
        } else {
            
            // The user clicked on a Gate's contents. Update the selection.
            if (modifyingExistingSelection) {
                if (clickedGateIsSelected) {
                    
                    // Remove the Gate from the selection.
                    NSMutableIndexSet *newSelectionIndexes = [[self selectionIndexes] mutableCopy];
                    [newSelectionIndexes removeIndex:clickedGateIndex];
                    [self changeSelectionIndexes:newSelectionIndexes];
                    clickedGateIsSelected = NO;
                    
                } else {
                    
                    // Add the Gate to the selection.
                    NSMutableIndexSet *newSelectionIndexes = [[self selectionIndexes] mutableCopy];
                    [newSelectionIndexes addIndex:clickedGateIndex];
                    [self changeSelectionIndexes:newSelectionIndexes];
                    clickedGateIsSelected = YES;
                    
                }
            } else {
                
                // If the Gate wasn't selected before then it is now, and none of the rest are.
                if (!clickedGateIsSelected) {
                    [self changeSelectionIndexes:[NSIndexSet indexSetWithIndex:clickedGateIndex]];
                    clickedGateIsSelected = YES;
                }
                
            }
            
            // Is the Gate that the user has clicked on now selected?
            if (clickedGateIsSelected) {
                
                // Yes. Let the user move all of the selected objects.
                [self moveSelectedGatesWithEvent:event];
                
            } else {
                
                // No. Just swallow mouse events until the user lets go of the mouse button. We don't even bother autoscrolling here.
//                while ([event type]!=NSLeftMouseUp) {
//                    event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
//                }
                
            }
            
        }
        
    } else {
	    
        // The user clicked somewhere other than on a Gate. Clear the selection, unless the user is holding down the shift key.
        if (!modifyingExistingSelection) {
            [self changeSelectionIndexes:[NSIndexSet indexSet]];
        }
        
        // The user clicked on a point where there is no Gate. Select and deselect Gates until the user lets go of the mouse button.
        [self marqueeSelectWithEvent:event];
        
    }
    
}


// An override of the NSView method.
- (BOOL)acceptsFirstMouse:(id)event {
    
    // In general we don't want to make people click once to activate the window then again to actually do something, but we do want to help users not accidentally throw away the current selection, if there is one.
    return [[self selectionIndexes] count]>0 ? NO : YES;
    
}


// An override of the NSResponder method.
- (void)mouseDown:(id)event {
    
    // If a Gate has been being edited (in Sketch SKTTexts are the only ones that are "editable" in this sense) then end editing.
    [self stopEditing];
    
    // Is a tool other than the Selection tool selected?
//    Class GateClassToInstantiate = [[SKTToolPaletteController sharedToolPaletteController] currentGateClass];
//    if (GateClassToInstantiate) {
//        
//        // Create a new Gate and then track to size it.
//        [self createGateOfClass:GateClassToInstantiate withEvent:event];
//        
//    } else {
//        
//        // Double-clicking with the selection tool always means "start editing," or "do nothing" if no editable Gate is double-clicked on.
//        LPGateView *doubleClickedGate = nil;
//        if ([event clickCount]>1) {
//            CGPoint mouseLocation = [self convertPoint:[event locationInWindow] fromView:nil];
//            doubleClickedGate = [self GateUnderPoint:mouseLocation index:NULL isSelected:NULL Pin:NULL];
//            if (doubleClickedGate) {
//                [self startEditingGate:doubleClickedGate];
//            }
//        }
//        if (!doubleClickedGate) {
//            
//            // Update the selection and/or move Gates or resize Gates.
//            [self selectAndTrackMouseWithEvent:event];
//            
//        }
//        
//    }
    
}


#pragma mark *** Keyboard Event Handling ***


// An override of the NSResponder method. NSResponder's implementation would just forward the message to the next responder (an NSClipView, in Sketch's case) and our overrides like -delete: would never be invoked.
- (void)keyDown:(id)event {
    
    // Ask the key binding manager to interpret the event for us.
//    [self interpretKeyEvents:[NSArray arrayWithObject:event]];
    
}


- (IBAction)delete:(id)sender {
    
    // Pretty simple.
    [self.gates removeObjectsAtIndexes:[self selectionIndexes]];
    [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Delete", @"UndoStrings", @"Action name for deletions.")];
    
}


// Overrides of the NSResponder(NSStandardKeyBindingMethods) methods.
- (void)deleteBackward:(id)sender {
    [self delete:sender];
}
- (void)deleteForward:(id)sender {
    [self delete:sender];
}


- (void)invalidatePinsOfGates:(NSArray *)Gates {
    NSUInteger i, c = [Gates count];
    for (i=0; i<c; i++) {
        [self setNeedsDisplayInRect:[[Gates objectAtIndex:i] drawingBounds]];
    }
}

- (void)unhidePinsForTimer:(NSTimer *)timer {
    _isHidingPins = NO;
    _pinShowingTimer = nil;
    [self setNeedsDisplayInRect:[LPBlock drawingBoundsOfGates:[self selectedGates]]];
}

- (void)hidePinsMomentarily {
    [_pinShowingTimer invalidate];
    _pinShowingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(unhidePinsForTimer:) userInfo:nil repeats:NO];
    _isHidingPins = YES;
    [self setNeedsDisplayInRect:[LPBlock drawingBoundsOfGates:[self selectedGates]]];
}


- (void)moveSelectedGatesByX:(CGFloat)x y:(CGFloat)y {
    
    // Don't do anything if there's nothing to do.
    NSArray *selectedGates = [self selectedGates];
    if ([selectedGates count]>0) {
        
        // Don't draw and redraw the selection rectangles while the user holds an arrow key to autorepeat.
        [self hidePinsMomentarily];
        
        // Move the selected Gates.
        [[LPBlock class] translateGates:selectedGates byX:x y:y];
        
        // Overwrite whatever undo action name was registered during all of that with a more specific one.
        [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Nudge", @"UndoStrings", @"Action name for nudge keyboard commands.")];
        
        // Post appropriate accessibility notification
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self);
    }
    
}


// Overrides of the NSResponder(NSStandardKeyBindingMethods) methods.
- (void)moveLeft:(id)sender {
    [self moveSelectedGatesByX:-1.0f y:0.0f];
}
- (void)moveRight:(id)sender {
    [self moveSelectedGatesByX:1.0f y:0.0f];
}
- (void)moveUp:(id)sender {
    [self moveSelectedGatesByX:0.0f y:-1.0f];
}
- (void)moveDown:(id)sender {
    [self moveSelectedGatesByX:0.0f y:1.0f];
}


#pragma mark *** Copy and Paste ***


- (BOOL)makeNewImageFromContentsOfFile:(NSString *)filename atPoint:(CGPoint)point {
//    NSString *extension = [filename pathExtension];
//    if ([[UIImage imageFileTypes] containsObject:extension]) {
//        UIImage *contents = [[UIImage alloc] initWithContentsOfFile:filename];
//        if (contents) {
//            SKTImage *newImage = [[SKTImage alloc] initWithPosition:point contents:contents];
//            [contents release];
//            [[self mutableGates] insertObject:newImage atIndex:0];
//            [newImage release];
//            [self changeSelectionIndexes:[NSIndexSet indexSetWithIndex:0]];
//            return YES;
//        }
//    }
    return NO;
}


- (BOOL)makeNewImageFromPasteboard:(id)pboard atPoint:(CGPoint)point {
//    NSString *type = [pboard availableTypeFromArray:[UIImage imagePasteboardTypes]];
//    if (type) {
//        UIImage *contents = [[UIImage alloc] initWithPasteboard:pboard];
//        if (contents) {
//            CGPoint imageOrigin = NSMakePoint(point.x, (point.y - [contents size].height));
//            SKTImage *newImage = [[SKTImage alloc] initWithPosition:imageOrigin contents:contents];
//            [contents release];
//            [[self mutableGates] insertObject:newImage atIndex:0];
//            [newImage release];
//            [self changeSelectionIndexes:[NSIndexSet indexSetWithIndex:0]];
//            return YES;
//        }
//    }
    return NO;
}


- (IBAction)copy:(id)sender {
//    NSArray *selectedGates = [self selectedGates];
//    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
//    [pasteboard declareTypes:[NSArray arrayWithObjects:LPGateViewPasteboardType, NSPDFPboardType, NSTIFFPboardType, nil] owner:nil];
//    [pasteboard setData:[[LPGateView class] pasteboardDataWithGates:selectedGates] forType:LPGateViewPasteboardType];
//    [pasteboard setData:[[SKTRenderingView class] pdfDataWithGates:selectedGates] forType:NSPDFPboardType];
//    [pasteboard setData:[[SKTRenderingView class] tiffDataWithGates:selectedGates error:NULL] forType:NSTIFFPboardType];
//    _pasteboardChangeCount = [pasteboard changeCount];
//    _pasteCascadeNumber = 1;
//    _pasteCascadeDelta = NSMakePoint(LPGateViewDefaultPasteCascadeDelta, LPGateViewDefaultPasteCascadeDelta);
}


- (IBAction)cut:(id)sender {
    [self copy:sender];
    [self delete:sender];
    [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Cut", @"UndoStrings", @"Action name for cut.")];
}


- (IBAction)paste:(id)sender {
    
//    // We let the user paste Gates, image files, and image data.
//    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
//    NSString *typeName = [pasteboard availableTypeFromArray:[NSArray arrayWithObjects:LPGateViewPasteboardType, NSFilenamesPboardType, nil]];
//    if ([typeName isEqualToString:LPGateViewPasteboardType]) {
//        
//        // You can't trust anything that might have been put on the pasteboard by another application, so be ready for +[LPGateView GatesWithPasteboardData:error:] to fail and return nil.
//        Class GateClass = [LPGateView class];
//        NSError *error;
//        NSArray *Gates = [GateClass GatesWithPasteboardData:[pasteboard dataForType:typeName] error:&error];
//        if (Gates) {
//            
//            // Should we reset the cascading of pasted Gates?
//            NSInteger pasteboardChangeCount = [pasteboard changeCount];
//            if (_pasteboardChangeCount!=pasteboardChangeCount) {
//                _pasteboardChangeCount = pasteboardChangeCount;
//                _pasteCascadeNumber = 0;
//                _pasteCascadeDelta = NSMakePoint(LPGateViewDefaultPasteCascadeDelta, LPGateViewDefaultPasteCascadeDelta);
//            }
//            
//            // An empty array doesn't signal an error, but it's still not useful to paste it.
//            NSUInteger GateCount = [Gates count];
//            if (GateCount>0) {
//                
//                // If this is a repetitive paste, or a paste of something that was just copied from this same view, then offset the Gates by a little bit.
//                if (_pasteCascadeNumber>0) {
//                    [GateClass translateGates:Gates byX:(_pasteCascadeNumber * _pasteCascadeDelta.x) y:(_pasteCascadeNumber * _pasteCascadeDelta.y)];
//                }
//                _pasteCascadeNumber++;
//                
//                // Add the pasted Gates in front of all others and select them.
//                NSIndexSet *insertionIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, GateCount)];
//                [[self mutableGates] insertObjects:Gates atIndexes:insertionIndexes];
//                [self changeSelectionIndexes:insertionIndexes];
//                
//                // Override any undo action name that might have been set with one that is more specific to this operation.
//                [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Paste", @"UndoStrings", @"Action name for paste.")];
//                
//            }
//            
//        } else {
//            
//            // Something went wrong? Present the error to the user in a sheet. It was entirely +[LPGateView GatesWithPasteboardData:error:]'s responsibility to set the error to something when it returned nil. It was also entirely responsible for not crashing if we had passed in error:NULL.
//            [self presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:NULL contextInfo:NULL];
//            
//        }
//        
//    } else if ([typeName isEqualToString:NSFilenamesPboardType]) {
//        NSArray *filenames = [pasteboard propertyListForType:NSFilenamesPboardType];
//        if ([filenames count] == 1) {
//            NSString *filename = [filenames objectAtIndex:0];
//            if ([self makeNewImageFromContentsOfFile:filename atPoint:NSMakePoint(50, 50)]) {
//                [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Paste", @"UndoStrings", @"Action name for paste.")];
//            }
//        }
//    } else if ([self makeNewImageFromPasteboard:pasteboard atPoint:NSMakePoint(50, 50)]) {
//        [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Paste", @"UndoStrings", @"Action name for paste.")];
//    }
    
}


#pragma mark *** Drag and Drop ***

//
//- (NSUInteger)dragOperationForDraggingInfo:(id <NSDraggingInfo>)sender {
//    NSPasteboard *pboard = [sender draggingPasteboard];
//    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:UIColorPboardType, NSFilenamesPboardType, nil]];
//    
//    if (type) {
//        if ([type isEqualToString:UIColorPboardType]) {
//            CGPoint point = [self convertPoint:[sender draggingLocation] fromView:nil];
//            if ([self GateUnderPoint:point index:NULL isSelected:NULL Pin:NULL]) {
//                return NSDragOperationGeneric;
//            }
//        }
//        if ([type isEqualToString:NSFilenamesPboardType]) {
//            return NSDragOperationCopy;
//        }
//    }
//    
//    type = [pboard availableTypeFromArray:[UIImage imagePasteboardTypes]];
//    if (type) {
//        return NSDragOperationCopy;
//    }
//    
//    return NSDragOperationNone;
//}
//
//
//// Conformance to the NSObject(NSDraggingDestination) informal protocol.
//- (NSUInteger)draggingEntered:(id <NSDraggingInfo>)sender {
//    return [self dragOperationForDraggingInfo:sender];
//}
//- (NSUInteger)draggingUpdated:(id <NSDraggingInfo>)sender {
//    return [self dragOperationForDraggingInfo:sender];
//}
//- (void)draggingExited:(id <NSDraggingInfo>)sender {
//    return;
//}
//- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
//    return YES;
//}
//- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
//    return YES;
//}
//
//- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
//    NSPasteboard *pboard = [sender draggingPasteboard];
//    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:UIColorPboardType, NSFilenamesPboardType, nil]];
//    CGPoint point = [self convertPoint:[sender draggingLocation] fromView:nil];
//    CGPoint draggedImageLocation = [self convertPoint:[sender draggedImageLocation] fromView:nil];
//    
//    if (type) {
//        if ([type isEqualToString:UIColorPboardType]) {
//            LPGateView *hitGate = [self GateUnderPoint:point index:NULL isSelected:NULL Pin:NULL];
//            
//            if (hitGate) {
//                UIColor *color = [[UIColor colorFromPasteboard:pboard] colorWithAlphaComponent:1.0];
//                [hitGate setColor:color];
//            }
//        } else if ([type isEqualToString:NSFilenamesPboardType]) {
//            NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
//            // Pin multiple files (cascade them?)
//            if ([filenames count] == 1) {
//                NSString *filename = [filenames objectAtIndex:0];
//                [self makeNewImageFromContentsOfFile:filename atPoint:point];
//            }
//        }
//        return;
//    }
//    
//    (void)[self makeNewImageFromPasteboard:pboard atPoint:draggedImageLocation];
//}


#pragma mark *** Other View Customization ***


// An override of the NSResponder method.
- (BOOL)acceptsFirstResponder {
    
    // This view can of course Pin lots of action messages.
    return YES;
    
}


// An override of the NSView method.
- (BOOL)isFlipped {
    
    // Put (0, 0) at the top-left of the view.
    return YES;
    
}


// An override of the NSView method.
- (BOOL)isOpaque {
    
    // Our override of -drawRect: always draws a background.
    return YES;
    
}


//// Conformance to the NSObject(NSMenuValidation) informal protocol.
//- (BOOL)validateMenuItem:(NSMenuItem *)item {
//    SEL action = [item action];
//    
//    if (action == @selector(makeNaturalSize:)) {
//        // Return YES if we have at least one selected Gate that has a natural size.
//        NSArray *selectedGates = [self selectedGates];
//        NSUInteger i, c = [selectedGates count];
//        if (c > 0) {
//            for (i=0; i<c; i++) {
//                if ([[selectedGates objectAtIndex:i] canMakeNaturalSize]) {
//                    return YES;
//                }
//            }
//        }
//        return NO;
//    } else if ((action == @selector(alignWithGrid:)) || (action == @selector(delete:)) || (action == @selector(bringToFront:)) || (action == @selector(sendToBack:)) || (action == @selector(cut:)) || (action == @selector(copy:))) {
//        
//        // The  grid is not always in a valid state.
//        if (action==@selector(alignWithGrid:) && ![_grid canAlign]) {
//            return NO;
//        }
//        
//        // These only apply if there is a selection
//        return (([[self selectedGates] count] > 0) ? YES : NO);
//    } else if ((action == @selector(alignLeftEdges:)) || (action == @selector(alignRightEdges:)) || (action == @selector(alignTopEdges:)) || (action == @selector(alignBottomEdges:)) || (action == @selector(alignHorizontalCenters:)) || (action == @selector(alignVerticalCenters:)) || (action == @selector(makeSameWidth:)) || (action == @selector(makeSameHeight:))) {
//        // These only apply to multiple selection
//        return (([[self selectedGates] count] > 1) ? YES : NO);
//    } else if (action==@selector(undo:) || action==@selector(redo:)) {
//        
//        // Because we implement -undo: and redo: action methods we must validate the actions too. Messaging the window directly like this is not strictly correct, because there may be other responders in the chain between this view and the window (superviews maybe?) that want control over undoing and redoing, but there's no AppKit method we can invoke to simply find the next responder that responds to -undo: and -redo:.
//        return [[self window] validateMenuItem:item];
//        
//    } else if (action==@selector(showOrHideRulers:)) {
//        
//        // The Show/Hide Ruler menu item is always enabled, but we have to set its title.
//        [item setTitle:([[self enclosingScrollView] rulersVisible] ? NSLocalizedStringFromTable(@"Hide Ruler", @"LPGateView", @"A main menu item title.") : NSLocalizedStringFromTable(@"Show Ruler", @"LPGateView", @"A main menu item title."))];
//        return YES;
//        
//    }else {
//        return YES;
//    }
//}


// An action method that isn't declared in any AppKit header, despite the fact that NSWindow implements it. Because this is here we have to Pin the action in our override of -validateMenuItem:, and we do.
- (IBAction)undo:(id)sender {
    
    // Applications are supposed to update the selection during undo and redo operations. Start keeping track of which Gates are added or changed during this operation so we can select them afterward. We don't do have to do anything when Gates are removed because the bound-to array controller keeps the selection indexes consistent when that happens. (This is the one place where LPGateView assumes anything about the class of an object to which its bound, and it's not really assuming that it's bound to an array controller. It's just assuming that the bound-to object is somehow keeping the bound-to indexes property consistent with the bound-to Gates.)
    _undoSelectionIndexes = [[NSMutableIndexSet alloc] init];
    
    // Do the regular Cocoa thing. Unfortunately, before you saw this there was no easy way for you know what "the regular Cocoa thing" is, but now you know: NSWindow has -undo: and -redo: methods, and is usually the object in the responder chain that performs these actions when the user chooses the corresponding items in the Edit menu. It would be more correct to write this as [[self nextResponder] tryToPerform:_cmd with:sender], because perhaps someday this class will be reused in a situation where the superview has opinions of its own about what should be done during undoing. We message the window directly just to be consistent with what we do in our implementation of -validateMenuItem:, where we have no choice.
//    [[self window] undo:sender];
    
    // Were Gates added or changed by undoing?
    if ([_undoSelectionIndexes count]>0) {
        
        // Yes, so replace the current selection with them.
        [self changeSelectionIndexes:_undoSelectionIndexes];
        
    } // else apparently nothing happening while undoing except maybe the removal of Gates, so we leave the selection alone.
    
    // Don't leak, and don't let -observeValueForKeyPath:ofObject:change:context: message a zombie.
    _undoSelectionIndexes = nil;
    
    // We overrode this method to find out when undoing is done, instead of observing NSUndoManagerWillUndoChangeNotification and NSUndoManagerDidUndoChangeNotification, because we only want to do what we do here when the user is focused on this view, and those notifications won't tell us the focused view. In Sketch this matters when the user has more than one window open for a document, but the concept applies whenever there are multiple views of the same data. Most of the time actions taken by the user in a view shouldn't affect the selection used in other views of the same data, with the obvious exception that removed items can no longer be selected in any view.
    
}


// The same as above, but for redoing instead of undoing. It doesn't look like so much work when you leave out the comments!
- (IBAction)redo:(id)sender {
    _undoSelectionIndexes = [[NSMutableIndexSet alloc] init];
//    [[self window] redo:sender];
    if ([_undoSelectionIndexes count]>0) {
        [self changeSelectionIndexes:_undoSelectionIndexes];
    }
    _undoSelectionIndexes = nil;
}


#pragma mark *** Other Actions ***


- (IBAction)alignLeftEdges:(id)sender {
    NSArray *selection = [self selectedGates];
    NSUInteger i, c = [selection count];
    if (c > 1) {
        CGRect firstBounds = [[selection objectAtIndex:0] bounds];
        LPGateView *curGate;
        CGRect curBounds;
        for (i=1; i<c; i++) {
            curGate = [selection objectAtIndex:i];
            curBounds = [curGate bounds];
            if (curBounds.origin.x != firstBounds.origin.x) {
                curBounds.origin.x = firstBounds.origin.x;
                [curGate setBounds:curBounds];
            }
        }
        [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Align Left Edges", @"UndoStrings", @"Action name for align left edges.")];
    }
}

- (IBAction)alignRightEdges:(id)sender {
    NSArray *selection = [self selectedGates];
    NSUInteger i, c = [selection count];
    if (c > 1) {
        CGRect firstBounds = [[selection objectAtIndex:0] bounds];
        LPGateView *curGate;
        CGRect curBounds;
        for (i=1; i<c; i++) {
            curGate = [selection objectAtIndex:i];
            curBounds = [curGate bounds];
            if (CGRectGetMaxX(curBounds) != CGRectGetMaxX(firstBounds)) {
                curBounds.origin.x = CGRectGetMaxX(firstBounds) - curBounds.size.width;
                [curGate setBounds:curBounds];
            }
        }
        [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Align Right Edges", @"UndoStrings", @"Action name for align right edges.")];
    }
}

- (IBAction)alignTopEdges:(id)sender {
    NSArray *selection = [self selectedGates];
    NSUInteger i, c = [selection count];
    if (c > 1) {
        CGRect firstBounds = [[selection objectAtIndex:0] bounds];
        LPGateView *curGate;
        CGRect curBounds;
        for (i=1; i<c; i++) {
            curGate = [selection objectAtIndex:i];
            curBounds = [curGate bounds];
            if (curBounds.origin.y != firstBounds.origin.y) {
                curBounds.origin.y = firstBounds.origin.y;
                [curGate setBounds:curBounds];
            }
        }
        [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Align Top Edges", @"UndoStrings", @"Action name for align top edges.")];
    }
}

- (IBAction)alignBottomEdges:(id)sender {
    NSArray *selection = [self selectedGates];
    NSUInteger i, c = [selection count];
    if (c > 1) {
        CGRect firstBounds = [[selection objectAtIndex:0] bounds];
        LPGateView *curGate;
        CGRect curBounds;
        for (i=1; i<c; i++) {
            curGate = [selection objectAtIndex:i];
            curBounds = [curGate bounds];
            if (CGRectGetMaxY(curBounds) != CGRectGetMaxY(firstBounds)) {
                curBounds.origin.y = CGRectGetMaxY(firstBounds) - curBounds.size.height;
                [curGate setBounds:curBounds];
            }
        }
        [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Align Bottom Edges", @"UndoStrings", @"Action name for align bottom edges.")];
    }
}

- (IBAction)alignHorizontalCenters:(id)sender {
    NSArray *selection = [self selectedGates];
    NSUInteger i, c = [selection count];
    if (c > 1) {
        CGRect firstBounds = [[selection objectAtIndex:0] bounds];
        LPGateView *curGate;
        CGRect curBounds;
        for (i=1; i<c; i++) {
            curGate = [selection objectAtIndex:i];
            curBounds = [curGate bounds];
            if (CGRectGetMidX(curBounds) != CGRectGetMidX(firstBounds)) {
                curBounds.origin.x = CGRectGetMidX(firstBounds) - (curBounds.size.width / 2.0);
                [curGate setBounds:curBounds];
            }
        }
        [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Align Horizontal Centers", @"UndoStrings", @"Action name for align horizontal centers.")];
    }
}

- (IBAction)alignVerticalCenters:(id)sender {
    NSArray *selection = [self selectedGates];
    NSUInteger i, c = [selection count];
    if (c > 1) {
        CGRect firstBounds = [[selection objectAtIndex:0] bounds];
        LPBlock *curGate;
        CGRect curBounds;
        for (i=1; i<c; i++) {
            curGate = [selection objectAtIndex:i];
            curBounds = [curGate bounds];
            if (CGRectGetMidY(curBounds) != CGRectGetMidY(firstBounds)) {
                curBounds.origin.y = CGRectGetMidY(firstBounds) - (curBounds.size.height / 2.0);
                [curGate setBounds:curBounds];
            }
        }
        [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Align Vertical Centers", @"UndoStrings", @"Action name for align vertical centers.")];
    }
}


- (IBAction)alignWithGrid:(id)sender {
    NSArray *selection = [self selectedGates];
    NSUInteger i, c = [selection count];
    if (c > 0) {
        LPBlock *curGate;
        
        for (i=0; i<c; i++) {
            curGate = [selection objectAtIndex:i];
            [curGate setBounds:[_grid alignedRect:[curGate bounds]]];
        }
        [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Grid Selected Gates", @"UndoStrings", @"Action name for grid selected Gates.")];
    }
}

- (IBAction)bringToFront:(id)sender {
    NSArray *selectedObjects = [[self selectedGates] copy];
    NSIndexSet *selectionIndexes = [self selectionIndexes];
    if ([selectionIndexes count]>0) {
//        NSMutableArray *mutableGates = [self mutableGates];
        [self.gates removeObjectsAtIndexes:selectionIndexes];
        NSIndexSet *insertionIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [selectedObjects count])];
        [self.gates insertObjects:selectedObjects atIndexes:insertionIndexes];
        [self changeSelectionIndexes:insertionIndexes];
        [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Bring To Front", @"UndoStrings", @"Action name for bring to front.")];
    }
}


- (IBAction)sendToBack:(id)sender {
    NSArray *selectedObjects = [[self selectedGates] copy];
    NSIndexSet *selectionIndexes = [self selectionIndexes];
    if ([selectionIndexes count]>0) {
//        NSMutableArray *mutableGates = [self mutableGates];
        [self.gates removeObjectsAtIndexes:selectionIndexes];
        NSIndexSet *insertionIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([self.gates count], [selectedObjects count])];
        [self.gates insertObjects:selectedObjects atIndexes:insertionIndexes];
        [self changeSelectionIndexes:insertionIndexes];
        [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Send To Back", @"UndoStrings", @"Action name for send to back.")];
    }
}


// Conformance to the NSObject(UIColorPanelResponderMethod) informal protocol.
- (void)changeColor:(id)sender {
    
    // Change the color of every selected Gate.
    [[self selectedGates] makeObjectsPerformSelector:@selector(setColor:) withObject:[sender color]];
    
}


- (IBAction)makeSameWidth:(id)sender {
    NSArray *selection = [self selectedGates];
    NSUInteger i, c = [selection count];
    if (c > 1) {
        CGRect firstBounds = [[selection objectAtIndex:0] bounds];
        LPGateView *curGate;
        CGRect curBounds;
        for (i=1; i<c; i++) {
            curGate = [selection objectAtIndex:i];
            curBounds = [curGate bounds];
            if (curBounds.size.width != firstBounds.size.width) {
                curBounds.size.width = firstBounds.size.width;
                [curGate setBounds:curBounds];
            }
        }
        [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Make Same Width", @"UndoStrings", @"Action name for make same width.")];
    }
}

- (IBAction)makeSameHeight:(id)sender {
    NSArray *selection = [self selectedGates];
    NSUInteger i, c = [selection count];
    if (c > 1) {
        CGRect firstBounds = [[selection objectAtIndex:0] bounds];
        LPGateView *curGate;
        CGRect curBounds;
        for (i=1; i<c; i++) {
            curGate = [selection objectAtIndex:i];
            curBounds = [curGate bounds];
            if (curBounds.size.height != firstBounds.size.height) {
                curBounds.size.height = firstBounds.size.height;
                [curGate setBounds:curBounds];
            }
        }
        [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Make Same Width", @"UndoStrings", @"Action name for make same width.")];
    }
}

- (IBAction)makeNaturalSize:(id)sender {
    NSArray *selection = [self selectedGates];
    if ([selection count] > 0) {
        [selection makeObjectsPerformSelector:@selector(makeNaturalSize)];
        [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Make Natural Size", @"UndoStrings", @"Action name for natural size.")];
    }
}


// An override of an NSResponder(NSStandardKeyBindingMethods) method and a matching method of our own.
- (void)selectAll:(id)sender {
    [self changeSelectionIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[self gates] count])]];
}
- (IBAction)deselectAll:(id)sender {
    [self changeSelectionIndexes:[NSIndexSet indexSet]];
}


// See the comment in the header about why we're not using -toggleRuler:.
- (IBAction)showOrHideRulers:(id)sender {
    
    // Simple.
//    UIScrollView *enclosingScrollView = [self enclosingScrollView];
//    [enclosingScrollView setRulersVisible:![enclosingScrollView rulersVisible]];
    
}

- (void)insertGateWithClass:(Class)class andEvent:(UIGestureRecognizer *)gesture {
    if (class) {
        [self createGateOfClass:class withEvent:gesture];
    }
}

- (IBAction)insertGate:(id)sender {
    
    Class GateClass = nil;
    switch ([sender tag])
    {
//            LPOrGate = 0,
//            LPNorGate,
//            LPAndGate,
//            LPNandGate,
//            LPXOrGate,
//            LPXNorGate,
//            LPBufferGate,
//            LPInverterGate,
//            LPLine
//        case LPOrGate:
//            GateClass = [SKTRectangle class];
//            break;
//        case SKTCircleToolRow:
//            GateClass = [SKTCircle class];
//            break;
//        case SKTLineToolRow:
//            GateClass = [SKTLine class];
//            break;
//        case SKTTextToolRow:
//            GateClass = [SKTText class];
//            break;
        default:
            break;
    };
    
    if (GateClass) {
        [self createGateOfClass:GateClass withEvent:nil];
//        [[LPToolPaletteController sharedToolPaletteController] selectArrowTool];
    }
}

#define NICE_SIZE  (0.25)

//- (void)setScale:(CGFloat)scale {
//    // redraw when the scale changes
//    if (scale != _scale) {
//        _scale = scale * NICE_SIZE;      // scale by 0.25 so 1.0 give a nice size
//        [self setNeedsDisplay];
//    }
//}
//
//- (CGFloat)scale {
//    if (!_scale) _scale = NICE_SIZE;
//    return _scale;
//}

//- (id)initWithFrame:(CGRect)frame {
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code
//    }
//    return self;
//}
//
//- (void)drawBufferInContext:(CGContextRef)context atPoint:(CGPoint)point withScale:(CGFloat)scale {
//    CGContextMoveToPoint(context, point.x, point.y);
//    CGContextAddLineToPoint(context, point.x,             point.y+180.0*scale);
//    CGContextAddLineToPoint(context, point.x+132.5*scale, point.y+90.0*scale);
//    CGContextAddLineToPoint(context, point.x-5.0*scale,   point.y-5.0*scale);
//    CGContextDrawPath(context, kCGPathStroke);
//}
//
//- (void)drawAndInContext:(CGContextRef)context atPoint:(CGPoint)point withScale:(CGFloat)scale {
//    CGContextMoveToPoint(context,     point.x,             point.y);
//    CGContextAddCurveToPoint(context, point.x,             point.y,             point.x,             point.y+216.0*scale, point.x,             point.y+216.0*scale);
//    CGContextAddCurveToPoint(context, point.x,             point.y+216.0*scale, point.x+173.0*scale, point.y+217.0*scale, point.x+173.0*scale, point.y+217.0*scale);
//    CGContextAddCurveToPoint(context, point.x+231.0*scale, point.y+217.0*scale, point.x+277.0*scale, point.y+156.0*scale, point.x+275.0*scale, point.y+106.0*scale);
//    CGContextAddCurveToPoint(context, point.x+271.0*scale, point.y+83.75*scale, point.x+249.0*scale, point.y+11.0*scale,  point.x+174.0*scale, point.y);
//    CGContextAddCurveToPoint(context, point.x+174.0*scale, point.y,             point.x-7.0*scale,   point.y,             point.x-7.0*scale,   point.y);
//    CGContextDrawPath(context, kCGPathStroke);
//}
//
//- (void)drawOrInContext:(CGContextRef)context atPoint:(CGPoint)point withScale:(CGFloat)scale {
//    CGContextMoveToPoint(context,     point.x,             point.y);
//    CGContextAddCurveToPoint(context, point.x+15.5*scale,  point.y+24.5*scale,  point.x+34.0*scale,  point.y+73.5*scale,  point.x+31.0*scale,  point.y+112.0*scale);
//    CGContextAddCurveToPoint(context, point.x+38.0*scale,  point.y+145.5*scale, point.x+11.0*scale,  point.y+205.5*scale, point.x+1.0*scale,   point.y+218.0*scale);
//    CGContextAddCurveToPoint(context, point.x+0.5*scale,   point.y+221.1*scale, point.x+141.1*scale, point.y+220.3*scale, point.x+142.0*scale, point.y+215.0*scale);
//    CGContextAddCurveToPoint(context, point.x+218.0*scale, point.y+214.0*scale, point.x+301.0*scale, point.y+135.5*scale, point.x+303.0*scale, point.y+111.0*scale);
//    CGContextAddCurveToPoint(context, point.x+284.5*scale, point.y+69.5*scale,  point.x+214.0*scale, point.y+14.5*scale,  point.x+141.0*scale, point.y+4.0*scale);
//    CGContextAddCurveToPoint(context, point.x+141.0*scale, point.y,             point.x-5.0*scale,   point.y,             point.x-5.0*scale,   point.y);
//    CGContextDrawPath(context, kCGPathStroke);
//}
//
//- (void)drawShieldInContext:(CGContextRef)context atPoint:(CGPoint)point withScale:(CGFloat)scale {
//    CGContextMoveToPoint(context,     point.x,             point.y);
//    CGContextAddCurveToPoint(context, point.x+15.5*scale,  point.y+24.5*scale,  point.x+34.0*scale,  point.y+73.5*scale,  point.x+31.0*scale,  point.y+112.0*scale);
//    CGContextAddCurveToPoint(context, point.x+38.0*scale,  point.y+145.5*scale, point.x+11.0*scale,  point.y+205.5*scale, point.x+1.0*scale,   point.y+218.0*scale);
//    CGContextDrawPath(context, kCGPathStroke);
//}
//
//- (void)drawXorInContext:(CGContextRef)context atPoint:(CGPoint)point withScale:(CGFloat)scale {
//    [self drawOrInContext:context atPoint:point withScale:scale];
//    [self drawShieldInContext:context atPoint:CGPointMake(point.x-50.0*scale, point.y) withScale:scale];
//}
//
//- (void)drawXNorInContext:(CGContextRef)context atPoint:(CGPoint)point withScale:(CGFloat)scale {
//    [self drawNorInContext:context atPoint:point withScale:scale];
//    [self drawShieldInContext:context atPoint:CGPointMake(point.x-50.0*scale, point.y) withScale:scale];    
//}
//
//- (void)drawNotInContext:(CGContextRef)context atPoint:(CGPoint)point withScale:(CGFloat)scale {
//    CGContextAddEllipseInRect(context, CGRectMake(point.x, point.y, 50*scale, 50*scale));
//    CGContextDrawPath(context, kCGPathStroke);
//}
//
//- (void)drawNorInContext:(CGContextRef)context atPoint:(CGPoint)point withScale:(CGFloat)scale {
//    [self drawOrInContext:context atPoint:point withScale:scale];
//    [self drawNotInContext:context atPoint:CGPointMake(point.x+303.0*scale, point.y+86.0*scale) withScale:scale];
//}
//
//- (void)drawNandInContext:(CGContextRef)context atPoint:(CGPoint)point withScale:(CGFloat)scale {
//    [self drawAndInContext:context atPoint:point withScale:scale];
//    [self drawNotInContext:context atPoint:CGPointMake(point.x+275.0*scale, point.y+81.0*scale) withScale:scale];
//}
//
//- (void)drawInverterInContext:(CGContextRef)context atPoint:(CGPoint)point withScale:(CGFloat)scale {
//    [self drawBufferInContext:context atPoint:point withScale:scale];
//    [self drawNotInContext:context atPoint:CGPointMake(point.x+135.0*scale, point.y+65.0*scale) withScale:scale];
//}

//- (void)drawShape:(LPGateView *)gate inContext:(CGContextRef)context withScale:(CGFloat)scale {
//    switch (gate.gate) {
//        case OR_GATE:       [self drawOrInContext:context atPoint:gate.location withScale:scale]; break;
//        case NOR_GATE:      [self drawNorInContext:context atPoint:gate.location withScale:scale]; break;
//        case AND_GATE:      [self drawAndInContext:context atPoint:gate.location withScale:scale]; break;
//        case NAND_GATE:     [self drawNandInContext:context atPoint:gate.location withScale:scale]; break;
//        case XOR_GATE:      [self drawXorInContext:context atPoint:gate.location withScale:scale]; break;
//        case XNOR_GATE:     [self drawXNorInContext:context atPoint:gate.location withScale:scale]; break;
//        case BUFFER_GATE:   [self drawBufferInContext:context atPoint:gate.location withScale:scale]; break;
//        case INVERTER_GATE: [self drawInverterInContext:context atPoint:gate.location withScale:scale]; break;
//        default: break;
//    }
//}

//- (void)drawRect:(CGRect)rect {
//    // Drawing code
//    CGContextRef context = UIGatesGetCurrentContext();
//    NSLog(@"Scale = %f", self.scale);
//    CGContextSetLineWidth(context, MAX(1,12*self.scale));
//    for (LPGateView *gate in self.gates.list) {
//        if (gate.selected) {
//            CGContextSaveGState(context);
//            CGContextSetRGBStrokeColor(context, 1, 0, 0, 1);
//            [self drawShape:gate inContext:context withScale:self.scale];
//            CGContextRestoreGState(context);
//        } else {
//            [self drawShape:gate inContext:context withScale:self.scale];
//        }
//    }
//}

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
