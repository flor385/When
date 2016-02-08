//
//  FSItemEditController.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 11.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSItemEditController.h"
#import "FSCalItemAdditions.h"
#import "FSCalendarsManager.h"
#import "FSDefaultAlarms.h"

@implementation FSItemEditController

#pragma mark -
#pragma mark Shared controllers

static FSItemEditController* sharedEventEditController = nil;

+(FSItemEditController*)sharedEventEditController
{
	if(sharedEventEditController == nil)
		sharedEventEditController = [[FSItemEditController alloc] initWithNibName:@"EventEditView" bundle:nil];
	
	return sharedEventEditController;
}

static FSItemEditController* sharedTaskEditController = nil;

+(FSItemEditController*)sharedTaskEditController
{
	if(sharedTaskEditController == nil)
		sharedTaskEditController = [[FSItemEditController alloc] initWithNibName:@"TaskEditView" bundle:nil];
	
	return sharedTaskEditController;
}

#pragma mark -
#pragma mark Init

-(void)awakeFromNib
{
	// alarms controller
	[taskDayevAlarmsController setContent:[FSDefaultAlarms defaultTaskDayevAlarms]];
	[normalAlarmsController setContent:[FSDefaultAlarms defaultAlarms]];
	
	// recurrence controller
	NSMutableArray* recurrenceContent = [[NSMutableArray new] autorelease];
	CalRecurrenceEnd* recEnd = [CalRecurrenceEnd recurrenceEndWithOccurrenceCount:NSIntegerMax];
	[recurrenceContent addObject:[[[CalRecurrenceRule alloc] 
								   initDailyRecurrenceWithInterval:1 end:recEnd] autorelease]];
	[recurrenceContent addObject:[[[CalRecurrenceRule alloc] 
								   initWeeklyRecurrenceWithInterval:1 end:recEnd] autorelease]];
	[recurrenceContent addObject:[[[CalRecurrenceRule alloc] 
								   initMonthlyRecurrenceWithInterval:1 end:recEnd] autorelease]];
	[recurrenceContent addObject:[[[CalRecurrenceRule alloc] 
								   initYearlyRecurrenceWithInterval:1 end:recEnd] autorelease]];
	[recurrenceController setContent:recurrenceContent];
	
	// calendars controller
	[calendarsController bind:@"contentArray" 
					 toObject:[FSCalendarsManager sharedManager] 
				  withKeyPath:@"calendars" 
					  options:nil];
	
	// task priorities are bound differently, using an FSPriorityMenuHandler
}

#pragma mark -
#pragma mark Actions

-(IBAction)okAction:(id)sender
{
	FSCalendarsManager* manager = [FSCalendarsManager sharedManager];
	
	[itemsController commitEditing];
	for(CalCalendarItem* calItem in [itemsController content])
		[manager saveItem:calItem];
	
	[self clearItems];
	[[[self view] window] orderOut:self];
}

-(IBAction)cancelAction:(id)sender
{
	
	if(isAdding){
		
		// if canceling during adding, delete the appropriate items
		NSArray* contentCopy = [NSArray arrayWithArray:[itemsController content]];
		[self clearItems];
		for(CalCalendarItem* calItem in contentCopy)
			[[FSCalendarsManager sharedManager] deleteItem:calItem];
		
		[[[self view] window] orderOut:self];
	
	}else{
		
		// if just editing, revert the items to their saved state
		for(CalCalendarItem* calItem in [itemsController content]){
			[calItem revertToSavedState];
		}
			
		[self clearItems];
		[[[self view] window] orderOut:self];
	}
}

-(void)startAddingItems:(NSArray*)newItems
{
	isAdding = TRUE;
	isEditing = FALSE;
	[super displayItems:newItems];
}

-(void)startEditingItems:(NSArray*)newItems
{
	isAdding = FALSE;
	isEditing = TRUE;
	[super displayItems:newItems];
}

@end
