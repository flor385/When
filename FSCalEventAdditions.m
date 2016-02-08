//
//  FSCalEventAdditions.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 22.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSCalEventAdditions.h"
#import "FSCalItemAdditions.h"

@implementation CalEvent (FSCalEventAdditions)

-(NSComparisonResult)compare:(CalEvent*)event
{
	// first compare them on calendar priority
	int first = [[FSCalendarsManager sharedManager] orderOfCalendar:self.calendar.uid];
	int second = [[FSCalendarsManager sharedManager] orderOfCalendar:event.calendar.uid];
	if(first != second) return first < second ? NSOrderedAscending : NSOrderedDescending;
	
	// the two cal events belong to the same calendar, see which starts first
	NSComparisonResult startResult = [self.startDate compare:event.startDate];
	if(startResult != NSOrderedSame) return startResult;
	
	// they start at the same time, see which ends first, that has priority
	return [self.endDate compare:event.endDate];
}

-(BOOL)intersects:(CalEvent*)event
{
	// we need to cut off the less-then-second parts from dates
	// in order to compare within second precision
	long selfStart = (long)[self.startDate timeIntervalSince1970];
	long eventEnd = (long)[event.endDate timeIntervalSince1970];
	
	// one side, remember that event ends are always exclusive
	BOOL startOK = eventEnd > selfStart;
	
	// the other side
	long selfEnd = (long)[self.endDate timeIntervalSince1970];
	long eventStart = (long)[event.startDate timeIntervalSince1970];
	
	BOOL endOK = eventStart < selfEnd;
	
	return startOK && endOK;
}

-(NSMutableDictionary*)pasteboardDict
{
	NSMutableDictionary* rVal = [super pasteboardDict];
	// skip attendees, recurrence, ocurrence, isDetached, they can't be encoded
	[rVal setValue:self.endDate forKey:@"endDate"];
	[rVal setValue:self.startDate forKey:@"startDate"];
	[rVal setValue:[NSNumber numberWithBool:self.isAllDay] forKey:@"isAllDay"];
	[rVal setValue:self.location forKey:@"location"];
	
	return rVal;
}

-(id)initWithPasteboardDict:(NSDictionary*)pbDict
{
	[super initWithPasteboardDict:pbDict];
	
	self.endDate = [pbDict valueForKey:@"endDate"];
	self.startDate = [pbDict valueForKey:@"startDate"];
	NSNumber* isAllDayNumber = [pbDict valueForKey:@"isAllDay"];
	if(isAllDayNumber)
		self.isAllDay = [isAllDayNumber boolValue];
	self.location = [pbDict valueForKey:@"location"];
	
	return self;
}

@end
