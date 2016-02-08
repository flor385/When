//
//  FSGeneralPreferenceController.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 13.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MBPreferencesController.h"
#import "FSPreferencesController.h"

@interface FSGeneralPreferenceController : NSViewController <MBPreferencesModule> {

	IBOutlet NSPopUpButton* recurringEventDeletionSpan;
	IBOutlet NSPopUpButton* recurringEventModificationSpan;
}

+(FSGeneralPreferenceController*)instance;

@end
