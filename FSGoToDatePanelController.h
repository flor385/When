//
//  FSGoToDatePanelController.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 08 3.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FSGoToDatePanelController : NSWindowController {

	IBOutlet NSTextField* dateField;
}

+(FSGoToDatePanelController*)sharedInstance;

-(IBAction)start:(id)sender;
-(IBAction)ok:(id)sender;
-(IBAction)cancel:(id)sender;

@end
