//
//  FSAppController.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 13.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>
#import "FSMainWindow.h"
#import "FSDialsView.h"
#import "FSDialsViewController.h"
#import "FSArrayProxyObjectTransformer.h"

@interface FSAppController : NSObject {

	IBOutlet FSMainWindow* mainWindow;
}

#pragma mark Access to the latest (only) instantiated controller
+(FSAppController*)controller;

#pragma mark Exposing some stuff
-(NSInteger)anchorViewOffset;

#pragma mark Dials view adding / removing
-(IBAction)addViewToFront:(id)sender;
-(IBAction)addViewToBack:(id)sender;
-(IBAction)removeFirstDay:(id)sender;
-(IBAction)removeLastDay:(id)sender;

#pragma mark Offset changing
-(IBAction)incrementOffset:(id)sender;
-(IBAction)decrementOffset:(id)sender;
-(IBAction)incrementOffsetByWeek:(id)sender;
-(IBAction)incrementOffsetByMonth:(id)sender;
-(IBAction)decrementOffsetByWeek:(id)sender;
-(IBAction)decrementOffsetByMonth:(id)sender;
-(IBAction)goToToday:(id)sender;
-(IBAction)goToDate:(id)sender;

#pragma mark Event, task and calendar creation
-(IBAction)newEvent:(id)sender;
+(void)newEventWithStartDate:(NSDate*)startDate 
					 endDate:(NSDate*)endDate 
					calendar:(CalCalendar*)calendar 
					dayEvent:(BOOL)dayev;
-(IBAction)newDayEvent:(id)sender;
+(void)newDayEventWithDate:(NSCalendarDate*)date calendar:(CalCalendar*)calendar;
-(IBAction)newTask:(id)sender;
+(void)newTask:(NSCalendarDate*)dueDate calendar:(CalCalendar*)calendar;
-(IBAction)newCalendar:(id)sender;
+(void)newCalendar;

#pragma mark Info, edit, deletion etc
+(IBAction)showSelectedItemInfo;
-(IBAction)showSelectedItemInfo:(id)sender;
+(IBAction)editSelectedItem;
-(IBAction)editSelectedItem:(id)sender;
-(IBAction)deleteSelection:(id)sender;
-(IBAction)cut:(id)sender;
-(IBAction)copy:(id)sender;
-(IBAction)paste:(id)sender;
-(IBAction)duplicate:(id)sender;
+(NSArray*)calItemsFromGeneralPasteboard;

#pragma mark Delegate of NSApplication
-(void)applicationWillTerminate:(NSNotification *)aNotification;

@end
