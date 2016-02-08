//
//  FSCalendarsMenuHandler.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 9.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSCalendarsMenuHandler.h"
#import "FSCalItemAdditions.h"

@implementation FSCalendarsMenuHandler

- (void)menuNeedsUpdate:(NSMenu*)menu{
	[self populateCalendarsMenu:menu forItems:[FSDialsViewController selectionCalItems]];
}

-(void)populateCalendarsMenu:(NSMenu*)menu forItems:(NSArray*)calItems
{
	// create a set contaning the UID of all the calendars
	// present in calItems
	NSMutableSet* calUIDs = [[NSMutableSet new] autorelease];
	for(CalCalendarItem* calItem in calItems)
		[calUIDs addObject:calItem.calendar.uid];
	
	// remove all the items from the menu
	for(int i = 0 , c = [menu numberOfItems] ; i < c ; i++)
		[menu removeItemAtIndex:0];
	
	// add an item for each calendar
	NSArray* calMappings = [[FSCalendarsManager sharedManager] calendarMappings];
	for(FSCalendarMapping* mapping in calMappings){
		
		// some stuff we will be needing
		CalCalendar* cal = mapping.calendar;
		NSInteger state = 0;
		if([self calendar:cal isPresentInSetOfUIDs:calUIDs]){
			state = [calUIDs count] > 1 ? NSMixedState : NSOnState;
		}else
			state = NSOffState;
		
		// create and tweak the item
		NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:cal.title 
													  action:@selector(calendarMenuItemAction:) 
											   keyEquivalent:@""];
		[item setState:state];
		[item setTarget:self];
		
		// add  the item to the menu
		[menu addItem:item];
		[item release];
	}
}

-(BOOL)calendar:(CalCalendar*)calendar isPresentInSetOfUIDs:(NSSet*)calendarUIDs
{
	for(NSString* calUID in calendarUIDs){
		if([calendar.uid isEqualToString:calUID])
			return YES;
	}
	
	return NO;
}

-(IBAction)calendarMenuItemAction:(id)sender
{
	// get the calendar represented by the menu
	NSMenuItem* menuItem = sender;
	int calIndex = [[menuItem menu] indexOfItem:menuItem];
	FSCalendarMapping* mapping = [[FSCalendarsManager sharedManager].calendarMappings objectAtIndex:calIndex];
	CalCalendar* calendar = mapping.calendar;
	
	// set the calendar for all the selected items
	for(CalCalendarItem* calItem in [FSDialsViewController selectionCalItems]){
		calItem.calendar = calendar;
		[[FSCalendarsManager sharedManager] saveItem:calItem];
	}
}

@end
