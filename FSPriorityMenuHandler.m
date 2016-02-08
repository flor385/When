//
//  FSPriorityMenuHandler.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 13.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSPriorityMenuHandler.h"
#import "FSCalItemAdditions.h"

@implementation FSPriorityMenuHandler

-(void)awakeFromNib
{
	// remove all the items from the menu
	for(int i = 0 , c = [menu numberOfItems] ; i < c ; i++)
		[menu removeItemAtIndex:0];
	
	// populate the menu with items representing cal priorities
	// no priority
	NSMenuItem* item = [[[NSMenuItem alloc] initWithTitle:@"None" 
												   action:@selector(priorityMenuItemAction:) 
											keyEquivalent:@""] autorelease];
	[item setTarget:self];
	[menu addItem:item];
	
	// low priority
	item = [[[NSMenuItem alloc] initWithTitle:@"Low" 
												   action:@selector(priorityMenuItemAction:) 
											keyEquivalent:@""] autorelease];
	[item setTarget:self];
	[menu addItem:item];
	
	// medium priority
	item = [[[NSMenuItem alloc] initWithTitle:@"Medium" 
												   action:@selector(priorityMenuItemAction:) 
											keyEquivalent:@""] autorelease];
	[item setTarget:self];
	[menu addItem:item];
	
	// high priority
	item = [[[NSMenuItem alloc] initWithTitle:@"High" 
												   action:@selector(priorityMenuItemAction:) 
											keyEquivalent:@""] autorelease];
	[item setTarget:self];
	[menu addItem:item];
}

- (void)menuNeedsUpdate:(NSMenu*)m
{
	NSArray* calTasks = calItemsController == nil ? [FSDialsViewController selectionCalItems] : [calItemsController selectedObjects];
	
	// create a set contaning the priority of all the teaks
	// present in calTasks
	NSMutableSet* priorities = [[NSMutableSet new] autorelease];
	for(CalTask* task in calTasks)
		[priorities addObject:[NSNumber numberWithInt:task.priority]];
	
	// update the state of the items
	
	// none priority
	int state = [priorities containsObject:[NSNumber numberWithInt:CalPriorityNone]] ?
	([priorities count] > 1 ? NSMixedState : NSOnState) : NSOffState;
	[[menu itemAtIndex:0] setState:state];
	
	// low priority
	state = [priorities containsObject:[NSNumber numberWithInt:CalPriorityLow]] ?
	([priorities count] > 1 ? NSMixedState : NSOnState) : NSOffState;
	[[menu itemAtIndex:1] setState:state];
	
	// medium priority
	state = [priorities containsObject:[NSNumber numberWithInt:CalPriorityMedium]] ?
	([priorities count] > 1 ? NSMixedState : NSOnState) : NSOffState;
	[[menu itemAtIndex:2] setState:state];
	
	// high priority
	state = [priorities containsObject:[NSNumber numberWithInt:CalPriorityHigh]] ?
	([priorities count] > 1 ? NSMixedState : NSOnState) : NSOffState;
	[[menu itemAtIndex:3] setState:state];
}

-(IBAction)priorityMenuItemAction:(id)sender
{
	// get the priority represented by the menu item
	NSMenuItem* menuItem = sender;
	int calIndex = [[sender menu] indexOfItem:menuItem];
	CalPriority priority;
	switch(calIndex){
		case 0 : priority = CalPriorityNone;
			break;
		case 1 : priority = CalPriorityLow;
			break;
		case 2 : priority = CalPriorityMedium;
			break;
		case 3 : priority = CalPriorityHigh;
			break;
	}
	
	// set the priority on the tasks
	// if the outlet is set, use it, otherwise use the general selection
	NSArray* tasks = calItemsController == nil ? [FSDialsViewController selectionCalItems] : [calItemsController selectedObjects];
	for(CalTask* task in tasks){
		if(task.priority == priority) continue;
		task.priority = priority;
		
		// apply changes immediately only if the items controller is nil
		if(calItemsController == nil)
			[[FSCalendarsManager sharedManager] saveItem:task];
	}
}

@end
