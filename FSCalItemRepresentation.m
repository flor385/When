//
//  FSCalItemRepresentation.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 29.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSCalItemRepresentation.h"


@implementation FSCalItemRepresentation

@synthesize path;
@synthesize item;
@synthesize dial;
@synthesize brokenStart;
@synthesize brokenEnd;
@synthesize taskDayevIndexInDial;
@synthesize repType;

+(NSArray*)flattenedItemsInRepArray:(NSArray*)repArray
{
	NSMutableArray* rVal = [[[NSMutableArray alloc] initWithCapacity:[repArray count]] autorelease];
	
	for(FSCalItemRepresentation* rep in repArray){
		if([rep.item isKindOfClass:[NSArray class]])
			[rVal addObjectsFromArray:rep.item];
		else
			[rVal addObject:rep.item];
	}
	
	return rVal;
}

-(id)initWithItem:(id)anItem dial:(int)aDial path:(NSBezierPath*)aPath
{
	if(self == [super init]){
		item = [anItem retain];
		path = [aPath retain];
		dial = aDial;
		
		// figure out the rep type
		repType = 0;
		
		// multiple event reps
		if([item isKindOfClass:[NSArray class]]){
			repType += FSRepForManyItems;
			CalCalendarItem* calItem = [item objectAtIndex:0];
			repType += [calItem isKindOfClass:[CalEvent class]] ? 
				(((CalEvent*)calItem).isAllDay ? FSRepForDayEvent : FSRepForNormalEvent) : FSRepForTask;
		
		// single event reps
		}else{
			repType += FSRepForSingleItem;
			repType += [item isKindOfClass:[CalEvent class]] ? 
				(((CalEvent*)item).isAllDay ? FSRepForDayEvent : FSRepForNormalEvent) : FSRepForTask;
		}
	}
	
	return self;
}

static NSColor* collapseFillColor = nil;

-(void)setFillColor:(NSColor*)color
{
	[color retain];
	[fillColor release];
	fillColor = color;
}

-(NSColor*)fillColor
{
	// lazy init / derived color caching
	if(fillColor == nil){
		
		// collapsing events get the collapse color	
		if(repType & FSRepForManyItems){
			if(collapseFillColor == nil) collapseFillColor = [[NSColor colorWithDeviceWhite:0.0 alpha:0.5] retain];
			fillColor = [collapseFillColor retain];
		
		// tasks get a lower opacity based on priority
		}else if(repType & FSRepForTask){
			
			CalTask* task = (CalTask*)item;
			
			switch( task.priority ){
				case CalPriorityHigh : {
					fillColor = [task.calendar.color retain];
					break;
				}
				case CalPriorityMedium : {
					fillColor = [[task.calendar.color blendedColorWithFraction:0.25 ofColor:[NSColor whiteColor]] retain];
					break;
				}
				case CalPriorityLow : {
					fillColor = [[task.calendar.color blendedColorWithFraction:0.5 ofColor:[NSColor whiteColor]] retain];
					break;
				}
				default : {
					fillColor = [[task.calendar.color blendedColorWithFraction:0.75 ofColor:[NSColor whiteColor]] retain];
					break;
				}
			}
		
		// day events
		}else if(repType & FSRepForDayEvent)
			fillColor = [[((CalEvent*)item).calendar.color blendedColorWithFraction:0.75 ofColor:[NSColor whiteColor]] retain];
		
		// normal events 
		else
			fillColor = [[((CalEvent*)item).calendar.color colorWithAlphaComponent:0.5] retain];
	}
	
	return fillColor;
}

NSColor* collapseStrokeColor;

-(void)setStrokeColor:(NSColor*)color
{
	[color retain];
	[strokeColor release];
	strokeColor = color;
}

-(NSColor*)strokeColor
{
	// lazy init / derived color caching
	if(strokeColor == nil){
		
		// collapsing items
		if(repType & FSRepForManyItems){
			if(collapseStrokeColor == nil) collapseStrokeColor = [[NSColor colorWithDeviceWhite:0.0 alpha:0.5] retain];
			strokeColor = [collapseStrokeColor retain];
		
		// tasks get a lower opacity based on priority
		}else if(repType & FSRepForTask){
			
			CalTask* task = (CalTask*)item;
			
			switch( task.priority ){
				case CalPriorityHigh :
					strokeColor = [task.calendar.color retain];
					break;
				
				case CalPriorityMedium :
					strokeColor = [[task.calendar.color blendedColorWithFraction:0.25 ofColor:[NSColor whiteColor]] retain];
					break;
				
				case CalPriorityLow :
					strokeColor = [[task.calendar.color blendedColorWithFraction:0.5 ofColor:[NSColor whiteColor]] retain];
					break;
				
				default :
					strokeColor = [[task.calendar.color blendedColorWithFraction:0.75 ofColor:[NSColor whiteColor]] retain];
					break;
				
			}
		
		// cal events get their stroke color as the calendar
		}else
			strokeColor = [((CalEvent*)item).calendar.color retain];
	}
	
	return strokeColor;
}

-(void)dealloc
{
	[item release];
	[path release];
	[fillColor release];
	[strokeColor release];
	[super dealloc];
}

@end
