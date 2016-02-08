//
//  FSWhenGeometry.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 23.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>

// dial constants
#define DIAL_EVENT_DIAMETER 100.0f
#define DIAL_EVENT_CLEARANCE 2.0f
#define DIAL_MARKS_LINE_WIDTH 0.5f
#define DIAL_MARKS_MINUTE_LINE_LENGHT 2.0f
#define DIAL_ELAPSED_TIME_LINE_LINE_WIDTH 0.5f
#define TRACK_CLEARANCE -0.1f

#define EVENT_FADE_WIDTH 5.0f

#define GLOSS_UPPER_HALF_HEIGHT_PROPORTION 0.3f

// navigation button constants
#define NAV_BUTTON_RADIUS 10.75f

// tasks dayev constants
#define TASK_DAYEV_POSITION_RADIUS 20.0f
#define TASK_DAYEV_CLEARANCE 2.2f
#define TASK_DAYEV_POSITION_SPREAD_ANGLE 22.5f
#define TASK_DAYEV_RENDER_RADIUS 2.8f
#define TASK_DAYEV_RENDER_LINE_WIDTH 0.8f

// task dayev highlight and selection
#define TASK_DAYEV_SELECTION_RENDER_RADIUS 3.8f
#define TASK_DAYEV_HIGHLIGHT_RENDER_RADIUS 3.8f
#define TASK_DAYEV_SELECTION_RENDER_LINE_WIDTH 2.0f
#define TASK_DAYEV_HIGHLIGHT_RENDER_LINE_WIDTH 0.8f

// the distance between individual dial views
#define DIAL_VIEW_SPACING 2.0f

// background constants
#define BACKGROUND_CLEARANCE 2.0f
#define BACKGROUND_RECT_ROUNDING 0.2f

@class FSDialsView;
@class FSTimeInterval;
@class FSPreferencesController;

@interface FSWhenGeometry : NSObject {

}

#pragma mark -
#pragma mark Basic When calculations
+(NSSize)baseSize:(int)earlyDialPosition;
+(NSRect)boundingRectForDial:(int)dialPosition;
+(NSPoint)dialCenter:(int)dialPosition;

#pragma mark -
#pragma mark Elementary geometry
+(NSPoint)pointWithCenter:(NSPoint)center radius:(float)radius angle:(float)degrees;
+(NSBezierPath*)circleWithCenter:(NSPoint)center radius:(float)radius;
+(NSBezierPath*)lineFrom:(NSPoint)p1 to:(NSPoint)p2 width:(float)width;
+(float)distanceOfPoint:(NSPoint)p1 fromPoint:(NSPoint)p2;

#pragma mark -
#pragma mark Angles, time and their conversion
+(float)nsGeometryAngleFromClockAngle:(float)clockAngle;
+(float)clockAngleFromCartasianAngle:(float)cartasianAngle;
+(float)degreeWithHours:(int)hours minutes:(int)minutes;
+(NSCalendarDate*)timeForMouseLocation:(NSPoint)point inView:(FSDialsView*)view;

#pragma mark -
#pragma mark When specific geomety
+(NSPoint)navigationButtonCenterForwards:(BOOL)forward 
					   earlyDialPosition:(int)earlyDialPosition 
						   flowDirection:(int)flowDirection;
+(NSBezierPath*)trackWithCenter:(NSPoint)center 
						radius1:(float)radius1 
						radius2:(float)radius2 
						 angle1:(float)angle1 
						 angle2:(float)angle2
					  clockwise:(BOOL)clockwise;
+(NSBezierPath*)taskDayevPathInDial:(int)dial 
						   position:(int)position 
							   item:(id)task;
+(NSBezierPath*)taskDayevHighlightPathInDial:(int)dial 
									position:(int)position 
										item:(id)task
									selected:(BOOL)selected;
+(NSBezierPath*)eventPathInDial:(int)dial 
					   interval:(FSTimeInterval*)interval 
						  track:(int)track 
							 of:(int)trackCount 
		  hasTaskDayevClearance:(BOOL)taskDayevClearance;
+(NSBezierPath*)glossPathInDial:(int)dial;

@end