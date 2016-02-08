//
//  FSSound.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 22.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FSSound : NSObject {

	// storage
	NSDictionary* systemSounds;
	NSSound* gong;
	
	// preference values
	NSString* soundOnNewHour;
	NSString* soundOnEventStart;
	BOOL gongOnDayStart;
	NSString* soundBeforeEventStart;
	NSInteger soundBeforeEventStartMinutes;
}

@property(retain) NSString* soundOnNewHour;
@property(retain) NSString* soundOnEventStart;
@property BOOL gongOnDayStart;
@property(retain) NSString* soundBeforeEventStart;
@property NSInteger soundBeforeEventStartMinutes;


+(FSSound*)sharedSound;

-(void)playGong;
-(void)playSound:(NSString*)soundName;
-(void)playSoundFor:(NSCalendarDate*)currentTime isStartOfDay:(BOOL)startOfDay;
-(NSArray*)systemSoundNames;

@end
