//
//  FSWhenTime.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 22.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FSPreferencesController.h"
#import "FSTimeInterval.h"
#import "FSDialsView.h"
#import "FSDialsViewController.h"
#import "FSWhenUtil.h"

@interface FSWhenTime : NSObject {

}

+(int)dayStartHours;
+(int)dayStartMinutes;
+(NSCalendarDate*)currentTime;
+(void)startWhenTimer;
+(void)updateWhenTime;

// time for offset methods
+(FSTimeInterval*)intervalForDayOffset:(int)offset useWhenDayStart:(BOOL)useWhenDayStart;
+(FSTimeInterval*)intervalForOffsetRange:(FSRange)range useWhenDayStart:(BOOL)useWhenDayStart;
+(FSTimeInterval*)intervalForDayOffset:(int)offset earlierHalf:(BOOL)earlierHalf;
+(NSCalendarDate*)calendarDateForOffset:(int)offset;
+(NSCalendarDate*)offsetStart:(int)offset useWhenDayStart:(BOOL)useWhenDayStart;

// offset for time methods
+(int)offsetForDate:(NSDate*)date useWhenDayStart:(BOOL)useWhenDayStart;
+(FSRange)offsetRangeForEvent:(CalEvent*)event useWhenDayStart:(BOOL)useWhenDayStart;

// date conversion
+(NSString*)formattedDate:(NSDate*)date;

@end
