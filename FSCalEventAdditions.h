//
//  FSCalEventAdditions.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 22.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>
#import "FSCalendarsManager.h"
#import "FSTimeInterval.h"

@interface CalEvent (FSCalEventAdditions)

-(NSComparisonResult)compare:(CalEvent*)event;
-(BOOL)intersects:(CalEvent*)event;

@end
