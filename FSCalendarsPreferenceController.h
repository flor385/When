//
//  FSCalendarsPreferenceController.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 12.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MBPreferencesController.h"

@interface FSCalendarsPreferenceController : NSViewController <MBPreferencesModule> {
	
	IBOutlet NSTableView* calendarsTable;
}

+(FSCalendarsPreferenceController*)instance;

-(IBAction)deleteCalendar:(id)sender;

@end