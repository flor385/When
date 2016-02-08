//
//  FSTimeInterval.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 22.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>

@interface FSTimeInterval : NSObject {

	NSDate* startDate;
	NSDate* endDate;
	BOOL startInclusive;
	BOOL endInclusive;
}

@property(readonly, retain) NSDate* startDate;
@property(readonly, retain) NSDate* endDate;
@property(readonly) BOOL startInclusive;
@property(readonly) BOOL endInclusive;

+(FSTimeInterval*)eventInterval:(CalEvent*)event;

-(id)initWithStart:(NSDate*)start 
	startInclusive:(BOOL)startIncl 
			   end:(NSDate*)end 
	  endInclusive:(BOOL)endIncl;

-(BOOL)intersects:(FSTimeInterval*)anInterval;
-(BOOL)intersectsEvent:(CalEvent*)event;
-(BOOL)contains:(NSDate*)date;
-(BOOL)simultaneousStart:(FSTimeInterval*)anInterval;
-(BOOL)simultaneousEnd:(FSTimeInterval*)anInterval;
-(FSTimeInterval*)unionInterval:(FSTimeInterval*)anInterval;
-(FSTimeInterval*)intersectionInterval:(FSTimeInterval*)anInterval;

@end
