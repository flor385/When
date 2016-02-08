//
//  FSNewCalendarController.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 21.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FSNewCalendarController : NSWindowController {

	IBOutlet NSTextField* nameTextField;
	IBOutlet NSColorWell* color;
	IBOutlet NSTextView* descriptionTextView;
	IBOutlet NSButton* okButton;
}

+(FSNewCalendarController*)sharedController;

-(IBAction)show:(id)sender;
-(IBAction)ok:(id)sender;
-(IBAction)cancel:(id)sender;

@end
