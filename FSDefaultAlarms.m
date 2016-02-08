//
//  FSDefaultAlarms.m
//  When
//
//  Created by Florijan Stamenkovic on 2010 07 26.
//  Copyright 2010 FloCo. All rights reserved.
//

#import "FSDefaultAlarms.h"
#import <CalendarStore/CalendarStore.h>


@implementation FSDefaultAlarms

static NSArray* defaultAlarms;
static NSArray* defaultTaskDayevAlarms;

+(NSArray*)defaultAlarms
{
	if(defaultAlarms == nil){
		
		NSMutableArray* alarms = [[NSMutableArray new] autorelease];
		CalAlarm* alarm = [CalAlarm alarm];
		alarm.relativeTrigger = (NSTimeInterval)-900.0f;
		[alarms addObject:alarm];
		[alarm release];
		alarm = [CalAlarm alarm];
		alarm.relativeTrigger = (NSTimeInterval)-3600.0f;
		[alarms addObject:alarm];
		[alarm release];
		alarm = [CalAlarm alarm];
		alarm.relativeTrigger = (NSTimeInterval)-86400.0f;
		[alarms addObject:alarm];
		[alarm release];
		
		defaultAlarms = [[NSArray arrayWithArray:alarms] retain];
	}
	
	return defaultAlarms;
}

+(NSArray*)defaultTaskDayevAlarms
{
	if(defaultTaskDayevAlarms == nil){
		
		NSMutableArray* alarms = [[NSMutableArray new] autorelease];
		CalAlarm* alarm = [CalAlarm alarm];
		alarm.relativeTrigger = (NSTimeInterval)-43200.00f;
		[alarms addObject:alarm];
		[alarm release];
		alarm = [CalAlarm alarm];
		alarm.relativeTrigger = (NSTimeInterval)-129600.00f;
		[alarms addObject:alarm];
		[alarm release];
		
		defaultTaskDayevAlarms = [[NSArray arrayWithArray:alarms] retain];
	}
	
	return defaultTaskDayevAlarms;
}

@end
