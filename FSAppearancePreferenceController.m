//
//  FSAppearancePreferenceController.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 13.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSAppearancePreferenceController.h"
#import "FSPreferencesController.h"

@implementation FSAppearancePreferenceController

#pragma mark -
#pragma mark Instance creation, MBPreferencesModule implementation

+(FSAppearancePreferenceController*)instance
{
	FSAppearancePreferenceController* rVal = 
	[[FSAppearancePreferenceController alloc] initWithNibName:@"AppearancePreferenceView" 
													bundle:nil];
	
	[rVal autorelease];
	return rVal;
}

- (NSString *)title
{
	return @"Appearance";
}

-(NSString *)identifier
{
	return @"FSWhenAppearancePerferenceModule";
}

-(NSImage *)image
{
	return [NSImage imageNamed:@"AppearanceIcon"];
}

#pragma mark -
#pragma mark Initial values

-(void)awakeFromNib
{
	// dial positions init
	[dialPositions removeAllItems];
	[dialPositions addItemsWithTitles:[NSArray arrayWithObjects:@"Left", @"Top", @"Right", @"Bottom", nil]];
	[dialPositions bind:@"selectedIndex" 
			   toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:[NSString stringWithFormat:@"values.%@", FSDialPositionPreference]
				options:nil];
	
	// dial flow init
	[dialViewFlow removeAllItems];
	[dialViewFlow addItemsWithTitles:[NSArray arrayWithObjects:
									  @"Downward", @"Leftward", @"Upward", @"Rightward", nil]];
	[dialViewFlow bind:@"selectedIndex" 
			   toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:[NSString stringWithFormat:@"values.%@", FSDialFlowPreference]
				options:nil];
	
	// event / todo display style
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud addObserver:self forKeyPath:FSDayEventDisplayStyle options:0 context:nil];
	[ud addObserver:self forKeyPath:FSTaskDisplayStyle options:0 context:nil];
	[self updateDisplayStyleEnabledness:ud];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	[self updateDisplayStyleEnabledness:object];
}


-(void)updateDisplayStyleEnabledness:(NSUserDefaults*)ud
{
	// handling the change in day event display style
    int selectedIndex = [ud integerForKey:FSDayEventDisplayStyle];
	for(NSButtonCell* cell in [todoEventDisplayStyle cells])
		[cell setEnabled:(selectedIndex != [cell tag]) || selectedIndex == FSDoNotDisplay];
	
	// handling the change in task display style
	selectedIndex = [ud integerForKey:FSTaskDisplayStyle];
		for(NSButtonCell* cell in [dayEventDisplayStyle cells])
			[cell setEnabled:(selectedIndex != [cell tag]) || selectedIndex == FSDoNotDisplay];
}

@end
