//
//  CalItemAdditions.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 9.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSCalItemAdditions.h"


#define FSCalItemTypeEvent 0
#define FSCalItemTypeTask 1

@implementation CalCalendarItem (FSCalItemAdditions)

-(BOOL)saveChangesToSelf
{
	CalCalendarStore* store = [FSCalendarsManager sharedManager].calendarStore;
	
	// the possibly occuring error
	NSError* error;
	
	// try to save self, the process is different for tasks then for events,
	// so check self class first
	if([self isKindOfClass:[CalEvent class]]){
		
		CalEvent* event = (CalEvent*)self;
		
		if(![store saveEvent:event span:[FSPreferencesController spanForEditingEvent:event] error:&error]){
			
			//	failed, notify the user
			NSAlert *theAlert = [NSAlert alertWithError:error];
			[theAlert runModal];
			
			// revert and return
			return NO;
		}
	}else{
		
		CalTask* task = (CalTask*)self;
		if(![store saveTask:task error:&error]){
			
			//	failed, notify the user
			NSAlert *theAlert = [NSAlert alertWithError:error];
			[theAlert runModal];
			
			// revert and return
			return NO;
		}
	}
	
	return YES;
}

-(void)revertToSavedState
{
	CalCalendarStore* calendarStore = [FSCalendarsManager sharedManager].calendarStore;
	
	// events
	if([self isKindOfClass:[CalEvent class]]){
		
		CalEvent* selfEvent = (CalEvent*)self;
		
		// recurrence is tough to deal with, keep trying till we have a hit
		CalEvent* savedState = [calendarStore eventWithUID:self.uid occurrence:selfEvent.occurrence];
		if(savedState == nil)
			savedState = [calendarStore eventWithUID:self.uid occurrence:nil];
		
		// if we don't have it, we can't revert
		if(savedState == nil)
			return;
		
		self.alarms = savedState.alarms;
		self.calendar = [[FSCalendarsManager sharedManager] calendarWithUID:savedState.calendar.uid];
		self.notes = savedState.notes;
		self.title = savedState.title;
		self.url = savedState.url;
		selfEvent.startDate = savedState.startDate;
		selfEvent.endDate = savedState.endDate;
		selfEvent.isAllDay = savedState.isAllDay;
		selfEvent.location = savedState.location;
		selfEvent.recurrenceRule = savedState.recurrenceRule;
		
	// tasks
	}else{
		
		CalTask* selfTask = (CalTask*)self;
		CalTask* savedState = [calendarStore taskWithUID:selfTask.uid];
		
		// if we don't have it, we can't revert
		if(savedState == nil)
			return;
		
		self.alarms = savedState.alarms;
		self.calendar = [[FSCalendarsManager sharedManager] calendarWithUID:savedState.calendar.uid];
		self.notes = savedState.notes;
		self.title = savedState.title;
		self.url = savedState.url;
		selfTask.dueDate = savedState.dueDate;
		selfTask.priority = savedState.priority;
		selfTask.completedDate = savedState.completedDate;
	}
}

-(void)deleteSelf
{
	CalCalendarStore* store = [FSCalendarsManager sharedManager].calendarStore;
	
	// the possibly occuring error
	NSError* error;
	
	// try to save self, the process is different for tasks then for events,
	// so check self class first
	if([self isKindOfClass:[CalEvent class]]){
		CalEvent* event = (CalEvent*)self;
		if(![store removeEvent:event span:[FSPreferencesController spanForDeletingEvent:event] error:&error]){
			//	failed
			NSAlert *theAlert = [NSAlert alertWithError:error];
			[theAlert runModal];
			return;
		}
	}else{
		CalTask* task = (CalTask*)self;
		if(![store removeTask:task error:&error]){
			//	failed
			NSAlert *theAlert = [NSAlert alertWithError:error];
			[theAlert runModal];
			return;
		}
	}
}

-(NSString*)description{
	return self.title;
}

-(NSMutableDictionary*)pasteboardDict
{
	/*
	 This implementation writes only the props common to events and tasks.
	 Subclasses (sub-categories) should override this method to write class specific props.
	 */
	NSMutableDictionary* rVal = [[NSMutableDictionary new] autorelease];
	int type = [self isKindOfClass:[CalEvent class]] ? FSCalItemTypeEvent : FSCalItemTypeTask;
	[rVal setValue:[NSNumber numberWithInt:type] forKey:@"FSCalItemType"];
	[rVal setValue:self.alarms forKey:@"alarms"];
	[rVal setValue:self.calendar.uid forKey:@"calendarUID"];
	[rVal setValue:self.notes forKey:@"notes"];
	[rVal setValue:self.title forKey:@"title"];
	[rVal setValue:self.url forKey:@"url"];
	
	return rVal;
}

-(id)initWithPasteboardDict:(NSDictionary*)pbDict
{
	/*
	 This implementation reads only the props common to events and tasks.
	 Subclasses (sub-categories) should override this method to write class specific props.
	 */
	self.alarms = [pbDict valueForKey:@"alarms"];
	self.calendar = [[FSCalendarsManager sharedManager] calendarWithUID:[pbDict valueForKey:@"calendarUID"]];
	if(self.calendar == nil)
		self.calendar = [[FSCalendarsManager sharedManager] highestPriorityCalendar];
	self.notes = [pbDict valueForKey:@"notes"];
	self.title = [pbDict valueForKey:@"title"];
	self.url = [pbDict valueForKey:@"url"];
	
	return self;
}

+(CalCalendarItem*)calItemForPasteboardDict:(NSDictionary*)pbDict
{
	NSNumber* typeNumber = [pbDict valueForKey:@"FSCalItemType"];
	CalCalendarItem* newItem = [typeNumber intValue] == FSCalItemTypeEvent ? [CalEvent event] : [CalTask task];
	return [newItem initWithPasteboardDict:pbDict];
}

@end
