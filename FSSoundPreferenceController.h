//
//  FSSoundPreferenceController.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 21.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MBPreferencesController.h"

@interface FSSoundPreferenceController : NSViewController <MBPreferencesModule> {

	IBOutlet NSArray* systemSounds;
}

+(FSSoundPreferenceController*)instance;

-(IBAction)newSoundSelected:(id)sender;
-(IBAction)gongPreferenceChanged:(id)sender;

@end
