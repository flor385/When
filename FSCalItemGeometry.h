//
//  FSEventGeometry.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 2.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>
#import "FSCalendarsManager.h"
#import "FSCalItemRepresentation.h"
#import "FSTimeInterval.h"
#import "FSWhenTime.h"
#import "FSWhenGeometry.h"
#import "FSPreferencesController.h"
#import "FSCalEventAdditions.h"

@interface FSCalItemGeometry : NSObject {

}

+(NSArray*)eventRepresentationsForOffset:(int)offset dial:(int)earlyDialPosition;
+(NSArray*)dayEventRepresentationsForOffset:(int)offset dial:(int)dial;
+(NSArray*)taskRepresentationsForOffset:(int)offset dial:(int)dial;

// utility methods

+(NSArray*)collapsedEventSetsForEvents:(NSArray*)events;
+(BOOL)event:(CalEvent*)event doesNotIntersectAnyEventIn:(NSArray*)events;
+(FSCalItemRepresentation*)repForItem:(id)item 
						   inInterval:(FSTimeInterval*)interval 
								 dial:(int)dial 
								track:(int)trackNumber;

@end
