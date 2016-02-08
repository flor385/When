//
//  FSPreferencesController.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 12.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSPreferencesController.h"
#import "MBPreferencesController.h"
#import "FSCalendarsPreferenceController.h"
#import "FSGeneralPreferenceController.h"
#import "FSAppearancePreferenceController.h"
#import "FSSoundPreferenceController.h"
#import "FSWhenGeometry.h"

@implementation FSPreferencesController

+(void)initiPreferenceDefaults
{
	// user defaults setup
	NSMutableDictionary* defaults = [[NSMutableDictionary new] autorelease];
	
	// calendar prefs initial values
	[defaults setValue:[NSNumber numberWithInt:5] forKey:FSTrackNumberPreference];
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:FSOneTrackPerCalPreference];
	[defaults setValue:[NSNumber numberWithBool:YES] forKey:FSUseCollapsingTrackPreference];
	
	// general prefs initial values
	[defaults setValue:[NSNumber numberWithInt:0] forKey:FSDayStartTimeHourPreference];
	[defaults setValue:[NSNumber numberWithInt:0] forKey:FSDayStartTimeMinutePreference];
	[defaults setValue:[NSNumber numberWithBool:YES] forKey:FSDisplayItemTitlesOnHover];
	[defaults setValue:[NSNumber numberWithInt:FSAskWhatToDo] forKey:FSRecurringEventDeletionSpanPreference];
	[defaults setValue:[NSNumber numberWithInt:FSAskWhatToDo] forKey:FSRecurringEventEditSpanPreference];
	[defaults setValue:[NSNumber numberWithInt:FSOnClickNothing] forKey:FSEventSingleClickBehavior];
	[defaults setValue:[NSNumber numberWithInt:FSOnClickEdit] forKey:FSEventDoubleClickBehavior];
	
	// apperance prefs
	[defaults setValue:[NSNumber numberWithInt:FSDialPositionLeft] 
				forKey:FSDialPositionPreference];
	[defaults setValue:[NSNumber numberWithInt:FSDialFlowDownward] forKey:FSDialFlowPreference];
	[defaults setValue:[NSNumber numberWithFloat:1.5] forKey:FSWhenSizePreference];
	[defaults setValue:[NSNumber numberWithInt:FSBackgroundShapeRectangular] 
				forKey:FSBackgroundShapePreference];
	[defaults setValue:[NSNumber numberWithInt:FSDisplayInLateDial] forKey:FSDayEventDisplayStyle];
	[defaults setValue:[NSNumber numberWithInt:FSDisplayInEarlyDial] forKey:FSTaskDisplayStyle];
	
	// sound prefs
	[defaults setValue:[NSNumber numberWithBool:YES] forKey:FSPlayGongOnNewDay];
	[defaults setValue:nil forKey:FSSoundOnNewHour];
	[defaults setValue:nil forKey:FSSoundOnEventStart];
	[defaults setValue:nil forKey:FSSoundBeforeEventStart];
	[defaults setValue:[NSNumber numberWithInt:15] forKey:FSSoundBeforeEventStartMinutes];
	
	// preferences not controlled via the Preferences window
	[defaults setValue:[NSNumber numberWithInt:0] forKey:FSAnchorDialViewOffsetPreference];
	[defaults setValue:[NSNumber numberWithInt:0] forKey:FSNumberOfForwardDialsPreference];
	[defaults setValue:[NSNumber numberWithInt:0] forKey:FSNumberOfBackwardDialsPreference];
	NSSize baseSize = [FSWhenGeometry baseSize:FSDialPositionLeft];
	NSSize screenSize = [[NSScreen mainScreen] frame].size;
	[defaults setValue:[NSNumber numberWithInt:(screenSize.width - baseSize.width) / 2]
				forKey:FSMainWindowOriginX];
	[defaults setValue:[NSNumber numberWithInt:(screenSize.height - baseSize.height) / 2]
				forKey:FSMainWindowOriginY];
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:FSAlwaysOnTopPreference];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

+(CalSpan)spanForDeletingEvent:(CalEvent*)event
{
	if(event.recurrenceRule == nil) return CalSpanThisEvent;
	
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	int preference = [ud integerForKey:FSRecurringEventDeletionSpanPreference];
	
	if(preference == FSAskWhatToDo){
		NSInteger choice = NSRunAlertPanel(
			[NSString stringWithFormat:@"\"%@\" is a recurring event", event.title],
			@"A recurring event is being deleted. Which recurrences should be removed?",
										   @"This event", @"Future events", @"All events");
		
		if(choice == NSAlertDefaultReturn) return CalSpanThisEvent;
		if(choice == NSAlertAlternateReturn) return CalSpanFutureEvents;
		if(choice == NSAlertOtherReturn) return CalSpanAllEvents;
	}
	
	if(preference == FSThisOccurence) return CalSpanThisEvent;
	if(preference == FSFutureOcurrences) return CalSpanFutureEvents;
	if(preference == FSAllOcurrences) return CalSpanAllEvents;
	
	return -1;
}

+(CalSpan)spanForEditingEvent:(CalEvent*)event
{
	if(event.recurrenceRule == nil) return CalSpanThisEvent;
	
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	int preference = [ud integerForKey:FSRecurringEventEditSpanPreference];
	
	if(preference == FSAskWhatToDo){
		NSInteger choice = NSRunAlertPanel(
			[NSString stringWithFormat:@"\"%@\" is a recurring event", event.title],
			@"A recurring event is being modified. Which recurrences should be affected?",
			@"This event", @"Future events", @"All events");
		
		if(choice == NSAlertDefaultReturn) return CalSpanThisEvent;
		if(choice == NSAlertAlternateReturn) return CalSpanFutureEvents;
		if(choice == NSAlertOtherReturn) return CalSpanAllEvents;
	}
	
	if(preference == FSThisOccurence) return CalSpanThisEvent;
	if(preference == FSFutureOcurrences) return CalSpanFutureEvents;
	if(preference == FSAllOcurrences) return CalSpanAllEvents;
	
	return -1;
}

static BOOL didInitialize = NO;

-(IBAction)showPreferences:(id)sender
{
	MBPreferencesController* mbpc = [MBPreferencesController sharedController];
	
	// lazy initialization
	if(!didInitialize){
		
		[mbpc setModules:[NSArray arrayWithObjects:
						  [FSGeneralPreferenceController instance],
						  [FSCalendarsPreferenceController instance],
						  [FSAppearancePreferenceController instance], 
						  [FSSoundPreferenceController instance], nil]];
		
		didInitialize = YES;
	}
	
	[mbpc showWindow:sender];
}

@end
