//
//  FSCalItemRepresentation.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 29.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>

@interface FSCalItemRepresentation : NSObject {

	NSBezierPath* path;
	int taskDayevIndexInDial;
	BOOL brokenStart;
	BOOL brokenEnd;
	int dial;
	id item;
	
	NSColor* fillColor;
	NSColor* strokeColor;
	NSUInteger repType;
}

enum{
	FSRepForNormalEvent = 1,
	FSRepForDayEvent = 2,
	FSRepForTask = 4,
	FSRepForSingleItem = 8,
	FSRepForManyItems = 16,
};

@property(retain, readonly) NSBezierPath* path;
@property(readonly) id item;
@property(readonly) int dial;
@property BOOL brokenStart;
@property BOOL brokenEnd;
@property int taskDayevIndexInDial;
@property(readonly) NSUInteger repType;

+(NSArray*)flattenedItemsInRepArray:(NSArray*)repArray;

-(id)initWithItem:(id)anItem dial:(int)aDial path:(NSBezierPath*)aPath;
-(void)setFillColor:(NSColor*)color;
-(NSColor*)fillColor;
-(void)setStrokeColor:(NSColor*)color;
-(NSColor*)strokeColor;

@end
