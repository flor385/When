//
//  FSCalCalendarAdditions.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 12.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>

@interface CalCalendar (FSCalCalendarAdditions)

-(BOOL)saveChangesToSelf;
-(BOOL)deleteSelf;
-(void)revertToSavedState;

-(NSString*)typeString;

@end
