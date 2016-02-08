//
//  FSCalendars.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 12.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSCalendarsManager.h"
#import "FSPreferencesController.h"
#import "FSCalendarMapping.h"
#import "FSCalItemAdditions.h"

@implementation FSCalendarsManager


# pragma mark -
# pragma mark Singleton pattern implementation

static FSCalendarsManager* sharedManager = nil;

+(FSCalendarsManager*)sharedManager
{
    @synchronized(self) {
        if (sharedManager == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedManager == nil) {
            sharedManager = [super allocWithZone:zone];
            return sharedManager;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

# pragma mark -
# pragma mark Init / dealloc

@synthesize calendarMappings;
@synthesize calendarStore;
@synthesize calendars;

-(id)init
{
	[super init];
	
	// init calendar store
	calendarStore = [[CalCalendarStore defaultCalendarStore] retain];
	
	// init caches
	calendars = [NSMutableArray new];
	normalEventCaches = [NSMutableDictionary new];
	dayEventCaches = [NSMutableDictionary new];
	taskCaches = [NSMutableDictionary new];
	
	// get the user preference for mappings
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSData* prefsData = [defaults dataForKey:FSCalendarsPreference];
	calendarMappings = [[NSMutableArray arrayWithArray:
							 [NSKeyedUnarchiver unarchiveObjectWithData:prefsData]] retain];
	
	// if there are mappings for deleted calendars, their calendar values will be null
	for(FSCalendarMapping* calMap in [NSArray arrayWithArray:calendarMappings])
		if(calMap.calendar == nil)
			[calendarMappings removeObject:calMap];
	
	// if there are calendars that we don't have, well, we want them
	for(CalCalendar* cal in [calendarStore calendars]){
		
		BOOL found = NO;
		for(FSCalendarMapping* calMap in calendarMappings)
			if([calMap.calendar.uid isEqualTo:cal.uid])
				found = YES;
		
		// if we already had this cal in the preferences, continue
		if(found) continue;
		
		// we don't have this cal in the prefs, add it
		FSCalendarMapping* newCalMap = [[FSCalendarMapping alloc] initWithCalendar:cal 
																		 isEnabled:YES];
		[calendarMappings addObject:newCalMap];
		[newCalMap release];
	}
	
	// observe all the mappings
	for(FSCalendarMapping* calMap in calendarMappings)
		[calMap addObserver:self forKeyPath:@"enabled" options:0 context:nil];
	
	// listen to calendar changes occurring in the calendar store
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self 
		   selector:@selector(calendarsChanged:) 
			   name:CalCalendarsChangedExternallyNotification 
			 object:calendarStore];
	[nc addObserver:self 
		   selector:@selector(calendarsChanged:) 
			   name:CalCalendarsChangedNotification 
			 object:calendarStore];
	
	// also listen for task changes (external and internal)
	[nc addObserver:self 
		   selector:@selector(tasksChanged:) 
			   name:CalTasksChangedExternallyNotification 
			 object:calendarStore];
	[nc addObserver:self 
		   selector:@selector(tasksChanged:) 
			   name:CalTasksChangedNotification 
			 object:calendarStore];
	
	// also listen for event changes (external and internal)
	[nc addObserver:self 
		   selector:@selector(eventsChanged:) 
			   name:CalEventsChangedExternallyNotification 
			 object:calendarStore];
	[nc addObserver:self 
		   selector:@selector(eventsChanged:) 
			   name:CalEventsChangedNotification 
			 object:calendarStore];
	
	// make sure the user preferences are up to date with the calendards
	[self calendarMappingsChanged];
	
	return self;
}

-(void)dealloc
{
	[normalEventCaches release];
	[dayEventCaches release];
	[taskCaches release];
	[calendarStore release];
	[calendarMappings release];
	[usedCalendars release];
	[calendars release];
	[super dealloc];
}

#pragma mark -
#pragma mark Notification and KVO reception methods

-(void)calendarsChanged:(NSNotification*)notification
{
	// deal with calendar insertions
	for(NSString* uid in [[notification userInfo] valueForKey:CalInsertedRecordsKey]){
		FSCalendarMapping* newMapping = [[[FSCalendarMapping alloc] 
										  initWithCalendar:[calendarStore calendarWithUID:uid] 
										  isEnabled:YES] autorelease];
		[newMapping addObserver:self forKeyPath:@"enabled" options:0 context:nil];
		[calendarMappings addObject:newMapping];
	}
		
	
	// for updates, simply re-cache the calendar object
	if([[notification userInfo] valueForKey:CalUpdatedRecordsKey] != nil)
		for(FSCalendarMapping* calMap in calendarMappings)
			calMap.calendar = [calendarStore calendarWithUID:calMap.calendar.uid];
	
	// deal with calendar deletions
	NSArray* deletedCalendars = [[notification userInfo] valueForKey:CalDeletedRecordsKey];
	if(deletedCalendars != nil){
		
		// indices of mappings to delete
		NSMutableIndexSet* indicesToDelete = [NSMutableIndexSet new];
		
		for(NSString* uid in deletedCalendars){
			
			// find the calendar mappings to delete
			for(int i = 0, c = [calendarMappings count] ; i < c ; i++){
				FSCalendarMapping* calMap = [calendarMappings objectAtIndex:i];
				if([calMap.calendar.uid isEqualTo:uid]){
					[indicesToDelete addIndex:i];
					[calMap removeObserver:self forKeyPath:@"enabled"];
				}
			}
			
			// remove the items belonging to the calendar from the caches
			[self clearCachesForCalendarUID:uid];
		}
		
		[calendarMappings removeObjectsAtIndexes:indicesToDelete];
	}
	
	// trigger all the stuff
	[self calendarMappingsChanged];
}

-(void)eventsChanged:(NSNotification*)eventsChangedNotification
{
	// some stuff we will need
	NSDictionary* userInfo = [eventsChangedNotification userInfo];
	NSArray* deleted = [userInfo objectForKey:CalDeletedRecordsKey];
	NSArray* inserted = [userInfo objectForKey:CalInsertedRecordsKey];
	NSArray* modified = [userInfo objectForKey:CalUpdatedRecordsKey];
	
	// remove items with those UIDs from the caches, and track what offsets are affected
	NSMutableSet* affectedOffsets = [[NSMutableSet new] autorelease];
	
	// for updates and removals, delete the cache
	if(modified != nil){
		[affectedOffsets unionSet:[self removeItemsWithUIDs:modified fromCacheDict:normalEventCaches]];
		[affectedOffsets unionSet:[self removeItemsWithUIDs:modified fromCacheDict:dayEventCaches]];
	}
	if(deleted != nil){
		[affectedOffsets unionSet:[self removeItemsWithUIDs:deleted fromCacheDict:normalEventCaches]];
		[affectedOffsets unionSet:[self removeItemsWithUIDs:deleted fromCacheDict:dayEventCaches]];
	}
		
	// deletions are done
	// insertions and updates are a bit trickier
	
	// first make a merge of the insertion and update arrays
	NSArray* uidsToAdd = inserted;
	if(uidsToAdd == nil)
		uidsToAdd = modified;
	else if(modified != nil)
		uidsToAdd = [uidsToAdd arrayByAddingObjectsFromArray:modified];
	
	// now iterate over them and re-cache
	for(NSString* uid in uidsToAdd)
		[affectedOffsets unionSet:[self recacheEvent:uid]];
		
	// resort
	for(NSNumber* offset in affectedOffsets){
		[[normalEventCaches objectForKey:offset] sortUsingSelector:@selector(compare:)];
		[[dayEventCaches objectForKey:offset] sortUsingSelector:@selector(compare:)];
	}
		
	// update the views that need updating
	for(FSDialsView* view in [FSDialsViewController allCurrentDialViewsSorted]){
		if(![affectedOffsets containsObject:[NSNumber numberWithInt:view.offset]])
			continue;
		[view updateEventGeometry];
		[view setNeedsDisplay:YES];
	}
}

-(void)tasksChanged:(NSNotification*)taskChangedNotification
{
	// some stuff we will need
	NSDictionary* userInfo = [taskChangedNotification userInfo];
	NSArray* deleted = [userInfo objectForKey:CalDeletedRecordsKey];
	NSArray* inserted = [userInfo objectForKey:CalInsertedRecordsKey];
	NSArray* modified = [userInfo objectForKey:CalUpdatedRecordsKey];
	
	// remove items with those UIDs from the caches, and track what offsets are affected
	NSMutableSet* affectedOffsets = [[NSMutableSet new] autorelease];
	
	// for updates and removals, delete the cache
	if(modified != nil)
		[affectedOffsets unionSet:[self removeItemsWithUIDs:modified fromCacheDict:taskCaches]];
	if(deleted != nil)
		[affectedOffsets unionSet:[self removeItemsWithUIDs:deleted fromCacheDict:taskCaches]];
	
	// deletions are done
	// insertions and updates are a bit trickier
	
	// first make a merge of the insertion and update arrays
	NSArray* uidsToAdd = inserted;
	if(uidsToAdd == nil)
		uidsToAdd = modified;
	else if(modified != nil)
		uidsToAdd = [uidsToAdd arrayByAddingObjectsFromArray:modified];
	
	// now iterate over them
	for(NSString* uid in uidsToAdd){
		
		// get the task
		CalTask* task = [calendarStore taskWithUID:uid];
		if(task.dueDate == nil) continue;
		
		// find where it fits and add it
		NSNumber* taskOffset = [NSNumber numberWithInt:[FSWhenTime offsetForDate:task.dueDate useWhenDayStart:NO]];
		NSMutableArray* cache = [taskCaches objectForKey:taskOffset];
		if(cache != nil){
			[cache addObject:task];
			[affectedOffsets addObject:taskOffset];
		}
	}
	
	// resort
	for(NSNumber* offset in affectedOffsets)
		[[taskCaches objectForKey:offset] sortUsingSelector:@selector(compare:)];
	
	// update the views that need updating
	for(FSDialsView* view in [FSDialsViewController allCurrentDialViewsSorted]){
		if(![affectedOffsets containsObject:[NSNumber numberWithInt:view.offset]])
			continue;
		[view updateTaskGeometry];
		[view setNeedsDisplay:YES];
	}
}

- (void)observeValueForKeyPath:(NSString*)keyPath 
					  ofObject:(id)object 
						change:(NSDictionary*)change 
					   context:(void *)context
{
	if([object isKindOfClass:[FSCalendarMapping class]]){
		
		FSCalendarMapping* calMap = (FSCalendarMapping*)object;
		if([@"enabled" isEqualToString:keyPath]){
			
			// clear the used calendars cache, so it is forced to refresh
			[usedCalendars release];
			usedCalendars = nil;
			
			// if enabled is true, we need to re-cache all the events
			if([calMap.enabled boolValue]){
				[self clearAllCalItemCaches:nil];
				[self recacheCalItemsForVisibleOffsets];
			}else{
				// the cal map is now disabled, simply remove caches for the
				// calendar it represents
				[self clearCachesForCalendarUID:calMap.calendar.uid];
			}
			
			[self calendarMappingsChanged];
		}
	}
}

#pragma mark -
#pragma mark Calendar basics

-(NSArray*)usedCalendars
{
	// lazy init
	if(usedCalendars == nil){
		NSMutableArray* used = [NSMutableArray new];
		for(FSCalendarMapping* calMap in calendarMappings)
			if([calMap.enabled boolValue])
				[used addObject:calMap.calendar];
		
		usedCalendars = [[NSArray arrayWithArray:used] retain];
		[used release];
	}
	
	return usedCalendars;
}

-(CalCalendar*)calendarWithUID:(NSString*)uid
{
	for(FSCalendarMapping* calMap in calendarMappings)
		if([calMap.calendar.uid isEqualToString:uid]) return calMap.calendar;
	
	return nil;
}

-(void)calendarMappingsChanged
{
	// clear the used calendars cache, so it is forced to refresh
	[usedCalendars release];
	usedCalendars = nil;
	
	// update the normal calendars
	[calendars removeAllObjects];
	for(FSCalendarMapping* calMap in calendarMappings)
		[calendars addObject:calMap.calendar];
	
	// update the user defaults
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:calendarMappings] 
				 forKey:FSCalendarsPreference];
}

#pragma mark -
#pragma mark Calendar order / priority

-(NSUInteger)orderOfCalendar:(NSString*)uid
{
	for(int i = 0 , c = [calendarMappings count] ; i < c ; i++){
		FSCalendarMapping* calMap = [calendarMappings objectAtIndex:i];
		if([calMap.calendar.uid isEqualTo:uid])
			return i;
	}
	
	return NSNotFound;
}

-(NSUInteger)orderOfUsedCalendar:(NSString*)uid
{
	NSArray* used = [self usedCalendars];
	for(int i = 0 , c = [used count] ; i < c ; i++){
		CalCalendar* cal = [used objectAtIndex:i];
		if([cal.uid isEqualTo:uid])
			return i;
	}
	
	return NSNotFound;
}

-(CalCalendar*)highestPriorityCalendar
{
	if([calendarMappings count] == 0) return nil;
	
	for(FSCalendarMapping* calMap in calendarMappings)
		if(calMap.enabled) return calMap.calendar;
	
	
	FSCalendarMapping* calMap = [calendarMappings objectAtIndex:0];
	return calMap.calendar;
}



-(void)moveCalendarWithPriority:(NSUInteger)currentPriority toPriority:(NSUInteger)desiredPriority
{
	// re-arrange the array
	// get the object being dragged
	FSCalendarMapping* mapping = [calendarMappings objectAtIndex:currentPriority];
	[mapping retain];
	[mapping autorelease];
   	
	// remove the mapping
	[calendarMappings removeObjectAtIndex:currentPriority];
	// add it at the desired location
	if(currentPriority < desiredPriority) desiredPriority--;
	[calendarMappings insertObject:mapping atIndex: desiredPriority];
	
	// re-sort the calendar item caches
	for(NSMutableArray* cache in [normalEventCaches allValues])
		[cache sortUsingSelector:@selector(compare:)];
	for(NSMutableArray* cache in [dayEventCaches allValues])
		[cache sortUsingSelector:@selector(compare:)];
	for(NSMutableArray* cache in [taskCaches allValues])
		[cache sortUsingSelector:@selector(compare:)];
	
	// clear some other caches
	[calendars removeAllObjects];
	for(FSCalendarMapping* mapping in calendarMappings)
		[calendars addObject:mapping.calendar];
	[usedCalendars release];
	usedCalendars = nil;
	
	// update the preferences
	[self calendarMappingsChanged];
}

#pragma mark -
#pragma mark CalEvent and CalTask managment methods

-(NSArray*)eventsForDayOffset:(int)offset
{
	NSNumber* offsetKey = [NSNumber numberWithInt:offset];
	NSArray* rVal = [normalEventCaches objectForKey:offsetKey];
	
	// if there's no cache for the offset, fetch and cache
	if(rVal == nil)
		[self updateNormalEventCaches:[FSWhenUtil rangeWithLoc:offset lenght:1]];
	
	rVal = [normalEventCaches objectForKey:offsetKey];
	return rVal;
}

-(NSArray*)dayEventsForDayOffset:(int)offset
{
	NSNumber* offsetKey = [NSNumber numberWithInt:offset];
	NSArray* rVal = [dayEventCaches objectForKey:offsetKey];
	
	// if there's no cache for the offset, fetch and cache
	if(rVal == nil)
		[self updateDayEventCaches:[FSWhenUtil rangeWithLoc:offset lenght:1]];
	
	rVal = [dayEventCaches objectForKey:offsetKey];
	return rVal;
}

-(NSArray*)tasksForDayOffset:(int)offset
{
	NSNumber* offsetKey = [NSNumber numberWithInt:offset];
	NSArray* rVal = [taskCaches objectForKey:offsetKey];
	
	// if there's no cache for the offset, fetch and cache
	if(rVal == nil)
		[self updateTaskCaches:[FSWhenUtil rangeWithLoc:offset lenght:1]];
	
	rVal = [taskCaches objectForKey:offsetKey];
	return rVal;
}

-(CalCalendarItem*)updatedItem:(CalCalendarItem*)cachedItem
{
	// tasks
	if([cachedItem isKindOfClass:[CalTask class]]){
		return [calendarStore taskWithUID:cachedItem.uid];
	}
	
	// events
	else{
		CalEvent* cachedEvent = (CalEvent*)cachedItem;
		
		// recurring?
		NSDate* ocurrence = cachedEvent.recurrenceRule == nil ? nil : cachedEvent.occurrence;
		return [calendarStore eventWithUID:cachedEvent.uid occurrence:ocurrence];
	}
}

-(BOOL)thereIsEventStartingInInterval:(FSTimeInterval*)interval
{
	for(NSMutableArray* normalEvents in [normalEventCaches allValues])
		for(CalEvent* event in normalEvents)
			if([interval contains:event.startDate])
				return YES;
	
	return NO;
}

#pragma mark -
#pragma mark Cal item adding, update and deletion

-(void)saveItem:(CalCalendarItem*)calItem
{
	// then save the changes to the item
	if(![calItem saveChangesToSelf])
		[calItem revertToSavedState];
}

-(void)deleteItem:(CalCalendarItem*)calItem
{
	[calItem deleteSelf];
}

#pragma mark -
#pragma mark Cal item cache management

-(void)updateNormalEventCaches:(FSRange)offsetRange
{
	// create a fetch predicate based on the offset
	FSTimeInterval* timeInterval = [FSWhenTime intervalForOffsetRange:offsetRange useWhenDayStart:YES];
	NSPredicate* predicate = 
	[CalCalendarStore eventPredicateWithStartDate:timeInterval.startDate
										  endDate:timeInterval.endDate
										calendars:[self usedCalendars]];
	
	// get the events
	NSArray* fetchedEvents = [calendarStore eventsWithPredicate:predicate];
	
	for(int i = offsetRange.location, c = offsetRange.location + offsetRange.length ; i < c ; i++){
		
		// get the time interval for the offset we are dealing with
		FSTimeInterval* offsetInterval = offsetRange.length == 1 ? 
		timeInterval : [FSWhenTime intervalForDayOffset:i useWhenDayStart:YES];
		
		// only cache events that are not day events and are in the right interval
		NSMutableArray* cache = [[NSMutableArray new] autorelease];
		for(CalEvent* event in fetchedEvents)
			if(!event.isAllDay && [offsetInterval intersectsEvent:event])
				[cache addObject:event];
		
		// return a sorted version of the events
		[cache sortUsingSelector:@selector(compare:)];
		[normalEventCaches setObject:cache forKey:[NSNumber numberWithInt:i]];
	}
}

-(void)updateDayEventCaches:(FSRange)offsetRange
{
	// create a fetch predicate based on the offset
	FSTimeInterval* timeInterval = [FSWhenTime intervalForOffsetRange:offsetRange useWhenDayStart:NO];
	NSPredicate* predicate = 
	[CalCalendarStore eventPredicateWithStartDate:timeInterval.startDate
										  endDate:timeInterval.endDate
										calendars:[self usedCalendars]];
	
	// get the events
	NSArray* fetchedEvents = [calendarStore eventsWithPredicate:predicate];
	
	for(int i = offsetRange.location, c = offsetRange.location + offsetRange.length ; i < c ; i++){
		
		// get the time interval for the offset we are dealing with
		FSTimeInterval* offsetInterval = offsetRange.length == 1 ? 
		timeInterval : [FSWhenTime intervalForDayOffset:i useWhenDayStart:NO];
		
		// only cache events that are day events
		NSMutableArray* cache = [[NSMutableArray new] autorelease];
		for(CalEvent* event in fetchedEvents)
			if(event.isAllDay && [offsetInterval intersectsEvent:event])
				[cache addObject:event];
		
		// return a sorted version of the events
		[cache sortUsingSelector:@selector(compare:)];
		[dayEventCaches setObject:cache forKey:[NSNumber numberWithInt:i]];
	}
}

-(void)updateTaskCaches:(FSRange)offsetRange
{
	// create a fetch predicate based on the offset
	FSTimeInterval* timeInterval = [FSWhenTime intervalForOffsetRange:offsetRange useWhenDayStart:NO];
	NSPredicate* predicate = 
	[CalCalendarStore taskPredicateWithUncompletedTasks:[self usedCalendars]];
	
	// get the tasks
	NSArray* tasks = [calendarStore tasksWithPredicate:predicate];
	
	for(int i = offsetRange.location, c = offsetRange.location + offsetRange.length ; i < c ; i++){
		
		// get the time interval for the offset we are dealing with
		FSTimeInterval* offsetInterval = offsetRange.length == 1 ? 
		timeInterval : [FSWhenTime intervalForDayOffset:i useWhenDayStart:NO];
		
		// only tasks whose dueDate falls within the current offset interval
		NSMutableArray* cache = [[NSMutableArray new] autorelease];
		for(CalTask* task in tasks)
			if([offsetInterval contains:task.dueDate])
				[cache addObject:task];
		
		// return a sorted version of the events
		[cache sortUsingSelector:@selector(compare:)];
		[taskCaches setObject:cache forKey:[NSNumber numberWithInt:i]];
	}
}

-(NSMutableSet*)recacheEvent:(NSString*)uid
{
	NSMutableSet* rVal = [[NSMutableSet new] autorelease];
	
	// figure out which offsets we are interested in
	NSInteger lowOffset = NSIntegerMax;
	NSInteger highOffset = NSIntegerMin;
	
	// since we don't know if we are getting a day even or a normal event
	// we need to scan both caches in search for highest / lowest offsets
	for(NSNumber* offsetNumber in [normalEventCaches allKeys]){
		int offset = [offsetNumber intValue];
		if(offset < lowOffset) lowOffset = offset;
		if(offset > highOffset) highOffset = offset;
	}
	for(NSNumber* offsetNumber in [dayEventCaches allKeys]){
		int offset = [offsetNumber intValue];
		if(offset < lowOffset) lowOffset = offset;
		if(offset > highOffset) highOffset = offset;
	}
	
	// based on offsets figure out 
	NSDate* start = [FSWhenTime offsetStart:lowOffset useWhenDayStart:NO];
	NSDate* end = [FSWhenTime offsetStart:highOffset + 2 useWhenDayStart:NO];
	
	// fetch
	NSPredicate* predicate = [CalCalendarStore eventPredicateWithStartDate:start 
																   endDate:end 
																	   UID:uid 
																 calendars:[self usedCalendars]];
	NSArray* events = [calendarStore eventsWithPredicate:predicate];
	
	// populate caches
	for(CalEvent* event in events){
		
		NSDictionary* cacheDict = event.isAllDay ? dayEventCaches : normalEventCaches;
		
		// add the event to every cache existing for the span of the event
		FSRange eventRange = [FSWhenTime offsetRangeForEvent:event useWhenDayStart:!event.isAllDay];
		for(int i = eventRange.location, c = eventRange.location + eventRange.length ; i < c ; i++){
			
			NSNumber* offset = [NSNumber numberWithInt:i];
			
			NSMutableArray* cache = [cacheDict objectForKey:offset];
			if(cache != nil){
				[cache addObject:event];
				[rVal addObject:offset];
				[cache sortUsingSelector:@selector(compare:)];
			}
		}
	}
	
	return rVal;
}

-(void)recacheCalItemsForVisibleOffsets
{
	int lowOffset = [FSDialsViewController lowestOffset] - FS_OFFSET_LOOK_AHEAD;
	int highOffset = [FSDialsViewController highestOffset] + FS_OFFSET_LOOK_AHEAD;
	FSRange rangeToCache = [FSWhenUtil rangeWithLoc:lowOffset lenght:highOffset - lowOffset + 1];
	
	[self updateDayEventCaches:rangeToCache];
	[self updateNormalEventCaches:rangeToCache];
	[self updateTaskCaches:rangeToCache];
}

-(void)shiftTaskDayevCacheOffsetsBy:(int)shift;
{
	// task caches
	NSMutableDictionary* newCache = [NSMutableDictionary new];
	for(NSNumber* offset in [taskCaches allKeys])
		[newCache setObject:[taskCaches objectForKey:offset] 
					 forKey:[NSNumber numberWithInt:[offset intValue] + shift]];
	[taskCaches release];
	taskCaches = newCache;
	
	
	
	// day event caches
	newCache = [NSMutableDictionary new];
	for(NSNumber* offset in [dayEventCaches allKeys])
		[newCache setObject:[dayEventCaches objectForKey:offset] 
					 forKey:[NSNumber numberWithInt:[offset intValue] + shift]];
	[dayEventCaches release];
	dayEventCaches = newCache;
}

-(void)shiftNormalEventCacheOffsetsBy:(int)shift
{
	// normal event caches
	NSMutableDictionary* newCache = [NSMutableDictionary new];
	for(NSNumber* offset in [normalEventCaches allKeys])
		[newCache setObject:[normalEventCaches objectForKey:offset] 
					 forKey:[NSNumber numberWithInt:[offset intValue] + shift]];
	[normalEventCaches release];
	normalEventCaches = newCache;
}

-(BOOL)event:(CalEvent*)event1 isEqualTo:(CalEvent*)event2
{
	BOOL uidEqual = [event1.uid isEqualToString:event2.uid];
	
	// consider the occurrences equal if their diff is less then one minute
	// since the minimum recurrence is a day, that is a margin of acceptable precision
	return uidEqual && ((event1.occurrence == nil && event2.occurrence == nil)
								 || fabsf([event1.occurrence timeIntervalSinceDate:event2.occurrence]) < 60.0f);
}

#pragma mark -
#pragma mark Cache management

-(void)clearNormalEventCaches:(NSNumber*)offset
{
	if(offset == nil)
		[normalEventCaches removeAllObjects];
	else
		[normalEventCaches removeObjectForKey:offset];
}

-(void)clearDayEventCaches:(NSNumber*)offset
{
	if(offset == nil)
		[dayEventCaches removeAllObjects];
	else
		[dayEventCaches removeObjectForKey:offset];
}

-(void)clearAllCalItemCaches:(NSNumber*)offset
{
	[self clearDayEventCaches:offset];
	[self clearNormalEventCaches:offset];
	[self clearTaskCaches:offset];
}

-(void)clearTaskCaches:(NSNumber*)offset
{
	if(offset == nil)
		[taskCaches removeAllObjects];
	else
		[taskCaches removeObjectForKey:offset];
}

-(NSMutableSet*)clearCachesFor:(CalCalendarItem*)calItem
{
	NSArray* uidArray = [NSArray arrayWithObject:calItem.uid];
	NSMutableSet* rVal;
	
	if([calItem isKindOfClass:[CalEvent class]]){
		rVal = [self removeItemsWithUIDs:uidArray fromCacheDict:normalEventCaches];
		[rVal unionSet:[self removeItemsWithUIDs:uidArray fromCacheDict:dayEventCaches]];
	}else{
		rVal = [self removeItemsWithUIDs:uidArray fromCacheDict:taskCaches];
	}
	
	return rVal;
}

-(NSMutableSet*)clearCachesForCalendarUID:(NSString*)calendarUID
{
	NSMutableSet* affectedOffsets = [[NSMutableSet new] autorelease];
	
	// temporary storage to keep track of items to remove, while iterating
	NSMutableArray* toRemove = [[NSMutableArray new] autorelease];
	
	// task caches
	for(NSNumber* offset in [taskCaches allKeys]){
		
		NSMutableArray* cache = [taskCaches objectForKey:offset];
		
		// find out which items need to be removed, and remove them
		for(CalCalendarItem* calItem in cache)
			if([calItem.calendar.uid isEqualToString:calendarUID])
				[toRemove addObject:calItem];
		[cache removeObjectsInArray:toRemove];
		
		// deal with the to remove cache
		if([toRemove count] > 0) [affectedOffsets addObject:offset];
		[toRemove removeAllObjects];
	}
	
	// normal event caches
	for(NSNumber* offset in [normalEventCaches allKeys]){
		
		NSMutableArray* cache = [normalEventCaches objectForKey:offset];
		
		// find out which items need to be removed, and remove them
		for(CalCalendarItem* calItem in cache)
			if([calItem.calendar.uid isEqualToString:calendarUID])
				[toRemove addObject:calItem];
		[cache removeObjectsInArray:toRemove];
		
		// deal with the to remove cache
		if([toRemove count] > 0) [affectedOffsets addObject:offset];
		[toRemove removeAllObjects];
	}
	
	// day event caches
	for(NSNumber* offset in [dayEventCaches allKeys]){
		
		NSMutableArray* cache = [dayEventCaches objectForKey:offset];
		
		// find out which items need to be removed, and remove them
		for(CalCalendarItem* calItem in cache)
			if([calItem.calendar.uid isEqualToString:calendarUID])
				[toRemove addObject:calItem];
		[cache removeObjectsInArray:toRemove];
		
		// deal with the to remove cache
		if([toRemove count] > 0) [affectedOffsets addObject:offset];
		[toRemove removeAllObjects];
	}
	
	return affectedOffsets;
}

-(NSMutableSet*)removeItemsWithUIDs:(NSArray*)uids fromCacheDict:(NSMutableDictionary*)cache
{
	// track which offsets are affected by the chage
	NSMutableSet* affectedOffsets = [[NSMutableSet new] autorelease];
	
	// use a temp cache of objects that need to be removed
	NSMutableArray* toRemoveCache = [[NSMutableArray new] autorelease];
	
	for(NSNumber* offset in [cache allKeys]){
		NSMutableArray* cachedItems = [cache objectForKey:offset];
		for(CalCalendarItem* item in cachedItems){
			if([uids containsObject:item.uid]){
				[toRemoveCache addObject:item];
				[affectedOffsets addObject:offset];
			}
			
		}
		
		[cachedItems removeObjectsInArray:toRemoveCache];
		[toRemoveCache removeAllObjects];
	}
	
	return affectedOffsets;
}

@end
