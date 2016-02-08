//
//  FSItemInfoController.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 2.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSItemInfoController.h"


@implementation FSItemInfoController

#pragma mark -
#pragma mark Shared controllers

static FSItemInfoController* sharedEventInfoController = nil;

+(FSItemInfoController*)sharedEventInfoController
{
	if(sharedEventInfoController == nil)
		sharedEventInfoController = [[FSItemInfoController alloc] initWithNibName:@"EventInfoView" bundle:nil];
	
	return sharedEventInfoController;
}

static FSItemInfoController* sharedTaskInfoController = nil;

+(FSItemInfoController*)sharedTaskInfoController
{
	if(sharedTaskInfoController == nil)
		sharedTaskInfoController = [[FSItemInfoController alloc] initWithNibName:@"TaskInfoView" bundle:nil];
	
	return sharedTaskInfoController;
}

#pragma mark -
#pragma mark Init

-(id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	if(self == [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]){
		
		// we want to observe changes happening to calendar events
		// to update the displayed content
		NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
		CalCalendarStore* store = [[FSCalendarsManager sharedManager] calendarStore];
		[nc addObserver:self 
			   selector:@selector(calItemsChanged:) 
				   name:CalEventsChangedExternallyNotification 
				 object:store];
		[nc addObserver:self 
			   selector:@selector(calItemsChanged:) 
				   name:CalEventsChangedNotification 
				 object:store];
		[nc addObserver:self 
			   selector:@selector(calItemsChanged:) 
				   name:CalTasksChangedExternallyNotification 
				 object:store];
		[nc addObserver:self 
			   selector:@selector(calItemsChanged:) 
				   name:CalTasksChangedNotification 
				 object:store];
	}
	
	return self;
}

-(void)awakeFromNib
{
	// manipulate the notes text view
	[notesTextView setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize: NSSmallControlSize]]];
}

#pragma mark -
#pragma mark Event content managment methods

-(void)addItems:(NSArray*)newItems
{
	[itemsController addObjects:newItems];
}

-(void)clearItems
{
	[itemsController removeObjects:[itemsController content]];
}

-(void)displayItems:(NSArray*)newItems
{
	[self clearItems];
	[self addItems:newItems];
	[itemsController setSelectionIndex:0];
}

-(void)calItemsChanged:(NSNotification*)notification
{
	// if the controller is empty, we are not interested
	if([[itemsController content] count] == 0) return;
	
	NSDictionary* userDict = [notification userInfo];
	
	// iterate over a copy of the items in the controller
	NSArray* controllerContentCopy = [[[itemsController content] copy] autorelease];
	
	// go over items that were deleted
	for(NSString* itemUID in ((NSArray*)[userDict valueForKey:CalDeletedRecordsKey])){
		
		// iterate over content items
		for(CalCalendarItem* contentItem in controllerContentCopy){
			if([itemUID isEqualToString:contentItem.uid]){
				[itemsController removeObject:contentItem];
				break;
			}
		}
	}
	
	// if the controller is empty, close it
	if([[itemsController content] count] == 0)
		[[[self view] window] orderOut:self];
	
	// go over items that were changed
	for(NSString* itemUID in ((NSArray*)[userDict valueForKey:CalUpdatedRecordsKey])){
		
		// iterate over content items
		for(CalCalendarItem* contentItem in controllerContentCopy){
			if([itemUID isEqualToString:contentItem.uid]){
				
				// we need to re-fetch the whole content array
				
				// remember the index of the selection
				NSInteger selection = [itemsController selectionIndex];
				
				NSArray* content = (NSArray*)[itemsController content];
				NSMutableArray* newContent = 
					[[[NSMutableArray alloc] initWithCapacity:[content count]] autorelease];
				
				// refresh the data
				for(CalCalendarItem* item in content){
					CalCalendarItem* updatedItem = [[FSCalendarsManager sharedManager] updatedItem:item];
					if(updatedItem != nil)
						[newContent addObject:updatedItem];
				}
				
				// set the fresh data on the controller
				[itemsController removeObjects:content];
				[itemsController addObjects:newContent];
				[itemsController setSelectionIndex:selection];
					
				// there is nothing more to do here
				return;
			}
		}
	}
}

#pragma mark -
#pragma mark Ops

-(IBAction)openSelectedItemURL:(id)sender
{
	CalCalendarItem* item = [[itemsController selectedObjects] objectAtIndex:0];
	NSURL* url = item.url;
	[[NSWorkspace sharedWorkspace] openURL:url];
}

#pragma mark -
#pragma mark NSTableView delegation methods (for non selectable tables)

- (NSIndexSet *)tableView:(NSTableView *)tableView 
selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
	return nil;
}

@end
