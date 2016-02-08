//
//  FSPreferencesController.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 12.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>

// general preferences
#define FSDayStartTimeHourPreference @"FSDayStartTimeHourPreference"
#define FSDayStartTimeMinutePreference @"FSDayStartTimeMinutePreference"
#define FSDisplayItemTitlesOnHover @"FSDisplayItemTitlesOnHover"
#define FSRecurringEventDeletionSpanPreference @"FSRecurringEventDeletionSpanPreference"
#define FSRecurringEventEditSpanPreference @"FSRecurringEventEditSpanPreference"
#define FSEventSingleClickBehavior @"FSEventSingleClickBehavior"
#define FSEventDoubleClickBehavior @"FSEventDoubleClickBehavior"

// calendars preferences
#define FSCalendarsPreference @"FSCalendarsPreference"
#define FSTrackNumberPreference @"FSTrackNumberPreference"
#define FSOneTrackPerCalPreference @"FSOneTrackPerCalPreference"
#define FSUseCollapsingTrackPreference @"FSUseCollapsingTrackPreference"

// appearance prefs
#define FSDialPositionPreference @"FSDialPositionPreference"
#define FSDialFlowPreference @"FSDialFlowPreference"
#define FSWhenSizePreference @"FSWhenSizePreference"
#define FSBackgroundShapePreference @"FSBackgroundShapePreference"
#define FSDayEventDisplayStyle @"FSDayEventDisplayStyle"
#define FSTaskDisplayStyle @"FSTaskDisplayStyle"

// sound prefs
#define FSPlayGongOnNewDay @"FSPlayGongOnNewDay"
#define FSSoundBeforeEventStart @"FSSoundBeforeEventStart"
#define FSSoundBeforeEventStartMinutes @"FSSoundBeforeEventStartMinutes"
#define FSSoundOnNewHour @"FSSoundOnNewHour"
#define FSSoundOnEventStart @"FSSoundOnEventStart"

// some user defaults that are not controlled in the Preferences window
#define FSAnchorDialViewOffsetPreference @"FSAnchorDialViewOffsetPreference"
#define FSNumberOfForwardDialsPreference @"FSNumberOfForwardDialsPreference"
#define FSNumberOfBackwardDialsPreference @"FSNumberOfBackwardDialsPreference"
#define FSMainWindowOriginX @"FSMainWindowOriginX"
#define FSMainWindowOriginY @"FSMainWindowOriginY"
#define FSAlwaysOnTopPreference @"FSAlwaysOnTopPreference"

// dial position constants
enum {
    FSDialPositionLeft	= 0,
    FSDialPositionTop	= 1,
    FSDialPositionRight	= 2,
    FSDialPositionDown	= 3
};

// dial flow constants
enum {
    FSDialFlowDownward	= 0,
    FSDialFlowLeftward	= 1,
    FSDialFlowUpward	= 2,
    FSDialFlowRightward	= 3
};

// background style constants
enum {
    FSBackgroundShapeRectangular	= 0,
    FSBackgroundShapeRounded		= 1
};

// day event / todo display constants
enum {
	FSDisplayInEarlyDial = 0,
	FSDisplayInLateDial = 1,
	FSDoNotDisplay = 2
};

// recurring event deletion span
enum {
	FSAskWhatToDo = 0,
	FSThisOccurence = 1,
	FSFutureOcurrences = 2,
	FSAllOcurrences = 3
};

// clicking behavior
enum {
	FSOnClickNothing = 0,
	FSOnClickShowInfo = 1,
	FSOnClickEdit = 2
};

@interface FSPreferencesController : NSObject {

}

+(void)initiPreferenceDefaults;
+(CalSpan)spanForDeletingEvent:(CalEvent*)event;
+(CalSpan)spanForEditingEvent:(CalEvent*)event;

-(IBAction)showPreferences:(id)sender;

@end
