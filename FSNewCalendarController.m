//
//  FSNewCalendarController.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 21.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSNewCalendarController.h"
#import <CalendarStore/CalendarStore.h>
#import "FSCalCalendarAdditions.h"

@implementation FSNewCalendarController

#pragma mark -
#pragma mark Shared controller

static FSNewCalendarController* sharedController = nil;

+(FSNewCalendarController*)sharedController
{
	if(sharedController == nil){
		sharedController = [[FSNewCalendarController alloc] initWithWindowNibName:@"NewCalendarPanel"];
	}
	
	return sharedController;
}

#pragma mark -
#pragma mark Init

-(void)awakeFromNib
{
	[descriptionTextView setFont:[NSFont systemFontOfSize:
								  [NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
	
	[[descriptionTextView textStorage] setDelegate:self];
}

-(void)textStorageWillProcessEditing:(NSNotification *)n
{
	NSTextStorage* ts = [n object];
	[ts setForegroundColor:[NSColor whiteColor]];
}

-(IBAction)show:(id)sender
{
	[nameTextField setStringValue:@"New calendar"];
	[nameTextField selectText:self];
	[descriptionTextView setString:@""];
	[[self window] makeKeyAndOrderFront:self];
}

-(IBAction)ok:(id)sender
{
	// create the calendar
	CalCalendar* newCalendar = [CalCalendar calendar];
	newCalendar.title = [nameTextField stringValue];
	newCalendar.color = [color color];
	newCalendar.notes = [descriptionTextView string];
	
	[newCalendar saveChangesToSelf];
	[[self window] orderOut:self];
}

-(IBAction)cancel:(id)sender
{
	[[self window] orderOut:self];
}

#pragma mark -
#pragma mark Delegate methods

-(void)controlTextDidChange:(NSNotification*)aNotification
{
	NSTextField* textField = [aNotification object];
	NSString* textValue = [textField stringValue];
	[okButton setEnabled:[textValue length] > 0];
}

@end
