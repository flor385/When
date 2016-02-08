//
//  FSCalCalendarAdditions.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 12.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSCalCalendarAdditions.h"
#import "FSCalendarsManager.h"

@implementation CalCalendar (FSCalCalendarAdditions)

-(BOOL)saveChangesToSelf
{
	// save it
	NSError* error;
	
	if(![[FSCalendarsManager sharedManager].calendarStore saveCalendar:self error:&error]){
		
		// an error ocurred, inform the user
		NSAlert *theAlert = [NSAlert alertWithError:error];
		[theAlert runModal];
		
		// revert to saved state
		[self revertToSavedState];
		return NO;
	}
	
	return YES;
}

-(BOOL)deleteSelf
{
	NSError* error;
	
	if(![[FSCalendarsManager sharedManager].calendarStore removeCalendar:self error:&error]){
		NSAlert *theAlert = [NSAlert alertWithError:error];
		[theAlert runModal];
		
		return NO;
	}
	
	return YES;
}

-(void)revertToSavedState
{
	CalCalendarStore* calendarStore = [FSCalendarsManager sharedManager].calendarStore;
	CalCalendar* savedState = [calendarStore calendarWithUID:self.uid];
	
	// if we don't have it, we can't revert
	if(savedState == nil)
		return;
	
	self.title = savedState.title;
	self.color = savedState.color;
	self.notes = savedState.notes;
}

-(NSString*)typeString
{
	NSString* type = [self type];
	
	if([CalCalendarTypeBirthday isEqualToString:type])
		return @"Birthday";
	if([CalCalendarTypeCalDAV isEqualToString:type])
		return @"CalDAV";
	if([CalCalendarTypeIMAP isEqualToString:type])
		return @"IMAP";
	if([CalCalendarTypeLocal isEqualToString:type])
		return @"Local";
	if([CalCalendarTypeSubscription isEqualToString:type])
		return @"Subscription";
	
	return @"Unknown";
}

-(NSString*)description
{
	return self.title;
}

@end
