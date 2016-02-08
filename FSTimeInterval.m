//
//  FSTimeInterval.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 22.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSTimeInterval.h"


@implementation FSTimeInterval

@synthesize startDate;
@synthesize endDate;
@synthesize startInclusive;
@synthesize endInclusive;

+(FSTimeInterval*)eventInterval:(CalEvent*)event
{
	FSTimeInterval* rVal = [[FSTimeInterval alloc] initWithStart:event.startDate 
												  startInclusive:YES 
															 end:event.endDate 
													endInclusive:NO];
	[rVal autorelease];
	return rVal;
}

-(id)initWithStart:(NSDate*)start 
	startInclusive:(BOOL)startIncl 
			   end:(NSDate*)end 
	  endInclusive:(BOOL)endIncl
{
	[super init];
	
	// check that we have not nil conditions
	if(start == nil || end == nil)
		[NSException raise:@"Invalid argument exception" 
					format:@"Both start and end date are not allowed to be nil"];
	
	startDate = [start earlierDate:end];
	[startDate retain];
	endDate = [start laterDate:end];
	[endDate retain];
	
	startInclusive = startIncl;
	endInclusive = endIncl;
	
	return self;
}

-(BOOL)intersects:(FSTimeInterval*)anInterval
{
	// we need to cut off the less-then-second parts from dates
	// in order to compare within second precision
	long comparison1 = (long)[self.startDate timeIntervalSince1970];
	long comparison2 = (long)[anInterval.endDate timeIntervalSince1970];
	
	// one side
	BOOL startOK = comparison2 > comparison1 || (comparison1 == comparison2 && self.startInclusive && anInterval.endInclusive);
	
	// the other side
	comparison1 = (long)[self.endDate timeIntervalSince1970];
	comparison2 = (long)[anInterval.startDate timeIntervalSince1970];
	
	BOOL endOK = comparison2 < comparison1 || (comparison1 == comparison2 && self.endInclusive && anInterval.startInclusive);
	
	return startOK && endOK;
}

-(BOOL)intersectsEvent:(CalEvent*)event
{
	// we need to cut off the less-then-second parts from dates
	// in order to compare within second precision
	long intervalStart = (long)[self.startDate timeIntervalSince1970];
	long eventEnd = (long)[event.endDate timeIntervalSince1970];
	
	// one side, remember that event ends are never inclusive
	BOOL startOK = eventEnd > intervalStart;
	
	// the other side
	long intervalEnd = (long)[self.endDate timeIntervalSince1970];
	long eventStart = (long)[event.startDate timeIntervalSince1970];
	
	// rememver that event starts are always inclusive
	BOOL endOK = eventStart < intervalEnd || (intervalEnd == eventStart && self.endInclusive);
	
	return startOK && endOK;
}

-(BOOL)simultaneousStart:(FSTimeInterval*)anInterval
{
	// we need to cut off the less-then-second parts from dates
	// in order to compare within second precision
	long start1 = (long)[self.startDate timeIntervalSince1970];
	long start2 = (long)[anInterval.startDate timeIntervalSince1970];
	
	return start1 == start2;
}

-(BOOL)simultaneousEnd:(FSTimeInterval*)anInterval
{
	// we need to cut off the less-then-second parts from dates
	// in order to compare within second precision
	long end1 = (long)[self.endDate timeIntervalSince1970];
	long end2 = (long)[anInterval.endDate timeIntervalSince1970];
	
	return end1 == end2;
}

-(BOOL)contains:(NSDate*)date
{
	long start = (long)[startDate timeIntervalSince1970];
	long end = (long)[endDate timeIntervalSince1970];
	long dateLong = (long)[date timeIntervalSince1970];
	
	BOOL startOK = start < dateLong || (start == dateLong && self.startInclusive);
	BOOL endOK = end > dateLong || (end == dateLong && self.endInclusive);
	return startOK && endOK;
}

-(FSTimeInterval*)unionInterval:(FSTimeInterval*)anInterval
{
	// if the two intervals do not intersect, return nil
	if(![self intersects:anInterval])
		return nil;
	
	// now find the eariler date, and use that as the start date
	NSDate* start = [self.startDate earlierDate:anInterval.startDate];
	
	// end the later, use that as the end date
	NSDate* end = [self.endDate laterDate:anInterval.endDate];
	
	// figure out if the boundaries are included or excluded
	BOOL startIncl = startDate == self.startDate ? self.startInclusive : anInterval.startInclusive;
	BOOL endIncl = endDate == self.endDate ? self.endInclusive : anInterval.endInclusive;
	
	// create an interval that starts with the lower start date, and ends with the later end date
	FSTimeInterval* rVal = [[FSTimeInterval alloc] initWithStart:start 
												  startInclusive:startIncl 
															 end:end 
													endInclusive:endIncl];
	
	[rVal autorelease];
	return rVal;
}

-(FSTimeInterval*)intersectionInterval:(FSTimeInterval*)anInterval
{
	// if the two intervals do not intersect, return nil
	if(![self intersects:anInterval])
		return nil;
	
	// figure out the start and end date of the intersection interval
	NSDate* start = [self.startDate laterDate:anInterval.startDate];
	NSDate* end = [self.endDate earlierDate:anInterval.endDate];
	
	// figure out if the boundaries are included or not
	BOOL startIncl = startDate == self.startDate ? self.startInclusive : anInterval.startInclusive;
	BOOL endIncl = endDate == self.endDate ? self.endInclusive : anInterval.endInclusive;
	
	// create an interval that starts with the lower start date, and ends with the later end date
	FSTimeInterval* rVal = [[FSTimeInterval alloc] initWithStart:start 
												  startInclusive:startIncl 
															 end:end 
													endInclusive:endIncl];
	
	[rVal autorelease];
	return rVal;
}

-(void)dealloc
{
	[startDate release];
	[endDate release];
	[super dealloc];
}

@end
