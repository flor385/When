//
//  CalItemAdditions.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 9.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>
#import "FSCalendarsManager.h"

@interface CalCalendarItem (FSCalItemAdditions)

-(BOOL)saveChangesToSelf;
-(void)revertToSavedState;
-(void)deleteSelf;

// converting to and from a dict
-(NSMutableDictionary*)pasteboardDict;
-(id)initWithPasteboardDict:(NSDictionary*)pbDict;
+(CalCalendarItem*)calItemForPasteboardDict:(NSDictionary*)pbDict;

@end
