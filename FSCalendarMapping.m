//
//  FSCalendarMapping.m
//  CalendarOrdering
//
//  Created by Florijan Stamenkovic on 2009 06 11.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSCalendarMapping.h"


@implementation FSCalendarMapping

@synthesize calendar;
@synthesize enabled;

-(id)initWithCalendar:(CalCalendar*)cal isEnabled:(BOOL)isEnabled
{
	[super init];
	calendar = [cal retain];
	enabled = [[NSNumber numberWithBool:isEnabled] retain];
	return self;
}

-(id)initWithCoder:(NSCoder*)coder
{
	[super init];
	
	NSString* calID = [coder decodeObjectForKey:@"calID"];
	CalCalendarStore* calStore = [CalCalendarStore defaultCalendarStore];
	
	self.calendar = [calStore calendarWithUID:calID];
	self.enabled = [coder decodeObjectForKey:@"calEnabled"];
	
	return self;
}

-(void)encodeWithCoder:(NSCoder*)coder{
	[coder encodeObject:calendar.uid forKey:@"calID"];
	[coder encodeObject:enabled forKey:@"calEnabled"];
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"CalendarMapping for calendar:\n\t%@,\nenabled:%@\n", calendar, enabled];
}

-(void)dealloc
{
	[calendar release];
	[enabled release];
	[super dealloc];
}

@end
