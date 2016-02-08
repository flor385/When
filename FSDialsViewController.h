//
//  FSDialsViewController.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 23.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>
#import "FSWhenGeometry.h"
#import "FSDialsView.h"

@interface FSDialsViewController : NSViewController {
}

#pragma mark Managing all controller instances / their views
+(NSArray*)allCurrentDialViewControllers;
+(NSArray*)allCurrentDialViewsSorted;
+(void)removeController:(FSDialsViewController*)controller;

#pragma mark Offset managing
+(FSDialsViewController*)existingControllerWithOffset:(int)offset;
+(NSInteger)highestOffset;
+(NSInteger)lowestOffset;
+(void)ensureOffsetIsVisible:(NSInteger)offset;

#pragma mark Managing selected / highlighted items
+(void)setSelectionCalItems:(NSArray*)newSelection;
+(NSArray*)selectionCalItems;
+(void)setHighlightCalItems:(NSArray*)newHighlight;
+(NSArray*)highlightCalItems;
+(BOOL)hasRecurrenceInSelection;

#pragma mark actions
-(IBAction)makeSelectedDayEventIntoNormalEvent:(id)sender;
-(IBAction)makeSelectedEventIntoDayEvent:(id)sender;
-(IBAction)markSelectedTaskAsCompleted:(id)sender;

#pragma mark actions that are forwarded to the FSAppController
-(IBAction)addViewToFront:(id)sender;
-(IBAction)addViewToBack:(id)sender;
-(IBAction)removeFirstDay:(id)sender;
-(IBAction)removeLastDay:(id)sender;
-(IBAction)incrementOffset:(id)sender;
-(IBAction)decrementOffset:(id)sender;

-(id)init;

@end
