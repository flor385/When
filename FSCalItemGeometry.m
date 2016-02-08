//
//  FSEventGeometry.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 2.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSCalItemGeometry.h"


@implementation FSCalItemGeometry

// current condition of the defaults
static int numberOfTracks;
static BOOL hasTaskDayevClearance;


+(NSArray*)eventRepresentationsForOffset:(int)offset dial:(int)earlyDialPosition
{
	// we need some preferences when doing this
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	numberOfTracks = [ud integerForKey:FSTrackNumberPreference];
	hasTaskDayevClearance = [ud integerForKey:FSTaskDisplayStyle] != FSDoNotDisplay || 
		[ud integerForKey:FSDayEventDisplayStyle] != FSDoNotDisplay;
	
	BOOL useCollapsingTrack = [ud boolForKey:FSUseCollapsingTrackPreference];
	BOOL oneTrackPerCalendar = [ud boolForKey:FSOneTrackPerCalPreference];
	
	int numberOfNonCollapsingTracks = numberOfTracks - (useCollapsingTrack ? 1 : 0);
	
	// temporary storage for events, while we are organizing
	NSMutableArray* tracks = [[[NSMutableArray alloc] initWithCapacity:numberOfTracks] autorelease];
	for(int i = 0 ; i < numberOfTracks ; i++)
		[tracks addObject:[[NSMutableArray new] autorelease]];
	NSMutableArray* collapsingTrack = useCollapsingTrack ? 
		[tracks objectAtIndex:numberOfTracks - 1] : nil;
	
	FSCalendarsManager* manager = [FSCalendarsManager sharedManager];
	NSArray* allEvents = [manager eventsForDayOffset:offset];
	for(CalEvent* event in allEvents){
		
		// one track per calendar logic
		if(oneTrackPerCalendar){
			
			// the calendar index
			int calendar = [manager orderOfUsedCalendar:event.calendar.uid];
			
			if(calendar < numberOfNonCollapsingTracks) [[tracks objectAtIndex:calendar] addObject:event];
			else if(useCollapsingTrack) [collapsingTrack addObject:event];
			
		// put wherever fits logic
		}else{
			
			// see if we can find a place for the event in the non-collapsing tracks
			BOOL didFind = NO;
			for(int trackNumber = 0 ; trackNumber < numberOfNonCollapsingTracks ; trackNumber++){
				NSMutableArray* track = [tracks objectAtIndex:trackNumber];
				if([FSCalItemGeometry event:event doesNotIntersectAnyEventIn:track]){
					[track addObject:event];
					didFind = YES;
					break;
				}
			}
			
			if(!didFind && useCollapsingTrack)
				[collapsingTrack addObject:event];
		}
	}
	
	// we have organized events, now make FSCalItemRepresentations of them
	int lateDialPosition = earlyDialPosition;
	switch (earlyDialPosition) {
		case FSDialPositionLeft:
			lateDialPosition = FSDialPositionRight;
			break;
		case FSDialPositionRight:
			lateDialPosition = FSDialPositionLeft;
			break;
		case FSDialPositionDown:
			lateDialPosition = FSDialPositionTop;
			break;
		default:
			lateDialPosition = FSDialPositionDown;
			break;
	}
	
	FSTimeInterval* earlyDialInterval = [FSWhenTime intervalForDayOffset:offset earlierHalf:YES];
	FSTimeInterval* lateDialInterval = [FSWhenTime intervalForDayOffset:offset earlierHalf:NO];
	NSMutableArray* rVal = [[[NSMutableArray alloc] initWithCapacity:[allEvents count]] autorelease];
	
	// first the non-collapsing tracks
	for(int trackNumber = 0 ; trackNumber < numberOfNonCollapsingTracks ; trackNumber++){
		for(CalEvent* event in [tracks objectAtIndex:trackNumber]){
			
			FSCalItemRepresentation* rep = [FSCalItemGeometry repForItem:event 
															inInterval:earlyDialInterval 
																  dial:earlyDialPosition 
																 track:trackNumber];
			if(rep != nil) [rVal addObject:rep];
			rep = [FSCalItemGeometry repForItem:event 
								   inInterval:lateDialInterval 
										 dial:lateDialPosition 
										track:trackNumber];
			if(rep != nil) [rVal addObject:rep];
		}
	}
	
	// now the collapsing track
	if(useCollapsingTrack){
		
		int collapsingTrackIndex = numberOfTracks - 1;
		for(NSMutableArray* itemSet in [FSCalItemGeometry collapsedEventSetsForEvents:collapsingTrack]){
			
			FSCalItemRepresentation* rep = [FSCalItemGeometry repForItem:itemSet 
															inInterval:earlyDialInterval 
																  dial:earlyDialPosition 
																 track:collapsingTrackIndex];
			if(rep != nil) [rVal addObject:rep];
			rep = [FSCalItemGeometry repForItem:itemSet 
								   inInterval:lateDialInterval 
										 dial:lateDialPosition 
										track:collapsingTrackIndex];
			if(rep != nil) [rVal addObject:rep];
		}
	}
	
	return rVal;
}

+(NSArray*)dayEventRepresentationsForOffset:(int)offset dial:(int)dial
{
	// get all the tasks for the offset
	NSArray* objects = [[FSCalendarsManager sharedManager] dayEventsForDayOffset:offset];
	NSMutableArray* dayEvents = [[[NSMutableArray alloc] initWithCapacity:[objects count]] autorelease];
	
	int max = (361.0 / TASK_DAYEV_POSITION_SPREAD_ANGLE);
	int objectCount = [objects count];
	int standalone = objectCount > max ? max - 3 : objectCount;
	
	for(int i = 0 ; i < standalone ; i++){
		NSBezierPath* path = [FSWhenGeometry taskDayevPathInDial:dial 
													   position:i
														   item:[objects objectAtIndex:i]];
		FSCalItemRepresentation* rep = 
		[[FSCalItemRepresentation alloc] initWithItem:[objects objectAtIndex:i] 
												 dial:dial
												 path:path];
		rep.taskDayevIndexInDial = i;
		[dayEvents addObject:rep];
		[rep release];
	}
	
	// see if we need to make a collapsing task
	if(standalone != objectCount){
		
		NSArray* collapsed = [objects subarrayWithRange:
							  NSMakeRange(standalone, objectCount - standalone)];
		NSBezierPath* path = [FSWhenGeometry taskDayevPathInDial:dial 
													   position:max - 2 
														   item:collapsed];
		FSCalItemRepresentation* rep = [[FSCalItemRepresentation alloc] initWithItem:collapsed
																				dial:dial
																				path:path];
		rep.taskDayevIndexInDial = max - 2;
		[dayEvents addObject:rep];
		[rep release];
	}
	
	return dayEvents;
}

+(NSArray*)taskRepresentationsForOffset:(int)offset dial:(int)dial
{
	// get all the tasks for the offset
	NSArray* taskObjects = [[FSCalendarsManager sharedManager] tasksForDayOffset:offset];
	NSMutableArray* tasks = [[[NSMutableArray alloc] initWithCapacity:[taskObjects count]] autorelease];
	
	int maxTaskCount = (361.0 / TASK_DAYEV_POSITION_SPREAD_ANGLE);
	int taskObjectCount = [taskObjects count];
	int standaloneTasks = taskObjectCount > maxTaskCount ? maxTaskCount - 3 : taskObjectCount;
	
	for(int i = 0 ; i < standaloneTasks ; i++){
		NSBezierPath* path = [FSWhenGeometry taskDayevPathInDial:dial 
												   position:i
													   item:[taskObjects objectAtIndex:i]];
		FSCalItemRepresentation* rep = 
		[[FSCalItemRepresentation alloc] initWithItem:[taskObjects objectAtIndex:i] 
												 dial:dial
												 path:path];
		rep.taskDayevIndexInDial = i;
		[tasks addObject:rep];
		[rep release];
	}
	
	// see if we need to make a collapsing task
	if(standaloneTasks != taskObjectCount){
		
		NSArray* collapsedTasks = [taskObjects subarrayWithRange:
								   NSMakeRange(standaloneTasks, taskObjectCount - standaloneTasks)];
		NSBezierPath* path = [FSWhenGeometry taskDayevPathInDial:dial 
												   position:maxTaskCount - 2 
													   item:collapsedTasks];
		FSCalItemRepresentation* rep = [[FSCalItemRepresentation alloc] initWithItem:collapsedTasks 
																				dial:dial
																				path:path];
		rep.taskDayevIndexInDial = maxTaskCount - 2;
		[tasks addObject:rep];
		[rep release];
	}
	
	return tasks;
}

+(BOOL)event:(CalEvent*)event doesNotIntersectAnyEventIn:(NSArray*)events
{
	for(CalEvent* otherEvent in events)
		if([event intersects:otherEvent])
			return NO;
	
	return YES;
}

+(NSArray*)collapsedEventSetsForEvents:(NSArray*)events
{
	NSMutableArray* collapsedItems = [[NSMutableArray new] autorelease];
	NSMutableArray* eventsToAdd = [NSMutableArray arrayWithArray:events];
	
	while([eventsToAdd count] != 0){
		
		// track if we found a way to fit an event
		BOOL didFit = NO;
		
		// see if the event fits into one of the existing sets
		for(NSMutableArray* itemSet in collapsedItems){
			
			// iterate over a copy of the to-add array
			NSArray* eventsToAddCopy = [eventsToAdd copy];
			
			for(CalEvent* event in eventsToAddCopy){
				if(![FSCalItemGeometry event:event doesNotIntersectAnyEventIn:itemSet]){
					[itemSet addObject:event];
					[eventsToAdd removeObject:event];
					didFit = YES;
				}
			}
			
			[eventsToAddCopy release];
			if(didFit) break;
		}
		
		if(didFit) continue;
		
		// need to create a new set
		NSMutableArray* itemSet = [NSMutableArray new];
		[collapsedItems addObject:itemSet];
		[itemSet release];
		
		// and add an event to it
		id event = [eventsToAdd objectAtIndex:0];
		[eventsToAdd removeObject:event];
		[itemSet addObject:event];
	}
	
	return collapsedItems;
}

+(FSCalItemRepresentation*)repForItem:(id)item 
						   inInterval:(FSTimeInterval*)interval 
								 dial:(int)dial 
								track:(int)trackNumber
{
	// get the interval of the item / collapsed items
	FSTimeInterval* itemInterval;
	if([item isKindOfClass:[NSArray class]]){
		// we have a collapsed item
		NSArray* itemSet = (NSArray*)item;
		itemInterval = [FSTimeInterval eventInterval:[itemSet objectAtIndex:0]];
		for(CalEvent* event in itemSet)
			itemInterval = [itemInterval unionInterval:[FSTimeInterval eventInterval:event]];
	}else{
		// we have a standard event
		itemInterval = [FSTimeInterval eventInterval:item];
	}
	
	FSTimeInterval* intersect = [itemInterval intersectionInterval:interval];
	if(intersect != nil){
		NSBezierPath* path = [FSWhenGeometry eventPathInDial:dial 
													interval:intersect 
													   track:trackNumber 
														  of:numberOfTracks
									   hasTaskDayevClearance:hasTaskDayevClearance];
		FSCalItemRepresentation* rep = [[FSCalItemRepresentation alloc] 
										initWithItem:item dial:dial path:path];
		
		// see if the rep got cut
		if(![itemInterval simultaneousStart:intersect])
			rep.brokenStart = YES;
		if(![itemInterval simultaneousEnd:intersect])
			rep.brokenEnd = YES;
		
		[rep autorelease];
		return rep;
	}
	
	return nil;
}

@end
