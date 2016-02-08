//
//  FSDialsViewInput.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 4.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSDialsViewInput.h"
#import "FSHUDTooltipController.h"
#import "FSCalItemAdditions.h"

@implementation FSDialsViewInput

#pragma mark -
#pragma mark Class initialization

static NSColor* taskDayevHighlightStrokeColor = nil;
static NSColor* taskDayevHighlightFillColor = nil;
static NSColor* taskDayevSelectionFillColor = nil;
static NSColor* normalEventHighlightStrokeColor = nil;
static NSColor* normalEventHighlightFillColor = nil;
static NSColor* normalEventSelectionStrokeColor = nil;
static NSColor* normalEventSelectionFillColor = nil;

+ (void)initialize
{
    if (self == [FSDialsViewInput class]){
		
		// initialize task-dayev highlight / selection colors
//		taskDayevHighlightStrokeColor = [[NSColor colorWithDeviceWhite:1.0 alpha:0.0] retain];
//		taskDayevHighlightFillColor = [[NSColor colorWithDeviceWhite:1.0 alpha:1.0] retain];
//		taskDayevSelectionStrokeColor = [[NSColor colorWithDeviceWhite:0.0 alpha:0.75] retain];
		taskDayevSelectionFillColor = [[NSColor colorWithDeviceWhite:1.0 alpha:1.0] retain];
		
		// initialize normal event highlight / selection colors
		normalEventHighlightStrokeColor = [[NSColor colorWithDeviceWhite:1.0 alpha:0.0] retain];
		normalEventHighlightFillColor = [[NSColor colorWithDeviceWhite:1.0 alpha:0.4] retain];
		normalEventSelectionStrokeColor = [[NSColor colorWithDeviceWhite:0.0 alpha:0.75] retain];
		normalEventSelectionFillColor = [[NSColor colorWithDeviceWhite:1.0 alpha:0.75] retain];
	}
}

#pragma mark -
#pragma mark Custom init

@synthesize eventSingleClickBehavior;
@synthesize eventDoubleClickBehavior;

-(void)customInit
{
	[super customInit];
	
	highlight = [NSMutableArray new];
	selection = [NSMutableArray new];
	
	dialHighlightColor = [[NSColor colorWithCalibratedWhite:0.0 alpha:0.25] retain];
	
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[self bind:@"eventSingleClickBehavior" toObject:ud withKeyPath:FSEventSingleClickBehavior options:nil];
	[self bind:@"eventDoubleClickBehavior" toObject:ud withKeyPath:FSEventDoubleClickBehavior options:nil];
}

#pragma mark -
#pragma mark Event response stuff

-(void)updateTrackingAreas
{
	for(NSTrackingArea* ta in [self trackingAreas])
		[self removeTrackingArea:ta];
	
	NSTrackingArea* trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] 
																options:NSTrackingMouseMoved | 
									NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways 
																  owner:self 
															   userInfo:nil];
	[self addTrackingArea:trackingArea];
	[trackingArea release];
}

-(BOOL)acceptsFirstMouse:(NSEvent*)theEvent{
	return YES;
}

-(void)mouseMoved:(NSEvent*)event
{
	int mouseUnderFlagBefore = contentUnderCursor;
	
	[self updateContentUnderCursorFlag:event];
	
	// if the content under cursor changed, we need to redraw
	if(contentUnderCursor != mouseUnderFlagBefore)
		[self setNeedsDisplay:YES];
	[FSHUDTooltipController updateOrigin];
}

-(void)mouseEntered:(NSEvent*)event
{
	// if mouse is down when this happens it means we are
	// dragging, that means, ignore this
	if(mouseDownEvent != nil) return;
	
	int mouseUnderFlagBefore = contentUnderCursor;
	
	[self updateContentUnderCursorFlag:event];
	
	// if the content under cursor changed, we need to redraw
	if(contentUnderCursor != mouseUnderFlagBefore)
		[self setNeedsDisplay:YES];
	[FSHUDTooltipController updateOrigin];
}

-(void)mouseExited:(NSEvent*)event
{
	// if mouse is down when this happens it means we are
	// dragging, that means, ignore this
	if(mouseDownEvent != nil) return;
	
	int mouseUnderFlagBefore = contentUnderCursor;
	
	[self updateContentUnderCursorFlag:event];
	
	// if the content under cursor changed, we need to redraw
	if(contentUnderCursor != mouseUnderFlagBefore)
		[self setNeedsDisplay:YES];
	[FSHUDTooltipController updateOrigin];
}

-(void)mouseDown:(NSEvent*)event
{
	[mouseDownEvent release];
	mouseDownEvent = [event retain];
	
	// Ctrl+click is interpreted as right click
	if(([event modifierFlags] & NSControlKeyMask) != 0)
		[self respondToRightMouseDown:event];
		
		// standard left click
	else
		[self respondToLeftMouseDown:event];
}

-(void)mouseUp:(NSEvent*)event
{
	[mouseDownEvent release];
	mouseDownEvent = nil;
}

-(void)rightMouseDown:(NSEvent*)event
{
	[mouseDownEvent release];
	mouseDownEvent = [event retain];
	
	[self respondToRightMouseDown:event];
}

-(void)mouseDragged:(NSEvent*)event
{
	// if we are over background, move the window
	if(contentUnderCursor == FSBackground && [event buttonNumber] == 0){
		
		NSWindow* window = [self window];
		NSPoint mouseDownInScreen = [window convertBaseToScreen:[mouseDownEvent locationInWindow]];
		NSPoint currentEventInSecreen = [window convertBaseToScreen:[event locationInWindow]];
		
		// reposition the window
		NSPoint origin = [window frame].origin;
		origin.x += currentEventInSecreen.x - mouseDownInScreen.x;
		origin.y += currentEventInSecreen.y - mouseDownInScreen.y;
		[window setFrameOrigin:origin];
	}
}


-(void)scrollWheel:(NSEvent*)theEvent
{
	NSUInteger modifierFlags = [theEvent modifierFlags];
	
	if(modifierFlags & NSAlternateKeyMask){
		
		// alt is pressed, do a resize
		
		// we are only interested in the Y
		CGFloat deltaY = [theEvent deltaY];
		if(fabs(deltaY) < 0.0001f) return;
		
		// update the size proportion
		FSMainWindow* mainWindow = (FSMainWindow*)[self window];
		float newSizeProportion = [mainWindow sizeProportion];
		newSizeProportion += deltaY / 500;
		if(newSizeProportion < 1.0) newSizeProportion = 1.0;
		if(newSizeProportion > 2.0) newSizeProportion = 2.0;
		
		NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
		[ud setValue:[NSNumber numberWithFloat:newSizeProportion] forKey:FSWhenSizePreference];
		
	}else{
		
		// no relevant modifier key, scroll through days
		
		// interpret the event based on the flow direction
		NSInteger relevantScrollChange = 0;
		if(flowDirection == FSDialFlowDownward || flowDirection == FSDialFlowUpward){
			// we have a vertically oriented flow
			relevantScrollChange = (NSInteger)[theEvent deltaY];
		}else
			relevantScrollChange = (NSInteger)[theEvent deltaX];
		
		if(abs(relevantScrollChange) < 1) return;
		if(relevantScrollChange < 0)
			[[FSAppController controller] incrementOffset:self];
		else
			[[FSAppController controller] decrementOffset:self];
	}
}

-(void)updateSelectionForEvent:(NSEvent*)event
{
	[FSDialsViewController setSelectionCalItems:[FSDialsViewController highlightCalItems]];
}

-(void)respondToLeftMouseDown:(NSEvent*)event
{
	// navigation gets performed regardless of the click count
	if(contentUnderCursor == FSForwardNavButton){
		[[FSAppController controller] incrementOffset:self];
		return;
	}else if(contentUnderCursor == FSBackwardNavButton){
		[[FSAppController controller] decrementOffset:self];
		return;
	}
	
	// single click
	if([event clickCount] == 1){
		
		[self updateContentUnderCursorFlag:event];
		[self updateSelectionForEvent:event];
		
		// depending on the user preference, show info or edit or nothing
		if(eventSingleClickBehavior == FSOnClickEdit)
			[FSAppController editSelectedItem];
		else if(eventSingleClickBehavior == FSOnClickShowInfo)
			[FSAppController showSelectedItemInfo];
	}
	
	// double click
	else if([event clickCount] == 2){
		
		// diferent behavior depending on where the cursor's at
		switch(contentUnderCursor){
			
			case FSNormalEvent: case FSDayEvent: case FSTask:
				// depending on the user preference, show info or edit or nothing
				if(eventDoubleClickBehavior == FSOnClickEdit)
					[FSAppController editSelectedItem];
				else if(eventDoubleClickBehavior == FSOnClickShowInfo)
					[FSAppController showSelectedItemInfo];
				break;
			
			case FSEmptyEventArea:
				[self newEvent:self];
				break;
			
			case FSEarlyDialInnerCircle:
				if(taskDisplayStyle == FSDisplayInEarlyDial)
					[self newTask:self];
				else if(dayEventDisplayStyle == FSDisplayInEarlyDial)
					[self newDayEvent:self];
				break;
			
			case FSLateDialInnerCircle :
				if(taskDisplayStyle == FSDisplayInLateDial)
					[self newTask:self];
				else if(dayEventDisplayStyle == FSDisplayInLateDial)
					[self newDayEvent:self];
				break;
		}
	}
}

-(void)respondToRightMouseDown:(NSEvent*)event
{
	// we will want to reset the selection once the event is processed
	NSArray* oldSelection = [[[FSDialsViewController selectionCalItems] retain] autorelease];
	
	[self updateSelectionForEvent:event];
	
	// show the menu, which will result in some processing
	[self showContextualMenuForEvent:event];
	
	// restore the selection, but only if it is an empty one
	// and if the info panel is not open
	if(![[FSItemInfoEditPanel sharedPanel] isVisible] && [oldSelection count] == 0)
		[FSDialsViewController setSelectionCalItems:oldSelection];
}

-(void)showContextualMenuForEvent:(NSEvent*)event
{
	NSMenu* menuToShow;
	
	if(contentUnderCursor == FSNormalEvent)
		menuToShow = eventMenu;
	else if(contentUnderCursor == FSDayEvent)
		menuToShow = dayEventMenu;
	else if(contentUnderCursor == FSTask)
		menuToShow = taskMenu;
	else if(contentUnderCursor == FSForwardNavButton)
		menuToShow = fwdNavMenu;
	else if(contentUnderCursor == FSBackwardNavButton)
		menuToShow = bwrdNavMenu;
	else
		menuToShow = defaultMenu;
	
	// hide the info if there
	[FSHUDTooltipController orderOut];
	[NSMenu popUpContextMenu:menuToShow withEvent:event forView:self];
}

-(void)updateContentUnderCursorFlag:(NSEvent*)event
{
	// reset the content under cursor flag
	contentUnderCursor = FSUndefined;
	
	// translate the cursor coordinates
	NSPoint inView = [self convertPoint:[event locationInWindow] fromView:nil];
	cursorInView = [transformInverted transformPoint:inView];
	
	// is the cursor over one of the nav buttons?
	if([navButtonForwardBackground containsPoint:cursorInView]){
		contentUnderCursor = [FSDialsViewController highestOffset] == offset ? FSForwardNavButton : FSBackground;
		return;
	}else if([navButtonBackwardBackground containsPoint:cursorInView]){
		contentUnderCursor = [FSDialsViewController lowestOffset] == offset ? FSBackwardNavButton : FSBackground;
		return;
	}
	
	// is there an event under the cursor?
	NSArray* repsUnderCursor = [self repsUnderCursor];
	NSArray* calItemsUnderCursor = [FSCalItemRepresentation flattenedItemsInRepArray:repsUnderCursor];
	
	// set the highlight to the content under the cursor
	[FSDialsViewController setHighlightCalItems:calItemsUnderCursor];
	
	// if there are calItems under cursor
	// update the content under cursor flag accordingly
	if([calItemsUnderCursor count] != 0){
		
		CalCalendarItem* item = [calItemsUnderCursor objectAtIndex:0];
		if([item isKindOfClass:[CalEvent class]]){
			contentUnderCursor = ((CalEvent*)item).isAllDay ? FSDayEvent : FSNormalEvent;
		}else
			contentUnderCursor = FSTask;
		
		// nothing more to do here
		return;
	}
	
	// figure out where the line between the event area and the inner circles is
	float innerRadius = TASK_DAYEV_POSITION_RADIUS;
	if(dayEventDisplayStyle != FSDoNotDisplay || taskDisplayStyle != FSDoNotDisplay)
		innerRadius += (TASK_DAYEV_CLEARANCE + TASK_DAYEV_RENDER_RADIUS);
	else
		innerRadius -= (TASK_DAYEV_CLEARANCE + TASK_DAYEV_RENDER_RADIUS);
	
	// there are no items under the cursor, we need to resort to background geometry
	// to figure it out
	if([dial1Background containsPoint:cursorInView]){
		
		// content under cursor depends on the cursor being in or out of the inner circle
		BOOL inInnerCircle = innerRadius > 
		[FSWhenGeometry distanceOfPoint:cursorInView 
							  fromPoint:[FSWhenGeometry dialCenter:earlyDialPosition]];
		if(inInnerCircle)
			contentUnderCursor = FSEarlyDialInnerCircle;
		else
			contentUnderCursor = FSEmptyEventArea;
		
	}else if([dial2Background containsPoint:cursorInView]){
		
		// content under cursor depends on the cursor being in or out of the inner circle
		BOOL inInnerCircle = innerRadius > 
		[FSWhenGeometry distanceOfPoint:cursorInView 
							  fromPoint:[FSWhenGeometry dialCenter:[self lateDialPosition]]];
		if(inInnerCircle)
			contentUnderCursor = FSLateDialInnerCircle;
		else
			contentUnderCursor = FSEmptyEventArea;
		
	}else if([background containsPoint:cursorInView]){
		contentUnderCursor = FSBackground;
	}
}

-(void)menuNeedsUpdate:(NSMenu*)menu
{
	NSString* selectedItemTitle;
	NSArray* selectedItems = [FSDialsViewController selectionCalItems];
	switch([selectedItems count]){
		case 0 : selectedItemTitle = @"No selection";
			break;
		case 1: {
			CalCalendarItem* calItem = [selectedItems objectAtIndex:0];
			if([calItem isKindOfClass:[CalEvent class]])
				selectedItemTitle = [NSString stringWithFormat:@"Event: %@", calItem.title];
			else
				selectedItemTitle = [NSString stringWithFormat:@"Task: %@", calItem.title];
			break;
		}
		default :
			selectedItemTitle = @"Multiple items";
	}
	
	if(menu == dayEventMenu){
		[[menu itemAtIndex:0] setTitle:selectedItemTitle];
	}else if(menu == eventMenu){
		[[menu itemAtIndex:0] setTitle:selectedItemTitle];
	}else if(menu == taskMenu){
		[[menu itemAtIndex:0] setTitle:selectedItemTitle];
	}
}

#pragma mark -
#pragma mark Item highlight / selection stuff

-(void)updateHighlightedItemsGeometry
{
	NSArray* highlightItems = [FSDialsViewController highlightCalItems];
	NSArray* selectionItems = [FSDialsViewController selectionCalItems];
	
	// clear the highlighted items
	[highlight removeAllObjects];
	
	// if the items we need to highlight are selected,
	// then we do not do highlighting
	if([selectionItems isEqualToArray:highlightItems])
		return;
	
	// otherwise, do the highlighting!
	for(FSCalItemRepresentation* itemRep in [self repsForItems:highlightItems])
		[highlight addObject:[self highlightRepFor:itemRep]];
}

-(void)updateSelectedItemsGeometry
{
	NSArray* selectionItems = [FSDialsViewController selectionCalItems];
	
	// assign path
	[selection removeAllObjects];
	
	// otherwise, do the highlighting!
	for(FSCalItemRepresentation* itemRep in [self repsForItems:selectionItems])
		[selection addObject:[self selectionRepFor:itemRep]];
}

-(NSArray*)repsUnderCursor
{
	NSMutableArray* repsUnder = [[NSMutableArray new] autorelease];
	
	// go through reps
	// tasks
	for(FSCalItemRepresentation* rep in tasks)
		if([rep.path containsPoint:cursorInView])
			[repsUnder addObject:rep];
	
	// if there is a task under, we can't have anything else
	if([repsUnder count] == 0)
		for(FSCalItemRepresentation* rep in dayEvents)
			if([rep.path containsPoint:cursorInView])
				[repsUnder addObject:rep];
	
	// if there is a task or dayev under, we can't have anything else
	if([repsUnder count] == 0)
		for(FSCalItemRepresentation* rep in events)
			if([rep.path containsPoint:cursorInView])
				[repsUnder addObject:rep];
	
	return repsUnder;
}

-(NSSet*)repsForItems:(NSArray*)items
{
	if([items count] == 0)
		return nil;
	
	// all the reps we have found till now
	NSMutableSet* matchingReps = [[NSMutableSet new] autorelease];
	
	for(int i = 0 ; i <= 2 && [matchingReps count] == 0 ; i ++){
		
		NSArray* reps;
		switch(i) {
			case 0:
				reps = tasks;
				break;
			case 1:
				reps = dayEvents;
				break;
			case 2:
				reps = events;
				break;
			case 3:
				[NSException raise:@"Index out of range" format:@"This should not happen"];
				break;
		}
		
		for(FSCalItemRepresentation* rep in reps){
			
			for(CalCalendarItem* itemToFind in items){
				
				// collapsed cal reps
				if([rep.item isKindOfClass:[NSArray class]]){
					for(CalCalendarItem* item in ((NSArray*)rep.item))
						if([item.uid isEqualToString:itemToFind.uid])
							[matchingReps addObject:rep];
					
					// normal cal reps
				}else if([((CalCalendarItem*)rep.item).uid isEqualToString:itemToFind.uid])
					[matchingReps addObject:rep];
			}
		}
	}
	
	// if we have any matching reps, then create a path
	return matchingReps;
}

-(FSCalItemRepresentation*)highlightRepFor:(FSCalItemRepresentation*)itemRep
{
	// tasks and dayevs get a different path
	NSBezierPath* path;
	if(itemRep.repType & FSRepForNormalEvent){
		path = [[itemRep.path copy] autorelease];
		[path setLineWidth:0.0f];
	}else{
		path = [FSWhenGeometry taskDayevHighlightPathInDial:itemRep.dial 
										  position:itemRep.taskDayevIndexInDial 
											  item:itemRep.item
										  selected:NO];
	}
	
	// create and init the highlight rep
	FSCalItemRepresentation* rVal = [[FSCalItemRepresentation alloc] initWithItem:itemRep.item 
																			 dial:itemRep.dial 
																			 path:path];
	
	// colors!!!
	if(itemRep.repType & FSRepForNormalEvent){
		[rVal setFillColor:normalEventHighlightFillColor];
		[rVal setStrokeColor:normalEventHighlightStrokeColor];
	}else{
		[rVal setFillColor:taskDayevHighlightFillColor];
		[rVal setStrokeColor:taskDayevHighlightStrokeColor];
	}
		
	// return it
	[rVal autorelease];
	return rVal;
}

-(FSCalItemRepresentation*)selectionRepFor:(FSCalItemRepresentation*)itemRep
{
	// tasks and dayevs get a different path
	NSBezierPath* path;
	if(itemRep.repType & FSRepForNormalEvent){
		path = [[itemRep.path copy] autorelease];
		[path setLineWidth:2.0f];
	}else{
		path = [FSWhenGeometry taskDayevHighlightPathInDial:itemRep.dial 
										  position:itemRep.taskDayevIndexInDial 
											  item:itemRep.item
										  selected:YES];
	}
	
	// create and init the highlight rep
	FSCalItemRepresentation* rVal = [[FSCalItemRepresentation alloc] initWithItem:itemRep.item 
																			 dial:itemRep.dial 
																			 path:path];
	
	// colors!!!
	if(itemRep.repType & FSRepForNormalEvent){
		[rVal setFillColor:normalEventSelectionFillColor];
	}else{
		[rVal setFillColor:taskDayevSelectionFillColor];
		if(rVal.repType & FSRepForSingleItem)
			[rVal setStrokeColor:((CalCalendarItem*)rVal.item).calendar.color];
	}
	
	// return it
	[rVal autorelease];
	return rVal;
}

-(void)drawHighlighAndSelection
{
	// paint the overlaying stuff
	
	for(FSCalItemRepresentation* highlightRep in highlight){
		[[highlightRep fillColor] set];
		[highlightRep.path fill];
		if([highlightRep.path lineWidth] > 0.0f){
			[[highlightRep strokeColor] set];
			[highlightRep.path stroke];
		}
	}
	
	for(FSCalItemRepresentation* selectionRep in selection){
		
		[[selectionRep fillColor] set];
		[selectionRep.path fill];
		
		if([selectionRep.path lineWidth] > 0.0f){
			[[selectionRep strokeColor] set];
			[selectionRep.path stroke];
		}
	}
}

-(void)updateDialHighlightGeometry
{
	[earlyDialHighlight release];
	earlyDialHighlight = nil;
	[lateDialHighlight release];
	lateDialHighlight = nil;
	
	float radius = TASK_DAYEV_POSITION_RADIUS;
	
	// the early dial highlight
	if(taskDisplayStyle == FSDisplayInEarlyDial || dayEventDisplayStyle == FSDisplayInEarlyDial){
		earlyDialHighlight = [FSWhenGeometry circleWithCenter:[FSWhenGeometry dialCenter:earlyDialPosition] 
													   radius:radius];
		[earlyDialHighlight setLineWidth:0.75];
		[earlyDialHighlight retain];
	}
		
	// the late dial highlight
	if(taskDisplayStyle == FSDisplayInLateDial || dayEventDisplayStyle == FSDisplayInLateDial){
		lateDialHighlight = [FSWhenGeometry circleWithCenter:[FSWhenGeometry dialCenter:[self lateDialPosition]] 
													  radius:radius];
		[lateDialHighlight setLineWidth:0.75];
		[lateDialHighlight retain];
	}
}

#pragma mark -
#pragma mark Actions

-(IBAction)newEvent:(id)sender
{
	NSCalendarDate* start = [FSWhenGeometry timeForMouseLocation:cursorInView inView:self];
	NSDate* end = [[NSCalendarDate alloc] initWithTimeInterval:3600 sinceDate:start];
	CalCalendar* cal = [[FSCalendarsManager sharedManager] highestPriorityCalendar];
	[FSAppController newEventWithStartDate:start endDate:end calendar:cal dayEvent:NO];
	[end release];
}

-(IBAction)newDayEvent:(id)sender
{
	NSCalendarDate* start = [FSWhenTime calendarDateForOffset:offset];
	NSCalendarDate* end = [[NSDate alloc] initWithTimeInterval:0.01 sinceDate:start];
	CalCalendar* cal = [[FSCalendarsManager sharedManager] highestPriorityCalendar];
	[FSAppController newEventWithStartDate:start endDate:end calendar:cal dayEvent:YES];
	[end release];
}

-(IBAction)newTask:(id)sender
{
	NSCalendarDate* dueDate = [FSWhenTime calendarDateForOffset:offset];
	CalCalendar* cal = [[FSCalendarsManager sharedManager] highestPriorityCalendar];
	[FSAppController newTask:dueDate calendar:cal];
}

-(IBAction)pasteHere:(id)sender
{
	// this paste op differs from the AppController one
	// in that it pastes items into this dial's offset
	
	// save the items
	for(CalCalendarItem* calItem in [FSAppController calItemsFromGeneralPasteboard]){
		
		// ensure that the item is in this dial
		
		// cal events
		if([calItem isKindOfClass:[CalEvent class]]){
			CalEvent* event = (CalEvent*)calItem;
			int eventOffset = [FSWhenTime offsetForDate:event.startDate useWhenDayStart:!event.isAllDay];
			if(offset != eventOffset){
				NSTimeInterval diff = 86400.0f * (offset - eventOffset);
				event.startDate = [[[NSDate alloc] initWithTimeInterval:diff sinceDate:event.startDate] autorelease];
				event.endDate = [[[NSDate alloc] initWithTimeInterval:diff sinceDate:event.endDate] autorelease];
			}
		}
		
		// cal tasks
		else{
			CalTask* task = (CalTask*)calItem;
			int eventOffset = task.dueDate == nil ? offset : [FSWhenTime offsetForDate:task.dueDate useWhenDayStart:NO];
			if(offset != eventOffset){
				NSTimeInterval diff = 86400.0f * (offset - eventOffset);
				task.dueDate = [[[NSDate alloc] initWithTimeInterval:diff sinceDate:task.dueDate] autorelease];
			}
		}
		
		[[FSCalendarsManager sharedManager] saveItem:calItem];
	}
}

-(BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	if([menuItem action] == @selector(pasteHere:))
		return [[FSAppController calItemsFromGeneralPasteboard] count] != 0;
	else
		return [[FSAppController controller] validateMenuItem:menuItem];
}

#pragma mark -
#pragma mark Overrides

-(void)updateAllGeometry
{
	[super updateAllGeometry];
	[self updateDialHighlightGeometry];
}

-(void)drawRect:(NSRect)dirtyRect
{
	// we need to set some scaling
	[transform concat];
	
	[self drawTransparentBackgroundGeometry];
	[self drawNavButtons];
	
	// nav button highlights
	[[NSColor grayColor] set];
	if(contentUnderCursor == FSForwardNavButton)
		[navButtonForwardHighlight stroke];
	if(contentUnderCursor == FSBackwardNavButton)
		[navButtonBackwardHighlight stroke];
	
	[self drawBackgroundGeometry];
	[self drawDialTickMarks];
	
	// dial highlights
	[dialHighlightColor set];
	BOOL highlightEarly = contentUnderCursor == FSEarlyDialInnerCircle ||
		(contentUnderCursor == FSDayEvent && dayEventDisplayStyle == FSDisplayInEarlyDial) ||
		(contentUnderCursor == FSTask && taskDisplayStyle == FSDisplayInEarlyDial);
	BOOL highlightLate = contentUnderCursor == FSLateDialInnerCircle ||
		(contentUnderCursor == FSDayEvent && dayEventDisplayStyle == FSDisplayInLateDial) ||
		(contentUnderCursor == FSTask && taskDisplayStyle == FSDisplayInLateDial);
	if(highlightEarly)
		[earlyDialHighlight stroke];
	if(highlightLate)
		[lateDialHighlight stroke];
	
	[self drawTasks];
	[self drawEvents];
	
	// event highlights
	[self drawHighlighAndSelection];
	
	[self drawElapsedTimeGeometry];
	[self drawText];
	[self drawGloss];
}

-(void)updateNavButtonGeometry
{
	// do the super class thing
	[super updateNavButtonGeometry];
	
	// here we just deal with the nav button highlights
	
	// release existing paths
	[navButtonForwardHighlight release];
	navButtonForwardHighlight = nil;
	[navButtonBackwardHighlight release];
	navButtonBackwardHighlight = nil;
	
	NSPoint forwardCenter = [FSWhenGeometry navigationButtonCenterForwards:YES 
														 earlyDialPosition:earlyDialPosition 
															 flowDirection:flowDirection];
	NSPoint backwardCenter = [FSWhenGeometry navigationButtonCenterForwards:NO 
														  earlyDialPosition:earlyDialPosition 
															  flowDirection:flowDirection];
	
	navButtonForwardHighlight = [[FSWhenGeometry circleWithCenter:forwardCenter 
															radius:NAV_BUTTON_RADIUS * 0.8] retain];
	[navButtonForwardHighlight setLineWidth:0.75f];
	navButtonBackwardHighlight = [[FSWhenGeometry circleWithCenter:backwardCenter 
															 radius:NAV_BUTTON_RADIUS * 0.8] retain];
	[navButtonBackwardHighlight setLineWidth:0.75f];
}

-(void)updateEventGeometry{
	[super updateEventGeometry];
	[self updateHighlightedItemsGeometry];
	[self updateSelectedItemsGeometry];
}

-(void)updateTaskGeometry{
	[super updateTaskGeometry];
	[self updateHighlightedItemsGeometry];
	[self updateSelectedItemsGeometry];
}

-(void)setTaskDisplayStyle:(int)newStyle
{
	[super setTaskDisplayStyle:newStyle];
	[self updateDialHighlightGeometry];
}

-(void)setDayEventDisplayStyle:(int)newStyle
{
	[super setDayEventDisplayStyle:newStyle];
	[self updateDialHighlightGeometry];
}

#pragma mark -

-(void)dealloc
{
	[highlight release];
	[selection release];
	
	[navButtonForwardHighlight release];
	[navButtonBackwardHighlight release];
	[earlyDialHighlight release];
	[lateDialHighlight release];
	
	[dialHighlightColor release];
	
	[mouseDownEvent release];
	
	[super dealloc];
}

@end
