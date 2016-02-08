//
//  FSCalAlarmAdditions.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 14.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSCalAlarmAdditions.h"
#import "FSWhenTime.h"

@implementation CalAlarm (FSCalCalendarAdditions)

#pragma mark -
#pragma mark NSCoding implementation methods

-(id)initWithCoder:(NSCoder*)coder
{
	[super init];
	
	self.absoluteTrigger = [coder decodeObjectForKey:@"absoluteTrigger"];
	self.action = [coder decodeObjectForKey:@"action"];
	self.emailAddress = [coder decodeObjectForKey:@"emailAddress"];
	self.relativeTrigger = [coder decodeFloatForKey:@"relativeTrigger"];
	self.sound = [coder decodeObjectForKey:@"sound"];
	self.url = [coder decodeObjectForKey:@"url"];
	
	return self;
}

-(void)encodeWithCoder:(NSCoder*)coder
{
	[coder encodeObject:self.absoluteTrigger forKey:@"absoluteTrigger"];
	[coder encodeObject:self.action forKey:@"action"];
	[coder encodeObject:self.emailAddress forKey:@"emailAddress"];
	[coder encodeFloat:self.relativeTrigger forKey:@"relativeTrigger"];
	[coder encodeObject:self.sound forKey:@"sound"];
	[coder encodeObject:self.url forKey:@"url"];
}

-(NSString*)description
{
	// first deal with the alarm action
	NSString* action = self.action;
	NSString* actionString;
	
	if([CalAlarmActionDisplay isEqualToString:action])
		actionString = @"Message";
	else if([CalAlarmActionEmail isEqualToString:action])
		actionString = [NSString stringWithFormat:@"Email %@", self.emailAddress];
	else if([CalAlarmActionProcedure isEqualToString:action])
		actionString = [NSString stringWithFormat:@"Open %@", self.url];
	else if([CalAlarmActionSound isEqualToString:action])
		actionString = [NSString stringWithFormat:@"Play %@", self.sound];
	else
		actionString = @"Do nothing";
	
	// now deal with the alarm time
	NSString* triggerString;
	if(self.absoluteTrigger != nil)
		triggerString = [NSString stringWithFormat:@"on %@", [FSWhenTime formattedDate:self.absoluteTrigger]];
	else{
		
		NSTimeInterval interval = self.relativeTrigger;
		double absoluteInterval = interval < 0.0 ? -interval : interval;
		
		NSString* unit;
		NSUInteger amount;
		
		if(absoluteInterval < 60.0){
			// seconds
			unit = @"sec";
			amount = rinttol(absoluteInterval);
			
		}else if(absoluteInterval < 3600.0){
			// minutes
			unit = @"min";
			amount = rinttol(absoluteInterval) / 60;
		
		}else if(absoluteInterval < 86400.0){
			// hours
			unit = @"hrs";
			amount = rinttol(absoluteInterval) / 3600;
		
		}else{
			// days
			unit = @"days";
			amount = rinttol(absoluteInterval) / 86400;
		}
		
		triggerString = [NSString stringWithFormat:@"%d %@ %@", amount, unit, (interval > 0.0 ? @"after" : @"before")];
	}
	
	// concat the two
	return [NSString stringWithFormat:@"%@ %@", actionString, triggerString];
}

-(NSString*)normalEventDescription
{
	return [self description];
}

-(NSString*)taskDayevDescription
{
	// first deal with the alarm action
	NSString* action = self.action;
	NSString* actionString;
	
	if([CalAlarmActionDisplay isEqualToString:action])
		actionString = @"Message";
	else if([CalAlarmActionEmail isEqualToString:action])
		actionString = [NSString stringWithFormat:@"Email %@", self.emailAddress];
	else if([CalAlarmActionProcedure isEqualToString:action])
		actionString = [NSString stringWithFormat:@"Open %@", self.url];
	else if([CalAlarmActionSound isEqualToString:action])
		actionString = [NSString stringWithFormat:@"Play %@", self.sound];
	else
		actionString = @"Do nothing";
	
	// now deal with the alarm time
	NSString* triggerString;
	if(self.absoluteTrigger != nil)
		triggerString = [NSString stringWithFormat:@"on %@", [FSWhenTime formattedDate:self.absoluteTrigger]];
	else{
		
		// some stuff we will need
		long interval = (long)self.relativeTrigger;
		long dayInSeconds = 24 * 3600;
		
		// figure out at which time the alarm will strike, considering it is relative to 00:00
		int hours = (interval % dayInSeconds) / 3600;
		if(hours < 0) hours = 24 + hours;
		int minutes = (interval % 3600) / 60;
		if(minutes < 0 ){
			minutes = 60 + minutes;
			hours = hours == 0 ? 23 : hours - 1;
		}
		
		if(interval == 0)
			@"on date at 00:00";
		else if(interval > 0 && interval < dayInSeconds)
			triggerString = [NSString stringWithFormat:@"the same day at %02d:%02d", hours, minutes];
		else if(interval > dayInSeconds)
			triggerString = [NSString stringWithFormat:@"%d days after at %02d:%02d", interval / dayInSeconds, hours, minutes];
		else if(interval < 0 && -interval < dayInSeconds)
			triggerString = [NSString stringWithFormat:@"the day before at %02d:%02d", hours, minutes];
		else
			triggerString = [NSString stringWithFormat:@"%d days before at %02d:%02d", (-interval / dayInSeconds) + 1,
							 hours, minutes];
	}
	
	// concat the two
	return [NSString stringWithFormat:@"%@ %@", actionString, triggerString];
}

@end
