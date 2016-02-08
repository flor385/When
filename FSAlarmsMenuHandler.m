//
//  FSAlarmsMenuHandler.m
//  When
//
//  Created by Florijan Stamenkovic on 2010 07 26.
//  Copyright 2010 FloCo. All rights reserved.
//

#import "FSAlarmsMenuHandler.h"
#import "FSDefaultAlarms.h"
#import <CalendarStore/CalendarStore.h>
#import "FSDialsViewController.h"
#import "FSCalAlarmAdditions.h"

@implementation FSAlarmsMenuHandler

-(BOOL)handlingTaskDayevEvents
{
	return NO;
}

-(void)awakeFromNib
{
	// we need to initialize the menu
	
	// first have some alarms that we will use
	NSArray* defaultAlarms = [self handlingTaskDayevEvents] ? [FSDefaultAlarms defaultTaskDayevAlarms] :
		[FSDefaultAlarms defaultAlarms];
	
	// now fill up the menu with items representing alarms
	NSMutableArray* tempAlarmItems = [[NSMutableArray new] autorelease];
	for(CalAlarm* alarm in defaultAlarms){
		
		NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:[self handlingTaskDayevEvents] ? 
							[alarm taskDayevDescription] : [alarm normalEventDescription] 
													  action:@selector(alarmMenuItemAction:) 
											   keyEquivalent:@""];
		[item setRepresentedObject:alarm];
		[item setTarget:self];
		
		[tempAlarmItems addObject:item];
	}
	
	defaultAlarmMenuItems = [[NSArray arrayWithArray:tempAlarmItems] retain];
}

- (void)menuNeedsUpdate:(NSMenu*)m
{
	// first remove all the items in the menu, and populate it again with the standard items
	NSArray* menuItems = [m itemArray];
	for(NSMenuItem* menuItem in menuItems)
		[m removeItem:menuItem];
	for(NSMenuItem* menuItem in defaultAlarmMenuItems)
		[m addItem:menuItem];
	
	// get the selected calendar items
	NSArray* calItems = calItemsController == nil ? [FSDialsViewController selectionCalItems] : 
		[calItemsController selectedObjects];
	
	// we need two sets:
	// one containing all the alarms that used in the selected items, and present in the menu
	// the other containing all the alarms that are used in the selected items, and NOT present in the menu
	
	NSMutableSet* inMenuAlarms = [[NSMutableSet new] autorelease];
	NSMutableSet* noMenuAlarms = [[NSMutableSet new] autorelease];
	NSArray* defaultAlarms = [self handlingTaskDayevEvents] ? [FSDefaultAlarms defaultTaskDayevAlarms] :
		[FSDefaultAlarms defaultAlarms];
	
	// now we go through the selected items
	for(CalCalendarItem* item in calItems){
		
		// the alarms of the calendar item
		NSArray* alarms = item.alarms;
		
		// each cal item can have multiple alarms, deal with that
		if([alarms count] == 1){
			CalAlarm* alarm = [alarms objectAtIndex:0];
			if([defaultAlarms containsObject:alarm])
				[inMenuAlarms addObject:alarm];
			else
				[noMenuAlarms addObject:alarm];
		}else if([alarms count] > 1)
			[noMenuAlarms addObject:alarms];
	}
	
	// now we have sorted the alarms of the selected items
	// all that's left if to update the menu items accordingly
	BOOL multipleAlarms = ([noMenuAlarms count] + [inMenuAlarms count]) > 1;
	
	// first deal with existing menu items
	for(NSMenuItem* alarmMenuItem in [m itemArray]){
		if([inMenuAlarms containsObject:[alarmMenuItem representedObject]])
			[alarmMenuItem setState:(multipleAlarms ? NSMixedState : NSOnState)];
		else
			[alarmMenuItem setState:NSOffState];
	}
	
	// now add menu items to represnte alarms that are not standard ones
	if([noMenuAlarms count] != 0){
		
		// first a separator!
		[m addItem:[NSMenuItem separatorItem]];
		
		// now the items representing alarms
		for(NSObject* alarmSet in noMenuAlarms)
			
			if([alarmSet isKindOfClass:[NSArray class]]){
				// we have a set of alarms, so just represent as suck
				NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:@"Multiple alarms" 
															  action:@selector(alarmMenuItemAction:) 
													   keyEquivalent:@""];
				[item setTarget:self];
				[item setRepresentedObject:alarmSet];
				[item autorelease];
				[item setState:NSOnState];
				[m addItem:item];
				
			}else{
				// we have a single alarm
				// we have a set of alarms, so just represent as suck
				CalAlarm* alarm = (CalAlarm*)alarmSet;
				NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:[self handlingTaskDayevEvents] ? 
									[alarm taskDayevDescription] : [alarm normalEventDescription] 
															  action:@selector(alarmMenuItemAction:) 
													   keyEquivalent:@""];
				[item setTarget:self];
				[item setRepresentedObject:alarm];
				[item autorelease];
				[item setState:NSOnState];
				[m addItem:item];
			}
	}
}

-(IBAction)alarmMenuItemAction:(id)sender
{
	// get the priority represented by the menu item
	NSMenuItem* menuItem = sender;
	NSObject* representedItem = [menuItem representedObject];
	NSArray* alarms = [representedItem isKindOfClass:[NSArray class]] ? 
		representedItem : [NSArray arrayWithObject:representedItem];
	
	// set the alarms on the cal items in question
	// if the outlet is set, use it, otherwise use the general selection
	NSArray* calItems = calItemsController == nil ? 
		[FSDialsViewController selectionCalItems] : [calItemsController selectedObjects];
	for(CalCalendarItem* item in calItems){
		if([item.alarms isEqualToArray:alarms]) continue;
		item.alarms = alarms;
		
		// apply changes immediately only if the items controller is nil
		if(calItemsController == nil)
			[[FSCalendarsManager sharedManager] saveItem:item];
	}
}

@end
