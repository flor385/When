//
//  FSGeneralPreferenceController.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 13.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSGeneralPreferenceController.h"


@implementation FSGeneralPreferenceController

#pragma mark -
#pragma mark Instance creation, MBPreferencesModule implementation

+(FSGeneralPreferenceController*)instance
{
	FSGeneralPreferenceController* rVal = 
	[[FSGeneralPreferenceController alloc] initWithNibName:@"GeneralPreferenceView" 
													  bundle:nil];
	
	[rVal autorelease];
	return rVal;
}

- (NSString *)title
{
	return @"General";
}

-(NSString *)identifier
{
	return @"FSWhenGeneralPerferenceModule";
}

-(NSImage *)image
{
	return [NSImage imageNamed:@"NSPreferencesGeneral"];
}

-(void)awakeFromNib
{
	// event deletion
	[recurringEventDeletionSpan removeAllItems];
	[recurringEventDeletionSpan addItemsWithTitles:[NSArray 
			arrayWithObjects: @"Ask", @"That event", @"Future events", @"All events", nil]];
	[recurringEventDeletionSpan bind:@"selectedIndex" 
			   toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:[NSString stringWithFormat:@"values.%@", FSRecurringEventDeletionSpanPreference]
				options:nil];
	
	// event modification
	[recurringEventModificationSpan removeAllItems];
	[recurringEventModificationSpan addItemsWithTitles:[NSArray 
			arrayWithObjects: @"Ask", @"That event", @"Future events", @"All events", nil]];
	[recurringEventModificationSpan bind:@"selectedIndex" 
				toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			 withKeyPath:[NSString stringWithFormat:@"values.%@", FSRecurringEventEditSpanPreference]
				 options:nil];
}

@end
