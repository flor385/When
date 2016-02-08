//
//  FSCalTaskAdditions.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 26.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>
#import "FSCalendarsManager.h"

@interface CalTask (FSCalTaskAdditions)

-(NSComparisonResult)compare:(CalTask*)task;
-(NSString*)priorityString;

@end
