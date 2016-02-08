//
//  FSCalendars.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 12.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>
#import "FSTimeInterval.h"
#import "FSWhenTime.h"
#import "FSWhenUtil.h"

#define FS_OFFSET_LOOK_AHEAD 14

@interface FSCalendarsManager : NSObject {

	// cached fetched cal items
	NSMutableDictionary* normalEventCaches;
	NSMutableDictionary* dayEventCaches;
	NSMutableDictionary* taskCaches;
	
	// manage calendars and their mappings
	NSMutableArray* calendarMappings;
	NSMutableArray* calendars;
	NSArray* usedCalendars;
	
	// the store!
	CalCalendarStore* calendarStore;
}

@property(retain, readonly) NSArray* calendarMappings;
@property(retain, readonly) CalCalendarStore* calendarStore;
@property(retain, readonly) NSArray* calendars;

+(FSCalendarsManager*)sharedManager;

#pragma mark Calendar managment stuff
-(NSArray*)usedCalendars;
-(CalCalendar*)calendarWithUID:(NSString*)uid;
-(void)calendarMappingsChanged;

#pragma mark Calendar order / priority
-(NSUInteger)orderOfCalendar:(NSString*)uid;
-(NSUInteger)orderOfUsedCalendar:(NSString*)uid;
-(CalCalendar*)highestPriorityCalendar;
-(void)moveCalendarWithPriority:(NSUInteger)currentPriority toPriority:(NSUInteger)desiredPriority;

#pragma mark CalEvent and CalTask managment methods
-(NSArray*)eventsForDayOffset:(int)offset;
-(NSArray*)dayEventsForDayOffset:(int)offset;
-(NSArray*)tasksForDayOffset:(int)offset;
-(CalCalendarItem*)updatedItem:(CalCalendarItem*)cachedItem;
-(BOOL)thereIsEventStartingInInterval:(FSTimeInterval*)interval;

#pragma mark Cal item adding, update and deletion
-(void)saveItem:(CalCalendarItem*)calItem;
-(void)deleteItem:(CalCalendarItem*)calItem;

#pragma mark Cal item cache management
-(void)updateNormalEventCaches:(FSRange)offsetRange;
-(void)updateDayEventCaches:(FSRange)offsetRange;
-(void)updateTaskCaches:(FSRange)offsetRange;
-(NSMutableSet*)recacheEvent:(NSString*)uid;
-(void)recacheCalItemsForVisibleOffsets;
-(void)shiftTaskDayevCacheOffsetsBy:(int)shift;
-(void)shiftNormalEventCacheOffsetsBy:(int)shift;
-(BOOL)event:(CalEvent*)event1 isEqualTo:(CalEvent*)event2;

#pragma mark Cal item cache clearing
-(void)clearNormalEventCaches:(NSNumber*)offset;
-(void)clearDayEventCaches:(NSNumber*)offset;
-(void)clearTaskCaches:(NSNumber*)offset;
-(void)clearAllCalItemCaches:(NSNumber*)offset;
-(NSMutableSet*)clearCachesFor:(CalCalendarItem*)calItem;
-(NSMutableSet*)clearCachesForCalendarUID:(NSString*)calendarUID;
-(NSMutableSet*)removeItemsWithUIDs:(NSArray*)uids fromCacheDict:(NSMutableDictionary*)cache;

@end