//
//  FSAlarmsMenuHandler.h
//  When
//
//  Created by Florijan Stamenkovic on 2010 07 26.
//  Copyright 2010 FloCo. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FSAlarmsMenuHandler : NSObject {
	
	NSArray* defaultAlarmMenuItems;

	IBOutlet NSArrayController* calItemsController;
}

-(BOOL)handlingTaskDayevEvents;
-(IBAction)alarmMenuItemAction:(id)sender;

@end
