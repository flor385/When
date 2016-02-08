//
//  FSAppController.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 13.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSAppController.h"
#import "FSPreferencesController.h"
#import "FSCalendarMapping.h"
#import "FSCalItemAdditions.h"
#import "FSItemInfoEditPanel.h"
#import "FSURLStringValueTransformer.h"
#import "FSCalPriorityIndexValueTransformer.h"
#import "FSPreferencesController.h"
#import "FSWhenUtil.h"
#import "FSNewCalendarController.h"
#import "FSObjectToStringValueTransformer.h"
#import "FSSoundNameValueTransformer.h"
#import "FSGoToDatePanelController.h"

@implementation FSAppController

#pragma mark -
#pragma mark Initialization

+ (void)initialize
{
    if (self == [FSAppController class]){
        
		// init preference defaults
		[FSPreferencesController initiPreferenceDefaults];
		
		// start when timer
		[FSWhenTime startWhenTimer];
		
		// register custom value transformers
		// create an autoreleased instance of our value transformer
		NSValueTransformer* transformer = [[FSURLStringValueTransformer new] autorelease];
		[NSValueTransformer setValueTransformer:transformer
										forName:@"FSURLStringValueTransformer"];
		transformer = [[FSCalPriorityIndexValueTransformer new] autorelease];
		[NSValueTransformer setValueTransformer:transformer
										forName:@"FSCalPriorityIndexValueTransformer"];
		transformer = [[FSObjectToStringValueTransformer new] autorelease];
		[NSValueTransformer setValueTransformer:transformer
										forName:@"FSObjectToStringValueTransformer"];
		transformer = [[FSSoundNameValueTransformer new] autorelease];
		[NSValueTransformer setValueTransformer:transformer
										forName:@"FSSoundNameValueTransformer"];
		transformer = [[FSArrayProxyObjectTransformer new] autorelease];
		[NSValueTransformer setValueTransformer:transformer
										forName:@"FSArrayProxyObjectTransformer"];
		
		// cache the events we will need in bulk (faster then lazy init on per-day requests
		NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
		int baseOffset = [ud integerForKey:FSAnchorDialViewOffsetPreference];
		int lowestOffset = baseOffset - [ud integerForKey:FSNumberOfBackwardDialsPreference];
		int highestOffset = baseOffset + [ud integerForKey:FSNumberOfForwardDialsPreference];
		// cache some more, it does not hurt
		lowestOffset -= FS_OFFSET_LOOK_AHEAD;
		highestOffset += FS_OFFSET_LOOK_AHEAD;
		
		// the range of the offsets we want to cache events for
		FSRange range = [FSWhenUtil rangeWithLoc:lowestOffset lenght:highestOffset - lowestOffset + 1];
		
		// cache (dayevs and tasks only if they are asked for
		[[FSCalendarsManager sharedManager] updateNormalEventCaches:range];
		if([ud integerForKey:FSDayEventDisplayStyle] != FSDoNotDisplay)
			[[FSCalendarsManager sharedManager] updateDayEventCaches:range];
		if([ud integerForKey:FSTaskDisplayStyle] != FSDoNotDisplay)
			[[FSCalendarsManager sharedManager] updateTaskCaches:range];
    }
}

static FSAppController* controller;

+(FSAppController*)controller
{
	return controller;
}

-(id)init
{
	if(self == [super init]){
		controller = self;
	}
	
	return self;
}

#pragma mark -
#pragma mark Exposing some stuff

-(NSInteger)anchorViewOffset
{
	return ((FSDialsView*)[[mainWindow anchorViewController] view]).offset;
}

#pragma mark -
#pragma mark Dials view adding / removing

-(IBAction)addViewToFront:(id)sender
{
	[mainWindow addDialViewToFront:YES updateGUI:YES];
}

-(IBAction)addViewToBack:(id)sender
{
	[mainWindow addDialViewToFront:NO updateGUI:YES];
}

-(IBAction)removeFirstDay:(id)sender
{
	[mainWindow removeDialViewFromFront:NO updateGUI:YES];
}

-(IBAction)removeLastDay:(id)sender
{
	[mainWindow removeDialViewFromFront:YES updateGUI:YES];
}

#pragma mark -
#pragma mark Offset changing

-(IBAction)incrementOffset:(id)sender
{
	for(FSDialsView* view in [FSDialsViewController allCurrentDialViewsSorted]){
		view.offset += 1;
		[view setNeedsDisplay:YES];
	}
}

-(IBAction)decrementOffset:(id)sender
{
	for(FSDialsView* view in [FSDialsViewController allCurrentDialViewsSorted]){
		view.offset -= 1;
		[view setNeedsDisplay:YES];
	}
}

-(IBAction)incrementOffsetByWeek:(id)sender
{
	for(FSDialsView* view in [FSDialsViewController allCurrentDialViewsSorted]){
		view.offset += 7;
		[view setNeedsDisplay:YES];
	}
}

-(IBAction)incrementOffsetByMonth:(id)sender
{
	// get a date for the same day, next month, relative to the anchor view offset
	int anchorOffset = ((FSDialsView*)[[mainWindow anchorViewController] view]).offset;
	NSCalendarDate* anchorDate = [FSWhenTime calendarDateForOffset:anchorOffset];
	int month = [anchorDate monthOfYear] + 1;
	int year = [anchorDate yearOfCommonEra];
	if(month > 12){
		month = 1;
		year++;
	}
	NSCalendarDate* destinationDate = [NSCalendarDate dateWithYear:year 
															 month:month 
															   day:[anchorDate dayOfMonth] 
															  hour:[anchorDate hourOfDay] 
															minute:[anchorDate minuteOfHour] 
															second:[anchorDate secondOfMinute] 
														  timeZone:nil];
	
	// figure out how many days ahead that is
	NSTimeInterval interval = [destinationDate timeIntervalSinceDate:anchorDate];
	int days = (int)roundtol(interval / 86400.0f);
	
	// and do it!
	for(FSDialsView* view in [FSDialsViewController allCurrentDialViewsSorted]){
		view.offset += days;
		[view setNeedsDisplay:YES];
	}
}

-(IBAction)decrementOffsetByWeek:(id)sender
{
	for(FSDialsView* view in [FSDialsViewController allCurrentDialViewsSorted]){
		view.offset -= 7;
		[view setNeedsDisplay:YES];
	}
}

-(IBAction)decrementOffsetByMonth:(id)sender
{
	// get a date for the same day, next month, relative to the anchor view offset
	int anchorOffset = ((FSDialsView*)[[mainWindow anchorViewController] view]).offset;
	NSCalendarDate* anchorDate = [FSWhenTime calendarDateForOffset:anchorOffset];
	int month = [anchorDate monthOfYear] + 1;
	int year = [anchorDate yearOfCommonEra];
	if(month > 12){
		month = 1;
		year++;
	}
	NSCalendarDate* destinationDate = [NSCalendarDate dateWithYear:year 
															 month:month 
															   day:[anchorDate dayOfMonth] 
															  hour:[anchorDate hourOfDay] 
															minute:[anchorDate minuteOfHour] 
															second:[anchorDate secondOfMinute] 
														  timeZone:nil];
	
	// figure out how many days ahead that is
	NSTimeInterval interval = [destinationDate timeIntervalSinceDate:anchorDate];
	int days = (int)roundtol(interval / 86400.0f);
	
	// and do it!
	for(FSDialsView* view in [FSDialsViewController allCurrentDialViewsSorted]){
		view.offset -= days;
		[view setNeedsDisplay:YES];
	}
}

-(IBAction)goToToday:(id)sender
{
	int offsetDecrease = ((FSDialsView*)[[mainWindow anchorViewController] view]).offset;
	if(offsetDecrease == 0) return;
	
	for(FSDialsView* view in [FSDialsViewController allCurrentDialViewsSorted])
		view.offset -= offsetDecrease;
}

-(IBAction)goToDate:(id)sender
{
	[[FSGoToDatePanelController sharedInstance] start:sender];
}

#pragma mark -
#pragma mark Event, task, calendar creation

-(IBAction)newEvent:(id)sender
{
	// make a span of one hour from now
	NSCalendarDate* startDate = [FSWhenTime currentTime];
	NSDate* endDate = [startDate dateByAddingYears:0 months:0 days:0 hours:1 minutes:0 seconds:0];
	
	// use the highest priority used calendar
	CalCalendar* cal = [[FSCalendarsManager sharedManager] highestPriorityCalendar];
	
	// create it!
	[FSAppController newEventWithStartDate:startDate endDate:endDate calendar:cal dayEvent:NO];
}

+(void)newEventWithStartDate:(NSDate*)startDate 
					 endDate:(NSDate*)endDate 
					calendar:(CalCalendar*)calendar 
					dayEvent:(BOOL)dayev
{
	if(calendar == nil) return;
	
	// create and save the new event
	CalEvent* newEvent = [[CalEvent new] autorelease];
	newEvent.calendar = calendar;
	newEvent.startDate = startDate;
	newEvent.endDate = endDate;
	newEvent.title = dayev ? @"New day event" : @"New event";
	if(dayev) newEvent.isAllDay = YES;
	
	// save the changes!
	[[FSCalendarsManager sharedManager] saveItem:newEvent];
	
	// find the offset in which this new event belongs
	// and ensure it is visible
	int offset = [FSWhenTime offsetForDate:startDate useWhenDayStart:!dayev];
	[FSDialsViewController ensureOffsetIsVisible:offset];
	
	// and finally, select the newly created item and edit it
	NSArray* newEventArray = [NSArray arrayWithObject:newEvent];
	[FSDialsViewController setSelectionCalItems:newEventArray];
	[[FSItemInfoEditPanel sharedPanel] addEvents:newEventArray];
}

-(IBAction)newDayEvent:(id)sender
{
	CalCalendar* cal = [[FSCalendarsManager sharedManager] highestPriorityCalendar];
	[FSAppController newDayEventWithDate:[FSWhenTime currentTime] calendar:cal];
}

+(void)newDayEventWithDate:(NSCalendarDate*)date calendar:(CalCalendar*)calendar
{
	// make a span of one second from now
	NSDate* endDate = [date dateByAddingYears:0 months:0 days:0 hours:0 minutes:0 seconds:1];
	
	// create it!
	[FSAppController newEventWithStartDate:date endDate:endDate calendar:calendar dayEvent:YES];
}

-(IBAction)newTask:(id)sender
{
	CalCalendar* cal = [[FSCalendarsManager sharedManager] highestPriorityCalendar];
	[FSAppController newTask:[FSWhenTime currentTime] calendar:cal];
}

+(void)newTask:(NSCalendarDate*)dueDate calendar:(CalCalendar*)calendar
{
	if(calendar == nil) return;
	
	// create and save the new task
	CalTask* newTask = [CalTask task];
	newTask.calendar = calendar;
	newTask.dueDate = dueDate;
	newTask.title = @"New task";
	
	// save it!
	[[FSCalendarsManager sharedManager] saveItem:newTask];
	
	// find the offset in which this new task belongs
	// and ensure it is visible
	int offset = [FSWhenTime offsetForDate:dueDate useWhenDayStart:NO];
	[FSDialsViewController ensureOffsetIsVisible:offset];
	
	// and finally, select the newly created item and edit it
	NSArray* newItemInArray = [NSArray arrayWithObject:newTask];
	[FSDialsViewController setSelectionCalItems:newItemInArray];
	[[FSItemInfoEditPanel sharedPanel] addTasks:newItemInArray];
}

-(IBAction)newCalendar:(id)sender
{
	[FSAppController newCalendar];
}

+(void)newCalendar
{
	[[FSNewCalendarController sharedController] show:self];
}

#pragma mark -
#pragma mark Info, edit etc

+(IBAction)showSelectedItemInfo
{
	NSArray* selectionItems = [FSDialsViewController selectionCalItems];
	
	// determine are we dealing with events or tasks
	BOOL displayEventInfo = [[selectionItems objectAtIndex:0] isKindOfClass:[CalEvent class]];
	
	if(displayEventInfo)
		[[FSItemInfoEditPanel sharedPanel] showEvents:selectionItems];
	else
		[[FSItemInfoEditPanel sharedPanel] showTasks:selectionItems];
}

-(IBAction)showSelectedItemInfo:(id)sender
{
	[FSAppController showSelectedItemInfo];
}

+(IBAction)editSelectedItem
{
	NSArray* selectionItems = [FSDialsViewController selectionCalItems];
	
	// determine are we dealing with events or tasks
	BOOL eventEdit = [[selectionItems objectAtIndex:0] isKindOfClass:[CalEvent class]];
	
	if(eventEdit)
		[[FSItemInfoEditPanel sharedPanel] editEvents:selectionItems];
	else
		[[FSItemInfoEditPanel sharedPanel] editTasks:selectionItems];
}

-(IBAction)editSelectedItem:(id)sender
{
	[FSAppController editSelectedItem];
}

-(IBAction)deleteSelection:(id)sender
{
	NSArray* selectionItems = [FSDialsViewController selectionCalItems];
	if([selectionItems count] == 0) return;
	
	NSArray* toDelete = [NSArray arrayWithArray:selectionItems];
	
	for(CalCalendarItem* item in toDelete)
		[[FSCalendarsManager sharedManager] deleteItem:item];
}

static NSString* FSWhenPasteboardType = @"FSWhenPasteboardType";
static NSArray* pasteboardTypeArray = nil;

-(IBAction)cut:(id)sender
{
	[self copy:sender];
	[self deleteSelection:sender];
}

-(IBAction)copy:(id)sender
{
	// encode the selected items
	NSArray* selection = [FSDialsViewController selectionCalItems];
	if([selection count] == 0) return;
	NSMutableArray* selectionDictReps = [[NSMutableArray new] autorelease];
	for(CalCalendarItem* calItem in selection)
		[selectionDictReps addObject:[calItem pasteboardDict]];
	NSData* encodedSelection = [NSKeyedArchiver archivedDataWithRootObject:selectionDictReps];
	
	// lazy init of the pb type array
	if(pasteboardTypeArray == nil)
		pasteboardTypeArray = [[NSArray arrayWithObject:FSWhenPasteboardType] retain];
	
	// perform the copy op
	NSPasteboard* pb = [NSPasteboard generalPasteboard];
	[pb declareTypes:pasteboardTypeArray owner:self];
	[pb setData:encodedSelection forType:FSWhenPasteboardType];
}

-(IBAction)paste:(id)sender
{
	for(CalCalendarItem* calItem in [FSAppController calItemsFromGeneralPasteboard])
		[[FSCalendarsManager sharedManager] saveItem:calItem];
}

+(NSArray*)calItemsFromGeneralPasteboard
{
	// lazy init of the pb type array
	if(pasteboardTypeArray == nil)
		pasteboardTypeArray = [[NSArray arrayWithObject:FSWhenPasteboardType] retain];
	
	NSPasteboard* pb = [NSPasteboard generalPasteboard];
	if([pb availableTypeFromArray:pasteboardTypeArray]){
		// there is something there!
		NSData* itemsData = [pb dataForType:FSWhenPasteboardType];
		NSArray* itemsArray = [NSKeyedUnarchiver unarchiveObjectWithData:itemsData];
		NSMutableArray* rVal = [[[NSMutableArray alloc] initWithCapacity:[itemsArray count]] autorelease];
		for(NSDictionary* pbDict in itemsArray)
			[rVal addObject:[CalCalendarItem calItemForPasteboardDict:pbDict]];
		
		return rVal;
	}
	
	return [NSArray array];
}

-(IBAction)duplicate:(id)sender
{
	// get the selected items
	NSArray* selection = [FSDialsViewController selectionCalItems];
	if([selection count] == 0) return;
	
	// for each item, create a dict representation
	// then create a new item based on it, and save it
	for(CalCalendarItem* calItem in selection){
		CalCalendarItem* duplicate = [CalCalendarItem calItemForPasteboardDict:[calItem pasteboardDict]];
		[[FSCalendarsManager sharedManager] saveItem:duplicate];
	}
}

#pragma mark -
#pragma mark NSApplication delegate methods

-(void)applicationWillTerminate:(NSNotification *)aNotification
{
	// store some user preferences
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	
	// anchor offset
	int anchorOffset = ((FSDialsView*)[[mainWindow anchorViewController] view]).offset;
	[ud setValue:[NSNumber numberWithInt:anchorOffset] forKey:FSAnchorDialViewOffsetPreference];
	
	// the number of forward / backward views
	int maxOffset = [FSDialsViewController highestOffset];
	[ud setValue:[NSNumber numberWithInt:maxOffset - anchorOffset] forKey:FSNumberOfForwardDialsPreference];
	int minOffset = [FSDialsViewController lowestOffset];
	[ud setValue:[NSNumber numberWithInt:anchorOffset - minOffset] forKey:FSNumberOfBackwardDialsPreference];
	
	// the current window position
	NSPoint windowOrigin = [mainWindow frame].origin;
	[ud setValue:[NSNumber numberWithInt:windowOrigin.x] forKey:FSMainWindowOriginX];
	[ud setValue:[NSNumber numberWithInt:windowOrigin.y] forKey:FSMainWindowOriginY];
}

#pragma mark -
#pragma mark Misc

-(BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	SEL action = [menuItem action];
	
	// lazy init of the pb type array
	if(pasteboardTypeArray == nil)
		pasteboardTypeArray = [[NSArray arrayWithObject:FSWhenPasteboardType] retain];
	
	// navigation actions
	if(action == @selector(goToToday:))
		return ((FSDialsView*)[[mainWindow anchorViewController] view]).offset != 0;
	
	// view add / removal actions
	if(action == @selector(removeFirstDay:)){
		FSDialsView* anchorView = (FSDialsView*)[[mainWindow anchorViewController] view];
		return [FSDialsViewController lowestOffset] != anchorView.offset;
	}else if(action == @selector(removeLastDay:)){
		FSDialsView* anchorView = (FSDialsView*)[[mainWindow anchorViewController] view];
		return [FSDialsViewController highestOffset] != anchorView.offset;
	}
	
	// event creation stuff
	else if(action == @selector(newEvent:))
		return [[FSCalendarsManager sharedManager].calendarMappings count] > 0;
	else if(action == @selector(newTask:))
		return [[FSCalendarsManager sharedManager].calendarMappings count] > 0;
	else if(action == @selector(newDayEvent:))
		return [[FSCalendarsManager sharedManager].calendarMappings count] > 0;
	
	// info edit
	else if(action == @selector(showSelectedItemInfo:))
			return [[FSDialsViewController selectionCalItems] count] != 0;
	else if(action == @selector(editSelectedItem:))
			return [[FSDialsViewController selectionCalItems] count] != 0;
	
	// deletion, cut, copy, paste, duplicate
	else if(action == @selector(deleteSelection:))
		return [[FSDialsViewController selectionCalItems] count] != 0;
	else if(action == @selector(cut:))
		return [[FSDialsViewController selectionCalItems] count] != 0;
	else if(action == @selector(copy:))
		return [[FSDialsViewController selectionCalItems] count] != 0;
	else if(action == @selector(paste:))
		return [[NSPasteboard generalPasteboard] availableTypeFromArray:pasteboardTypeArray] != nil;
	else if(action == @selector(duplicate:))
		return [[FSDialsViewController selectionCalItems] count] != 0;
	
	return YES;
}

@end
