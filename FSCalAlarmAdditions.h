//
//  FSCalAlarmAdditions.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 14.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>

@interface CalAlarm (FSCalCalendarAdditions) <NSCoding>

-(NSString*)normalEventDescription;
-(NSString*)taskDayevDescription;

@end
