//
//  FSItemInfoController.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 2.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>
#import "FSCalendarsManager.h"

@interface FSItemInfoController : NSViewController {

	IBOutlet NSTextView* notesTextView;
	IBOutlet NSArrayController* itemsController;
}

+(FSItemInfoController*)sharedEventInfoController;
+(FSItemInfoController*)sharedTaskInfoController;

-(IBAction)openSelectedItemURL:(id)sender;

-(void)addItems:(NSArray*)newItems;
-(void)clearItems;
-(void)displayItems:(NSArray*)newItems;

@end
