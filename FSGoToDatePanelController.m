//
//  FSGoToDatePanelController.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 08 3.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSGoToDatePanelController.h"
#import "FSAppController.h"
#import "FSDialsView.h"
#import "FSDialsViewController.h"
#import "FSWhenTime.h"

@implementation FSGoToDatePanelController

static FSGoToDatePanelController* sharedInstance = nil;

+(FSGoToDatePanelController*)sharedInstance
{
	if(sharedInstance == nil){
		sharedInstance = [[FSGoToDatePanelController alloc] initWithWindowNibName:@"GoToDatePanel"];
	}
	
	return sharedInstance;
}

-(IBAction)start:(id)sender
{
	// show window
	[[self window] makeKeyAndOrderFront:sender];
	
	// get the current anchor view offset
	NSInteger anchorOffset = [[FSAppController controller] anchorViewOffset];
	
	// set the date
	NSDate* date = [FSWhenTime calendarDateForOffset:anchorOffset];
	[[dateField cell] setObjectValue:date];
}

-(IBAction)ok:(id)sender
{
	// get the date the user wanted
	NSDate* desiredOffsetDate = (NSDate*)[[dateField cell] objectValue];
	NSInteger desiredOffset = [FSWhenTime offsetForDate:desiredOffsetDate useWhenDayStart:NO];
	
	// get the offset diff
	NSInteger anchorOffset = [[FSAppController controller] anchorViewOffset];
	NSInteger offsetDiff = desiredOffset - anchorOffset;
	
	// move the dials if necessary
	if(offsetDiff != 0)
		for(FSDialsView* view in [FSDialsViewController allCurrentDialViewsSorted])
			view.offset += offsetDiff;
	
	[[self window] orderOut:sender];
}

-(IBAction)cancel:(id)sender
{
	[[self window] orderOut:sender];
}

@end
