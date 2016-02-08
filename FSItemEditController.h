//
//  FSItemEditController.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 11.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FSItemInfoController.h"

@interface FSItemEditController : FSItemInfoController {

	IBOutlet NSArrayController* calendarsController;
	IBOutlet NSArrayController* recurrenceController;
	IBOutlet NSArrayController* normalAlarmsController;
	IBOutlet NSArrayController* taskDayevAlarmsController;
	
	BOOL isAdding;
	BOOL isEditing;
}

+(FSItemEditController*)sharedEventEditController;
+(FSItemEditController*)sharedTaskEditController;

-(IBAction)okAction:(id)sender;
-(IBAction)cancelAction:(id)sender;

-(void)startAddingItems:(NSArray*)newItems;
-(void)startEditingItems:(NSArray*)newItems;

@end
