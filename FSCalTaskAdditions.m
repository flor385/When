//
//  FSCalTaskAdditions.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 26.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSCalTaskAdditions.h"
#import "FSCalItemAdditions.h"

@implementation CalTask (FSCalTaskAdditions)

-(NSComparisonResult)compare:(CalTask*)task
{
	// compare tasks on their priority
	// if they have different priorities
	if(self.priority != task.priority)
		switch(self.priority){
			case CalPriorityHigh : return NSOrderedAscending;
			case CalPriorityMedium : {
				if(task.priority == CalPriorityHigh) return NSOrderedDescending;
				else return NSOrderedAscending;
			}
			case CalPriorityLow : {
				if(task.priority == CalPriorityNone) return NSOrderedAscending;
				else return NSOrderedDescending;
			}
			case CalPriorityNone : return NSOrderedDescending;
	}
	
	// they have the same priorities, compare them based on calendar priority
	int first = [[FSCalendarsManager sharedManager] orderOfCalendar:self.calendar.uid];
	int second = [[FSCalendarsManager sharedManager] orderOfCalendar:task.calendar.uid];
	if(first != second) return first < second ? NSOrderedAscending : NSOrderedDescending;
	
	// the two tasks are of the same priority and the same calendar
	return NSOrderedSame;
}

-(NSString*)priorityString
{
	switch(self.priority) {
		case CalPriorityHigh:
			return @"High";
		case CalPriorityMedium:
			return @"Medium";
		case CalPriorityLow:
			return @"Low";
		default:
			return nil;;
	}
}

-(NSMutableDictionary*)pasteboardDict
{
	NSMutableDictionary* rVal = [super pasteboardDict];
	[rVal setValue:self.completedDate forKey:@"completedDate"];
	[rVal setValue:self.dueDate forKey:@"dueDate"];
	[rVal setValue:[NSNumber numberWithInt:self.priority] forKey:@"priority"];
	
	return rVal;
}

-(id)initWithPasteboardDict:(NSDictionary*)pbDict
{
	[super initWithPasteboardDict:pbDict];
	
	self.completedDate = [pbDict valueForKey:@"completedDate"];
	self.dueDate = [pbDict valueForKey:@"dueDate"];
	NSNumber* priority = [pbDict valueForKey:@"priority"];
	if(priority)
		self.priority = [priority intValue];
	
	return self;
}

@end
