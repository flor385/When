//
//  FSPriorityMenuHandler.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 13.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>
#import "FSCalendarsManager.h"
#import "FSCalendarMapping.h"

@interface FSPriorityMenuHandler : NSObject {

	IBOutlet NSMenu* menu;
	IBOutlet NSArrayController* calItemsController;
}

-(IBAction)priorityMenuItemAction:(id)sender;

@end