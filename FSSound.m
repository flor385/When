//
//  FSSound.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 22.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSSound.h"
#import "FSPreferencesController.h"
#import "FSTimeInterval.h"
#import "FSCalendarsManager.h"

@implementation FSSound

static FSSound* sharedSound = nil;

+(FSSound*)sharedSound
{
	if(sharedSound == nil)
		sharedSound = [FSSound new];
	
	return sharedSound;
}

@synthesize soundOnNewHour;
@synthesize soundOnEventStart;
@synthesize gongOnDayStart;
@synthesize soundBeforeEventStart;
@synthesize soundBeforeEventStartMinutes;

-(id)init
{
	[super init];
	
	// the gong!
	gong = [[NSSound soundNamed:@"Gong"] retain];
	
	// fill the sounds dict up
	systemSounds = [NSMutableDictionary new];
	NSFileWrapper* systemSoundsFolder = [[NSFileWrapper alloc] initWithPath:@"/System/Library/Sounds/"];
	for(NSFileWrapper* soundFileWrapper in [[systemSoundsFolder fileWrappers] allValues]){
		
		// we only want aiffs
		NSString* fileName = [soundFileWrapper filename];
		if(![fileName hasSuffix:@".aiff"]) continue;
		
		NSString* name = [fileName stringByDeletingPathExtension];
		NSSound* sound = [NSSound soundNamed:name];
		[systemSounds setValue:sound forKey:name];
	}
	
	// bind some values
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[self bind:@"soundOnNewHour" toObject:ud withKeyPath:FSSoundOnNewHour options:nil];
	[self bind:@"soundOnEventStart" toObject:ud withKeyPath:FSSoundOnEventStart options:nil];
	[self bind:@"gongOnDayStart" toObject:ud withKeyPath:FSPlayGongOnNewDay options:nil];
	[self bind:@"soundBeforeEventStart" toObject:ud withKeyPath:FSSoundBeforeEventStart options:nil];
	[self bind:@"soundBeforeEventStartMinutes" toObject:ud withKeyPath:FSSoundBeforeEventStartMinutes options:nil];
	
	return self;
}

-(void)playGong
{
	[gong play];
}

-(void)playSound:(NSString*)soundName
{
	NSSound* sound = [systemSounds objectForKey:soundName];
	[sound play];
}

-(void)playSoundFor:(NSCalendarDate*)currentTime isStartOfDay:(BOOL)startOfDay
{
	// reset the date to 0 seconds
	currentTime = [NSCalendarDate dateWithYear:[currentTime yearOfCommonEra] 
										 month:[currentTime monthOfYear] 
										   day:[currentTime dayOfMonth] 
										  hour:[currentTime hourOfDay]
										minute:[currentTime minuteOfHour] 
										second:0 timeZone:nil];
	
	// if start of day, and a sound should be played, do it!
	if(startOfDay && gongOnDayStart){
		[gong play];
		return;
	}
	
	// sound on new hour
	if(soundOnNewHour && [currentTime minuteOfHour] == 0){
		[self playSound:soundOnNewHour];
		return;
	}
	
	// event start
	if(soundOnEventStart){
		NSDate* end = [[[NSDate alloc] initWithTimeInterval:60.0f sinceDate:currentTime] autorelease];
		FSTimeInterval* interval = [[[FSTimeInterval alloc] initWithStart:currentTime 
														  startInclusive:YES 
																	 end:end 
															endInclusive:NO] autorelease];
		
		if([[FSCalendarsManager sharedManager] thereIsEventStartingInInterval:interval]){
			[self playSound:soundOnEventStart];
			return;
		}
	}
	
	// before event start
	if(soundBeforeEventStart){
		NSDate* start = [[[NSDate alloc] initWithTimeInterval:(60.0f * soundBeforeEventStartMinutes)
													sinceDate:currentTime] autorelease];
		NSDate* end = [[[NSDate alloc] initWithTimeInterval:60.0f sinceDate:start] autorelease];
		FSTimeInterval* interval = [[[FSTimeInterval alloc] initWithStart:start 
														   startInclusive:YES 
																	  end:end 
															 endInclusive:NO] autorelease];
		
		if([[FSCalendarsManager sharedManager] thereIsEventStartingInInterval:interval]){
			[self playSound:soundBeforeEventStart];
			return;
		}
	}
}

-(NSArray*)systemSoundNames
{
	return [systemSounds allKeys];
}

-(void)dealloc
{
	[systemSounds release];
	[gong release];
	[super dealloc];
}

@end
