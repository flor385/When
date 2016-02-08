//
//  FSCalendarsMenuHandler.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 9.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>
#import "FSCalendarsManager.h"
#import "FSCalendarMapping.h"

@interface FSCalendarsMenuHandler : NSObject {

}

-(IBAction)calendarMenuItemAction:(id)sender;
-(void)populateCalendarsMenu:(NSMenu*)menu forItems:(NSArray*)calItems;
-(BOOL)calendar:(CalCalendar*)calendar isPresentInSetOfUIDs:(NSSet*)calendarUIDs;

@end
