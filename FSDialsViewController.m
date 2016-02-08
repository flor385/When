//
//  FSDialsViewController.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 23.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSDialsViewController.h"
#import "FSDialsViewInput.h"
#import "FSCalItemAdditions.h"
#import "FSCalendarMapping.h"
#import "FSHUDTooltipController.h"

@implementation FSDialsViewController

static NSMutableArray* allControllers;

#pragma mark -
#pragma mark Instance tracking

+(NSArray*)allCurrentDialViewControllers
{
	return [NSArray arrayWithArray:allControllers];
}

+(NSArray*)allCurrentDialViewsSorted
{
	NSMutableArray* views = [NSMutableArray new];
	for(FSDialsViewController* controller in [FSDialsViewController allCurrentDialViewControllers])
		[views addObject:[controller view]];
	
	NSArray* rVal = [views sortedArrayUsingSelector:@selector(compare:)];
	[views release];
	return rVal;
}

+(NSInteger)highestOffset
{
	NSInteger offset = NSIntegerMin;
	for(FSDialsViewController* controller in [FSDialsViewController allCurrentDialViewControllers]){
		FSDialsView* view = (FSDialsView*)[controller view];
		offset = fmaxl(offset, view.offset);
	}
	
	return offset;
}

+(NSInteger)lowestOffset
{
	NSInteger offset = NSIntegerMax;
	for(FSDialsViewController* controller in [FSDialsViewController allCurrentDialViewControllers]){
		FSDialsView* view = (FSDialsView*)[controller view];
		offset = fminl(offset, view.offset);
	}
	
	return offset;
}

+(FSDialsViewController*)existingControllerWithOffset:(int)offset
{
	for(FSDialsViewController* controller in allControllers)
		if( ((FSDialsView*)[controller view]).offset == offset)
			return controller;
	
	return nil;
}

+(void)removeController:(FSDialsViewController*)controller
{
	[allControllers removeObject:controller];
}

+(void)ensureOffsetIsVisible:(NSInteger)offset
{
	int lowestOffset = [FSDialsViewController lowestOffset];
	int highestOffset = [FSDialsViewController highestOffset];
	FSRange offsetRange = [FSWhenUtil rangeWithLoc:lowestOffset lenght:highestOffset - lowestOffset + 1];
	
	// are we out of the displayed offset range?
	if(![FSWhenUtil integer:offset isInRange:offsetRange]){
		int deltaOffset = offset < lowestOffset ? offset - lowestOffset : offset - highestOffset;
		for(FSDialsView* view in [FSDialsViewController allCurrentDialViewsSorted])
			view.offset += deltaOffset;
	}
}

#pragma mark -
#pragma mark Managing selected / highlighted items

static NSArray* selectionCalItems;
static NSArray* highlightCalItems;

+(NSArray*)selectionCalItems{
	return selectionCalItems;
}

+(void)setSelectionCalItems:(NSArray*)newSelection
{
	// if the selection is the same as before, there is nothing to do
	if(newSelection == nil && selectionCalItems == nil) return;
	if([selectionCalItems isEqualToArray:newSelection]) return;
	
	// assign the new selection
	[newSelection retain];
	[selectionCalItems release];
	selectionCalItems = newSelection;
	
	// update the GUI
	for(FSDialsViewInput* view in [FSDialsViewController allCurrentDialViewsSorted]){
		[view updateSelectedItemsGeometry];
		[view updateHighlightedItemsGeometry];
		[view setNeedsDisplay:YES];
	}
	
	// if the info is open already, update it
	if([[FSItemInfoEditPanel sharedPanel] isVisible])
		if([selectionCalItems count] == 0)
			[[FSItemInfoEditPanel sharedPanel] orderOut:self];
		else
			[[FSItemInfoEditPanel sharedPanel] doTheSameWithNewItems:selectionCalItems canContinueAdding:NO];
}

+(NSArray*)highlightCalItems{
	return highlightCalItems;
}

+(void)setHighlightCalItems:(NSArray*)newHighlight
{
	// if the selection is the same as before, there is nothing to do
	if(highlightCalItems == nil && newHighlight == nil) return;
	if([highlightCalItems isEqualToArray:newHighlight]) return;
	
	[newHighlight retain];
	[highlightCalItems release];
	highlightCalItems = newHighlight;
	
	// update the GUI
	for(FSDialsViewInput* view in [FSDialsViewController allCurrentDialViewsSorted]){
		[view updateHighlightedItemsGeometry];
		[view setNeedsDisplay:YES];
	}
	
	// update the HUD tooltip
	if([highlightCalItems count] == 0)
		[FSHUDTooltipController orderOut];
	else
		[FSHUDTooltipController updateAndDisplay];
}

+(BOOL)hasRecurrenceInSelection
{
	for(CalCalendarItem* item in selectionCalItems){
		if([item isKindOfClass:[CalEvent class]] && ((CalEvent*)item).recurrenceRule != nil)
			return YES;
	}
	
	return NO;
}


#pragma mark -
#pragma mark Initialization, value binding and observing

-(id)init
{
	id rVal = [self initWithNibName:@"DialsView" bundle:nil];
	return rVal;
}

-(id)initWithNibName:(NSString*)nibName bundle:(NSBundle*)bundle
{
	// initialize controllers cache
	if(allControllers == nil) allControllers = [NSMutableArray new];
	
	// initialize and return self
	if(self == [super initWithNibName:nibName bundle:bundle])
		[allControllers addObject:self];
	
	return self;
}

-(void)awakeFromNib
{
	// we are interested in obsering come changes
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	
	[ud addObserver:self forKeyPath:FSCalendarsPreference options:0 context:nil];
	[ud addObserver:self forKeyPath:FSOneTrackPerCalPreference options:0 context:nil];
	[ud addObserver:self forKeyPath:FSTrackNumberPreference options:0 context:nil];
	[ud addObserver:self forKeyPath:FSUseCollapsingTrackPreference options:0 context:nil];
}

-(void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	// calendars preference
	if([keyPath isEqualTo:FSCalendarsPreference]){
		FSDialsView* dialsView = (FSDialsView*)[self view];
		[dialsView updateTaskGeometry];
		[dialsView updateEventGeometry];
		[dialsView setNeedsDisplay:YES];
	}
	
	// track tweaking preferences
	else if([keyPath isEqual:FSOneTrackPerCalPreference] || [keyPath isEqual:FSTrackNumberPreference] 
			|| [keyPath isEqual:FSUseCollapsingTrackPreference])
	{
		FSDialsView* dialsView = (FSDialsView*)[self view];
		[dialsView updateEventGeometry];
		[dialsView setNeedsDisplay:YES];
	}
}

#pragma mark -
#pragma mark Actions

-(IBAction)makeSelectedDayEventIntoNormalEvent:(id)sender
{
	NSArray* selectionItems = [FSDialsViewController selectionCalItems];
	if([selectionItems count] == 0) return;
	
	NSArray* toConvert = [NSArray arrayWithArray:selectionItems];
	
	// remove the selection and the highlight
	for(FSDialsViewInput* view in [FSDialsViewController allCurrentDialViewsSorted]){
		[FSDialsViewController setHighlightCalItems:nil];
		[FSDialsViewController setSelectionCalItems:nil];
	}
	
	for(CalEvent* event in toConvert){
		event.isAllDay = NO;
		[[FSCalendarsManager sharedManager] saveItem:event];
	}
}

-(IBAction)makeSelectedEventIntoDayEvent:(id)sender
{
	NSArray* selectionItems = [FSDialsViewController selectionCalItems];
	if([selectionItems count] == 0) return;
	
	NSArray* toConvert = [NSArray arrayWithArray:selectionItems];
	
	// remove the selection and the highlight
	for(FSDialsViewInput* view in [FSDialsViewController allCurrentDialViewsSorted]){
		[FSDialsViewController setHighlightCalItems:nil];
		[FSDialsViewController setSelectionCalItems:nil];
	}
	
	for(CalEvent* event in toConvert){
		event.isAllDay = YES;
		[[FSCalendarsManager sharedManager] saveItem:event];
	}
}

-(IBAction)markSelectedTaskAsCompleted:(id)sender
{
	NSArray* selectionItems = [FSDialsViewController selectionCalItems];
	if([selectionItems count] == 0) return;
	
	NSArray* toMark = [NSArray arrayWithArray:selectionItems];
	
	// remove the selection and the highlight
	for(FSDialsViewInput* view in [FSDialsViewController allCurrentDialViewsSorted]){
		[FSDialsViewController setHighlightCalItems:nil];
		[FSDialsViewController setSelectionCalItems:nil];
	}
	
	CalCalendarStore* store = [[FSCalendarsManager sharedManager] calendarStore];
	NSError* error;
	for(CalTask* task in toMark){
		task.isCompleted = YES;
		if(![store saveTask:task error:&error]){
			//	failed
			NSAlert *theAlert = [NSAlert alertWithError:error];
			[theAlert runModal];
			return;
		}
	}
}

#pragma mark -
#pragma mark Actions we forward to the app controller

-(IBAction)addViewToFront:(id)sender
{
	[[FSAppController controller] addViewToFront:sender];
}

-(IBAction)addViewToBack:(id)sender
{
	[[FSAppController controller] addViewToBack:sender];
}

-(IBAction)removeFirstDay:(id)sender
{
	[[FSAppController controller] removeFirstDay:sender];
}

-(IBAction)removeLastDay:(id)sender
{
	[[FSAppController controller] removeLastDay:sender];
}

-(IBAction)incrementOffset:(id)sender
{
	[[FSAppController controller] incrementOffset:sender];
}

-(IBAction)decrementOffset:(id)sender
{
	[[FSAppController controller] decrementOffset:sender];
}

-(BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	return [[FSAppController controller] validateMenuItem:menuItem];
}

@end
