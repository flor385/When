//
//  FSAppearancePreferenceController.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 13.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MBPreferencesController.h"

@interface FSAppearancePreferenceController : NSViewController <MBPreferencesModule> {

	IBOutlet NSPopUpButton* dialPositions;
	IBOutlet NSPopUpButton* dialViewFlow;
	IBOutlet NSMatrix* dayEventDisplayStyle;
	IBOutlet NSMatrix* todoEventDisplayStyle;
}

+(FSAppearancePreferenceController*)instance;

-(void)updateDisplayStyleEnabledness:(NSUserDefaults*)ud;

@end
