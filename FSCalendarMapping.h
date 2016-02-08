//
//  FSCalendarMapping.h
//  CalendarOrdering
//
//  Created by Florijan Stamenkovic on 2009 06 11.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalCalendar.h>
#import <CalendarStore/CalCalendarStore.h>

@interface FSCalendarMapping : NSObject  <NSCoding> {

	CalCalendar* calendar;
	NSNumber* enabled;
}

@property(retain) CalCalendar* calendar;
@property(retain) NSNumber* enabled;

-(id)initWithCalendar:(CalCalendar*)cal isEnabled:(BOOL)isEnabled;

@end
