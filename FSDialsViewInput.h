//
//  FSDialsViewInput.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 4.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>
#import "FSDialsView.h"
#import "FSCalItemRepresentation.h"
#import "FSItemInfoEditPanel.h"
#import "FSDialsViewController.h"
#import "FSAppController.h"

@interface FSDialsViewInput : FSDialsView {
	
	// properties bound to preferences
	int eventSingleClickBehavior;
	int eventDoubleClickBehavior;
	
	// user input tracking
	NSEvent* mouseDownEvent;
	NSPoint cursorInView;
	int contentUnderCursor;
	
	// highlights and selections
	NSMutableArray* highlight;
	NSMutableArray* selection;
	
	// mouse over highlights
	NSBezierPath* navButtonForwardHighlight;
	NSBezierPath* navButtonBackwardHighlight;
	NSBezierPath* earlyDialHighlight;
	NSBezierPath* lateDialHighlight;
	
	NSColor* dialHighlightColor;
	
	// contextual menus
	IBOutlet NSMenu* taskMenu;
	IBOutlet NSMenu* eventMenu;
	IBOutlet NSMenu* dayEventMenu;
	IBOutlet NSMenu* defaultMenu;
	IBOutlet NSMenu* fwdNavMenu;
	IBOutlet NSMenu* bwrdNavMenu;
}

@property int eventSingleClickBehavior;
@property int eventDoubleClickBehavior;

// an indicator of where the mouse is
enum{
	FSNormalEvent,
	FSDayEvent,
	FSTask,
	FSEmptyEventArea,
	FSEarlyDialInnerCircle,
	FSLateDialInnerCircle,
	FSBackwardNavButton,
	FSForwardNavButton,
	FSBackground,
	FSUndefined
};

// responose
-(void)respondToLeftMouseDown:(NSEvent*)event;
-(void)respondToRightMouseDown:(NSEvent*)event;
-(void)updateSelectionForEvent:(NSEvent*)event;
-(void)showContextualMenuForEvent:(NSEvent*)event;
-(void)updateContentUnderCursorFlag:(NSEvent*)event;

// highligh / selection stuff
-(void)updateHighlightedItemsGeometry;
-(void)updateSelectedItemsGeometry;
-(void)updateDialHighlightGeometry;
-(NSArray*)repsUnderCursor;
-(NSSet*)repsForItems:(NSArray*)items;
-(FSCalItemRepresentation*)highlightRepFor:(FSCalItemRepresentation*)itemRep;
-(FSCalItemRepresentation*)selectionRepFor:(FSCalItemRepresentation*)itemRep;
-(void)drawHighlighAndSelection;

// actions
-(IBAction)newEvent:(id)sender;
-(IBAction)newDayEvent:(id)sender;
-(IBAction)newTask:(id)sender;
-(IBAction)pasteHere:(id)sender;

@end
