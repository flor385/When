//
//  FSWhenTime.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 22.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSWhenTime.h"
#import "FSSound.h"

@implementation FSWhenTime

// we need to track the representation od 24 hours at 0 offset (current date)
// to see when we need to move forward
static FSTimeInterval* zeroOffsetTimeInterval;

// also track the 'current time', updated at a one minute resolution
static NSCalendarDate* currentTime;

// track this info as we use it a lot
static int dayStartHours;
static int dayStartMinutes;

+ (void)initialize
{
    if(self == [FSWhenTime class]){
        
		// we need to track day start time user defaults
		NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
		dayStartHours = [ud integerForKey:FSDayStartTimeHourPreference];
		dayStartMinutes = [ud integerForKey:FSDayStartTimeMinutePreference];
		
		[ud addObserver:self 
			 forKeyPath:FSDayStartTimeHourPreference 
				options:NSKeyValueObservingOptionNew 
				context:nil];
		[ud addObserver:self 
			 forKeyPath:FSDayStartTimeMinutePreference 
				options:NSKeyValueObservingOptionNew 
				context:nil];
		
		// receive notifications of the computer waking up from sleep,
		// to immediately update the waking
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self 
															   selector:@selector(workspaceDidWake:)
																   name:NSWorkspaceDidWakeNotification 
																 object:nil];
		
		// init the times
		currentTime = [[NSCalendarDate date] retain];
		zeroOffsetTimeInterval = [[FSWhenTime intervalForDayOffset:0 useWhenDayStart:YES] retain];
	}
}

+(int)dayStartHours{
	return dayStartHours;
}

+(int)dayStartMinutes{
	return dayStartMinutes;
}

+(void)observeValueForKeyPath:(NSString *)keyPath
					 ofObject:(id)object
					   change:(NSDictionary *)change
					  context:(void *)context
{
	
	// day start hour pref changed
	if([FSDayStartTimeHourPreference isEqualToString:keyPath] 
	   || [FSDayStartTimeMinutePreference isEqualToString:keyPath]){
		
		// update the cached day start
		NSUserDefaults* ud = (NSUserDefaults*)object;
		dayStartHours = [ud integerForKey:FSDayStartTimeHourPreference];
		dayStartMinutes = [ud integerForKey:FSDayStartTimeMinutePreference];
		
		// update the zero offset
		[zeroOffsetTimeInterval release];
		zeroOffsetTimeInterval = [[FSWhenTime intervalForDayOffset:0 useWhenDayStart:YES] retain];
		
		// clear the normal event cache, and then recache
		[[FSCalendarsManager sharedManager] clearNormalEventCaches:nil];
		int lowOffset = [FSDialsViewController lowestOffset] - FS_OFFSET_LOOK_AHEAD;
		int highOffset = [FSDialsViewController highestOffset] + FS_OFFSET_LOOK_AHEAD;
		FSRange updateRange = [FSWhenUtil rangeWithLoc:lowOffset lenght:highOffset - lowOffset + 1];
		[[FSCalendarsManager sharedManager] updateNormalEventCaches:updateRange];
		
		// make the views re-draw themselves
		for(FSDialsView* dialsView in [FSDialsViewController allCurrentDialViewsSorted]){
			[dialsView updateElapsedTimeGeometry];
			[dialsView updateEventGeometry];
			[dialsView updateEventFadeGeometry];
			[dialsView setNeedsDisplay:YES];
		}
	}
}

+(NSCalendarDate*)currentTime
{
	return currentTime;
}

#pragma mark -
#pragma mark Logic

+(void)startWhenTimer
{
	[NSTimer scheduledTimerWithTimeInterval:60.0f 
									 target:self 
								   selector:@selector(timerFireMethod:) 
								   userInfo:nil 
									repeats:YES];
}

+(void)timerFireMethod:(NSTimer*)theTimer
{
	[self updateWhenTime];
}

+(void)workspaceDidWake:(NSNotification*)n
{
	[self updateWhenTime];
}

+(void)updateWhenTime
{
	NSDate* previousCurrentTime = [currentTime autorelease];
	currentTime = [[NSCalendarDate date] retain];
	
	FSTimeInterval* previousZeroOffsetTimeInterval = [zeroOffsetTimeInterval autorelease];
	zeroOffsetTimeInterval = [[FSWhenTime intervalForDayOffset:0 useWhenDayStart:YES] retain];
	
	// we need to find out how many when day boundaries have passed since last update
	// if more then 24 hours have passed, for sure we passed some
	NSTimeInterval diff = [currentTime timeIntervalSinceDate:previousCurrentTime];
	long whenDaysPassed = ((long)diff) / (24 * 3600);
	
	// but maybe we passed a when day boundary without 24 hours having elapsed
	// this depends on how much time was left in the when day
	NSTimeInterval timeRemainingInPreviousWhenDay = 
		[[previousZeroOffsetTimeInterval endDate] timeIntervalSinceDate:previousCurrentTime];
	// it also depends on how much 
	if( diff - (whenDaysPassed * (24 * 3600)) > timeRemainingInPreviousWhenDay )
		whenDaysPassed++;
	
	// we also need to know how many normal day boundaries have passed since last update
	long normalDaysPassed = ((long)diff) / (24 * 3600);
	
	NSTimeInterval timeRemainingInPreviousDay = timeRemainingInPreviousWhenDay + (dayStartHours * 3600) + (dayStartMinutes * 60);
	if( diff - (normalDaysPassed * (24 * 3600)) > timeRemainingInPreviousDay )
		normalDaysPassed++;
	
	// two important booleans
	BOOL enteredNewWhenDay = whenDaysPassed != 0;
	BOOL enteredNewNormalDay = normalDaysPassed != 0;
	
	// based on this information we need to update cal item caches
	if(enteredNewWhenDay)
		[[FSCalendarsManager sharedManager] shiftNormalEventCacheOffsetsBy:-whenDaysPassed];
	if(enteredNewNormalDay)
		[[FSCalendarsManager sharedManager] shiftTaskDayevCacheOffsetsBy:-normalDaysPassed];
	
	// if we are entering a new day, either way, do a  full view update
	if(enteredNewWhenDay || enteredNewNormalDay){
		for(FSDialsView* view in [FSDialsViewController allCurrentDialViewsSorted]){
			[view updateAllGeometry];
			[view setNeedsDisplay:YES];
		}
		
		// otherwise we just need to update the elapsed time stuff of view for offset 0
	}else{
		
		FSDialsViewController* zeroOffsetController = [FSDialsViewController existingControllerWithOffset:0];
		FSDialsView* zeroOffsetView = (FSDialsView*)[zeroOffsetController view];
		[zeroOffsetView updateElapsedTimeGeometry];
		[zeroOffsetView setNeedsDisplay:YES];
	}
	
	// play sounds if necessary
	[[FSSound sharedSound] playSoundFor:currentTime isStartOfDay:enteredNewWhenDay];
}

/*
 
 This is the old version of the updateWhenTime method. It does not deal with skipping time periods greater then
 one minute (when for example waking from sleep), so it needed to be updated. It is kept here for reference in
 case the new method turns out flawed (the old version is functional in every other respect).
 
*/
+(void)updateWhenTime2
{
	// see what date we are on at the moment
	[currentTime release];
	currentTime = [[NSCalendarDate date] retain];
	
	BOOL enteredNewWhenDay = ![zeroOffsetTimeInterval contains:currentTime];
	BOOL enteredNewDay = [currentTime minuteOfHour] == 0 && [currentTime hourOfDay] == 0;
	
	// shift offsets in task dayev caches if we have entered a new day
	if(enteredNewDay)
		[[FSCalendarsManager sharedManager] shiftTaskDayevCacheOffsetsBy:-1];
	
	// if we have entered a new when day, sfit normal caches
	// and update the time interval
	if(enteredNewWhenDay){
		[[FSCalendarsManager sharedManager] shiftNormalEventCacheOffsetsBy:-1];
		
		[zeroOffsetTimeInterval release];
		zeroOffsetTimeInterval = [[FSWhenTime intervalForDayOffset:0 useWhenDayStart:YES] retain];
	}
	
	// if we are entering a new day, either way, do a  full view update
	if(enteredNewWhenDay || enteredNewDay){
		for(FSDialsView* view in [FSDialsViewController allCurrentDialViewsSorted]){
			[view updateAllGeometry];
			[view setNeedsDisplay:YES];
		}
		
		// otherwise we just need to update the elapsed time stuff of view for offset 0
	}else{
		
		FSDialsViewController* zeroOffsetController = [FSDialsViewController existingControllerWithOffset:0];
		FSDialsView* zeroOffsetView = (FSDialsView*)[zeroOffsetController view];
		[zeroOffsetView updateElapsedTimeGeometry];
		[zeroOffsetView setNeedsDisplay:YES];
	}
	
	// play sounds if necessary
	[[FSSound sharedSound] playSoundFor:currentTime isStartOfDay:enteredNewWhenDay];
}

+(FSTimeInterval*)intervalForDayOffset:(int)offset useWhenDayStart:(BOOL)useWhenDayStart
{
	// figure hours and minutes out based on the use when day start flag
	int hours = 0;
	int minutes = 0;
	if(useWhenDayStart){
		hours = dayStartHours;
		minutes = dayStartMinutes;
	}
	
	NSCalendarDate* now = currentTime;
	
	// if the current moment is before day start, we need to return the day interval
	// for the date before today, the easiest way is to just reduce the offset by 1
	if([now hourOfDay] < hours || ([now hourOfDay] == hours && [now minuteOfHour] < minutes))
		offset--;
	
	NSCalendarDate* start = [NSCalendarDate dateWithYear:[now yearOfCommonEra] 
												   month:[now monthOfYear] 
													 day:[now dayOfMonth] 
													hour:hours 
												  minute:minutes 
												  second:00 timeZone:nil];
	start = [start dateByAddingYears:0 months:0 days:offset hours:0 minutes:0 seconds:0];
	NSDate* end = [start dateByAddingYears:0 months:0 days:0 hours:24 minutes:0 seconds:0];
	
	FSTimeInterval* rVal = [[FSTimeInterval alloc] initWithStart:start startInclusive:YES end:end endInclusive:NO];
	[rVal autorelease];
	return rVal;
}

+(FSTimeInterval*)intervalForDayOffset:(int)offset earlierHalf:(BOOL)earlierHalf
{
	NSCalendarDate* now = currentTime;
	int hours = dayStartHours;
	int minutes = dayStartMinutes;
	
	// if the current moment is before day start, we need to return the day interval
	// for the date before today, the easiest way is to just reduce the offset by 1
	if([now hourOfDay] < hours || ([now hourOfDay] == hours && [now minuteOfHour] < minutes))
		offset--;
	
	if(!earlierHalf)
		hours += 12;
	
	
	NSCalendarDate* start = [NSCalendarDate dateWithYear:[now yearOfCommonEra] 
												   month:[now monthOfYear] 
													 day:[now dayOfMonth] 
													hour:hours 
												  minute:minutes 
												  second:00 timeZone:nil];
	start = [start dateByAddingYears:0 months:0 days:offset hours:0 minutes:0 seconds:0];
	NSDate* end = [start dateByAddingYears:0 months:0 days:0 hours:12 minutes:0 seconds:0];
	
	FSTimeInterval* rVal = [[FSTimeInterval alloc] initWithStart:start startInclusive:YES end:end endInclusive:NO];
	[rVal autorelease];
	return rVal;
}

+(NSCalendarDate*)calendarDateForOffset:(int)offset
{
	NSCalendarDate* now = currentTime;
	
	// if the current moment is before day start, we need to return the day interval
	// for the date before today, the easiest way is to just reduce the offset by 1
	if([now hourOfDay] < dayStartHours || ([now hourOfDay] == dayStartHours && [now minuteOfHour] < dayStartMinutes))
		offset--;

	NSCalendarDate* rVal = [now dateByAddingYears:0 months:0 days:offset hours:0 minutes:0 seconds:-[now secondOfMinute]];
	return rVal;
}

+(NSCalendarDate*)offsetStart:(int)offset useWhenDayStart:(BOOL)useWhenDayStart
{
	// figure hours and minutes out based on the use when day start flag
	int hours = 0;
	int minutes = 0;
	if(useWhenDayStart){
		hours = dayStartHours;
		minutes = dayStartMinutes;
	}
	
	NSCalendarDate* now = currentTime;
	
	// if the current moment is before day start, we need to return the day interval
	// for the date before today, the easiest way is to just reduce the offset by 1
	if([now hourOfDay] < hours || ([now hourOfDay] == hours && [now minuteOfHour] < minutes))
		offset--;
	
	NSCalendarDate* start = [NSCalendarDate dateWithYear:[now yearOfCommonEra] 
												   month:[now monthOfYear] 
													 day:[now dayOfMonth] 
													hour:hours 
												  minute:minutes 
												  second:00 timeZone:nil];
	return [start dateByAddingYears:0 months:0 days:offset hours:0 minutes:0 seconds:0];
}

+(int)offsetForDate:(NSDate*)date useWhenDayStart:(BOOL)useWhenDayStart
{
	// the amount of seconds the given date is from the start of interval at offset 0
	NSDate* startOfOffsetZero = [FSWhenTime intervalForDayOffset:0 useWhenDayStart:useWhenDayStart].startDate;
	NSTimeInterval timeSinceStartOfOffsetZero = [date timeIntervalSinceDate:startOfOffsetZero];
	
	int offsetSeconds = (int)timeSinceStartOfOffsetZero;
	int offsetDays = offsetSeconds / 86400;
	
	if(offsetSeconds % 86400 < 0) offsetDays--;
	
	return offsetDays;
}

+(FSTimeInterval*)intervalForOffsetRange:(FSRange)range useWhenDayStart:(BOOL)useWhenDayStart
{
	// figure hours and minutes out based on the use when day start flag
	int hours = 0;
	int minutes = 0;
	if(useWhenDayStart){
		hours = dayStartHours;
		minutes = dayStartMinutes;
	}
	
	NSCalendarDate* now = currentTime;
	
	// if the current moment is before day start, we need to return the day interval
	// for the date before today, the easiest way is to just reduce the offset by 1
	if([now hourOfDay] < hours || ([now hourOfDay] == hours && [now minuteOfHour] < minutes))
		range.location--;
	
	NSCalendarDate* start = [NSCalendarDate dateWithYear:[now yearOfCommonEra] 
												   month:[now monthOfYear] 
													 day:[now dayOfMonth] 
													hour:hours 
												  minute:minutes 
												  second:00 timeZone:nil];
	start = [start dateByAddingYears:0 months:0 days:range.location hours:0 minutes:0 seconds:0];
	NSDate* end = [start dateByAddingYears:0 months:0 days:(range.length) hours:0 minutes:0 seconds:0];
	
	FSTimeInterval* rVal = [[FSTimeInterval alloc] initWithStart:start startInclusive:YES end:end endInclusive:NO];
	[rVal autorelease];
	return rVal;
}

+(FSRange)offsetRangeForEvent:(CalEvent*)event useWhenDayStart:(BOOL)useWhenDayStart
{
	// get the offset location
	int startDateOffset = [FSWhenTime offsetForDate:event.startDate useWhenDayStart:useWhenDayStart];
	
	// we need the offset for the end of the event
	// but seeing how the end date of an event is not included in it's time period
	// we imitate that by shaving off a second
	NSDate* endDateShaved = [[NSDate alloc] initWithTimeInterval:-1.0f sinceDate:event.endDate];
	int endDateOffset = [FSWhenTime offsetForDate:endDateShaved useWhenDayStart:useWhenDayStart];
	[endDateShaved release];
	
	return [FSWhenUtil rangeWithLoc:startDateOffset lenght:endDateOffset - startDateOffset + 1];
}

static NSDateFormatter* dateFormatter = nil;

+(NSString*)formattedDate:(NSDate*)date
{
	if(dateFormatter == nil){
		dateFormatter = [NSDateFormatter new];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
	}
		
	return [dateFormatter stringFromDate:date];
}

@end