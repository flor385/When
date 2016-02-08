//
//  FSWhenGeometry.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 23.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSWhenGeometry.h"
#import "FSPreferencesController.h"
#import "FSTimeInterval.h"
#import "FSDialsViewInput.h"

@implementation FSWhenGeometry


#pragma mark -
#pragma mark Basic When calculations

+(NSSize)baseSize:(int)earlyDialPosition
{
	float longerSize = 2*(BACKGROUND_CLEARANCE + DIAL_EVENT_DIAMETER + DIAL_EVENT_CLEARANCE);
	float shorterSide = longerSize - DIAL_EVENT_DIAMETER;
	
	if(earlyDialPosition == FSDialPositionLeft || earlyDialPosition == FSDialPositionRight)
		return NSMakeSize(longerSize, shorterSide);
	else
		return NSMakeSize(shorterSide, longerSize);
}

+(NSRect)boundingRectForDial:(int)dialPosition
{
	float x;
	float y;
	float width;
	float height;
	
	float dialEventToEdgeClearance = BACKGROUND_CLEARANCE + DIAL_EVENT_CLEARANCE;
	
	if(dialPosition == FSDialPositionLeft){
		y = x = 0;
		height = (dialEventToEdgeClearance * 2) + DIAL_EVENT_DIAMETER;
		width = dialEventToEdgeClearance + DIAL_EVENT_DIAMETER;
	}else if(dialPosition == FSDialPositionRight){
		y = 0;
		x = dialEventToEdgeClearance + DIAL_EVENT_DIAMETER;
		height = (dialEventToEdgeClearance * 2) + DIAL_EVENT_DIAMETER;
		width = dialEventToEdgeClearance + DIAL_EVENT_DIAMETER;
	}else if(dialPosition == FSDialPositionDown){
		y = x = 0;
		width = (dialEventToEdgeClearance * 2) + DIAL_EVENT_DIAMETER;
		height = dialEventToEdgeClearance + DIAL_EVENT_DIAMETER;
	}else{
		x = 0;
		y = dialEventToEdgeClearance + DIAL_EVENT_DIAMETER;
		width = (dialEventToEdgeClearance * 2) + DIAL_EVENT_DIAMETER;
		height = dialEventToEdgeClearance + DIAL_EVENT_DIAMETER;
	}
	
	return NSMakeRect(x, y, width, height);
}

+(NSPoint)dialCenter:(int)dialPosition
{
	float x;
	float y;
	float dialEventToEdgeClearance = BACKGROUND_CLEARANCE + DIAL_EVENT_CLEARANCE;
	
	if(dialPosition == FSDialPositionLeft){
		y = dialEventToEdgeClearance + (DIAL_EVENT_DIAMETER / 2);
		x = y;
	}else if(dialPosition == FSDialPositionRight){
		y = dialEventToEdgeClearance + (DIAL_EVENT_DIAMETER / 2);
		x = y + DIAL_EVENT_DIAMETER;
	}else if(dialPosition == FSDialPositionDown){
		y = dialEventToEdgeClearance + (DIAL_EVENT_DIAMETER / 2);
		x = y;
	}else{
		x = dialEventToEdgeClearance + (DIAL_EVENT_DIAMETER / 2);
		y = x + DIAL_EVENT_DIAMETER;
	}
	
	return NSMakePoint(x, y);
}

#pragma mark -
#pragma mark Elementary geometry

+(NSPoint)pointWithCenter:(NSPoint)center radius:(float)radius angle:(float)degrees
{
	// translate degrees to radians
	degrees = (degrees / 360.0f) * M_PI * 2.0f;
	
	float x = center.x + (radius * cosf(degrees));
	float y = center.y + (radius * sinf(degrees));
	return NSMakePoint(x, y);
}

+(NSBezierPath*)circleWithCenter:(NSPoint)center radius:(float)radius
{
	NSRect rect = NSMakeRect(center.x - radius, center.y - radius, radius * 2, radius * 2);
	return [NSBezierPath bezierPathWithOvalInRect:rect];
}

+(NSBezierPath*)lineFrom:(NSPoint)p1 to:(NSPoint)p2 width:(float)width
{
	NSBezierPath* rVal = [NSBezierPath bezierPath];
	[rVal moveToPoint:p1];
	[rVal lineToPoint:p2];
	[rVal setLineWidth:(CGFloat)width];
	
	return rVal;
}

+(float)distanceOfPoint:(NSPoint)p1 fromPoint:(NSPoint)p2{
	float a = fabsf(p1.x - p2.x);
	float b = fabsf(p1.y - p2.y);
	
	return sqrtf(a*a + b*b);
}

#pragma mark -
#pragma mark Angles, time and their conversion

+(float)nsGeometryAngleFromClockAngle:(float)clockAngle
{
	float degrees = 360.0f - clockAngle + 90.0f;
	if(degrees > 360.0f)
		degrees -= 360.0f;
	
	return degrees;
}

+(float)clockAngleFromCartasianAngle:(float)cartasianAngle
{
	float degrees = 360.0f - cartasianAngle + 90.0f;
	if(degrees > 360.0f)
		degrees -= 360.0f;
	
	return degrees;
}

+(float)degreeWithHours:(int)hours minutes:(int)minutes
{
	float totalHours = hours + (minutes / 60.0f);
	float degrees = totalHours * 30.0f; // each hour on a 12 hour clock contains 30 degrees
	
	// we need to translate from y-axis clockwise, to x-axis counter-clockwise based degrees
	return [FSWhenGeometry nsGeometryAngleFromClockAngle:degrees];
}

+(NSCalendarDate*)timeForMouseLocation:(NSPoint)point inView:(FSDialsView*)view
{
	// first figure out the closer dial center
	NSPoint dial1Center = [FSWhenGeometry dialCenter:view.earlyDialPosition];
	NSPoint dial2Center = [FSWhenGeometry dialCenter:[view lateDialPosition]];
	BOOL inEarlyDial = [FSWhenGeometry distanceOfPoint:point fromPoint:dial1Center] <
	[FSWhenGeometry distanceOfPoint:point fromPoint:dial2Center];
	NSPoint closerCenter = inEarlyDial ? dial1Center : dial2Center;
	
	// now figure out the angle
	double angle = atan2(point.y - closerCenter.y, point.x - closerCenter.x) * 180 / M_PI;
	if(angle < 0.0f) angle = 360.f + angle;
	double clockAngle = [FSWhenGeometry clockAngleFromCartasianAngle:angle];
	
	// from it the hours and minutes
	int hours = (int)(clockAngle / 30.f);
	int minutes = (int)((clockAngle - hours * 30.f) * 2.0);
	if(hours < [FSWhenTime dayStartHours] 
	   || (hours == [FSWhenTime dayStartHours] && minutes < [FSWhenTime dayStartMinutes]))
		hours +=12;
	if(!inEarlyDial) hours += 12;
	
	// round the minutes
	int minutesRemainder = minutes % 15;
	if(minutesRemainder > 7) minutes += 15 - minutesRemainder;
	else minutes -= minutesRemainder;
	
	// and create and return the date
	NSCalendarDate* rVal = [FSWhenTime calendarDateForOffset:view.offset];
	rVal = [rVal dateByAddingYears:0 months:0 days:0 
							 hours:hours - [rVal hourOfDay] 
						   minutes:minutes - [rVal minuteOfHour] 
						   seconds:0];
	
	return rVal;
}

#pragma mark -
#pragma mark When specific geomety

+(NSPoint)navigationButtonCenterForwards:(BOOL)forward 
					   earlyDialPosition:(int)earlyDialPosition 
						   flowDirection:(int)flowDirection
{
	BOOL horizontal = earlyDialPosition == FSDialPositionLeft || earlyDialPosition == FSDialPositionRight;
	NSSize baseSize = [FSWhenGeometry baseSize:earlyDialPosition];
	
	float y;
	float x;
	
	if(horizontal){
		// x coordinate is on the half of the size
		x = baseSize.width / 2;
		
		// y is a bit more complicated
		BOOL top = NO;
		switch(flowDirection){
			case FSDialFlowDownward:
				top = !forward;
				break;
			case FSDialFlowUpward:
				top = forward;
				break;
			case FSDialFlowLeftward: case FSDialFlowRightward:
				top = forward;
				break;
			default:
				break;
		}
		
		float distanceFromEdge = BACKGROUND_CLEARANCE + NAV_BUTTON_RADIUS;
		y = top ? baseSize.height - distanceFromEdge : distanceFromEdge;
		
	}else{
		// y coordinate is on the half of the size
		y = [FSWhenGeometry baseSize:earlyDialPosition].height / 2;
		
		// x is a bit more complicated
		BOOL right = NO;
		switch(flowDirection){
			case FSDialFlowRightward:
				right = forward;
				break;
			case FSDialFlowLeftward:
				right = !forward;
				break;
			case FSDialFlowDownward: case FSDialFlowUpward:
				right = forward;
				break;
			default:
				break;
		}
		
		float distanceFromEdge = BACKGROUND_CLEARANCE + NAV_BUTTON_RADIUS;
		x = right ? baseSize.width - distanceFromEdge : distanceFromEdge;
	}
	
	return NSMakePoint(x, y);
}

+(NSBezierPath*)trackWithCenter:(NSPoint)center 
						radius1:(float)radius1 
						radius2:(float)radius2 
						 angle1:(float)angle1 
						 angle2:(float)angle2
					  clockwise:(BOOL)clockwise
{
	// if angles are the same, we need a full track
	if(angle1 == angle2){
		NSBezierPath* outer = [FSWhenGeometry circleWithCenter:center radius:fmaxf(radius1, radius2)];
		NSBezierPath* inner = [FSWhenGeometry circleWithCenter:center radius:fminf(radius1, radius2)];
		[outer setWindingRule:NSEvenOddWindingRule];
		[outer appendBezierPath:inner];
		return outer;
	}
	
	NSBezierPath* rVal = [NSBezierPath bezierPath];
	[rVal appendBezierPathWithArcWithCenter:center 
									 radius:radius1 
								 startAngle:angle1 
								   endAngle:angle2 
								  clockwise:clockwise];
	[rVal lineToPoint:[FSWhenGeometry pointWithCenter:center radius:radius2 angle:angle2]];
	[rVal appendBezierPathWithArcWithCenter:center 
									 radius:radius2 
								 startAngle:angle2 
								   endAngle:angle1 
								  clockwise:!clockwise];
	[rVal closePath];
	return rVal;
}

+(NSBezierPath*)taskDayevPathInDial:(int)dial position:(int)position item:(id)task
{
	// find the center point of the task
	float angle = [FSWhenGeometry nsGeometryAngleFromClockAngle:(position * TASK_DAYEV_POSITION_SPREAD_ANGLE)];
	NSPoint center = [FSWhenGeometry pointWithCenter:[FSWhenGeometry dialCenter:dial] 
											  radius:TASK_DAYEV_POSITION_RADIUS
											   angle:angle];
	
	// figure out the radius / line width
	float radius = TASK_DAYEV_RENDER_RADIUS - (TASK_DAYEV_RENDER_LINE_WIDTH / 2);
	float lineWidth = TASK_DAYEV_RENDER_LINE_WIDTH;
	
	NSBezierPath* circle = [FSWhenGeometry circleWithCenter:center radius:radius];
	[circle setLineWidth:lineWidth];
	
	return circle;
}

+(NSBezierPath*)taskDayevHighlightPathInDial:(int)dial 
									position:(int)position 
										item:(id)task
									selected:(BOOL)selected
{
	// find the center point of the task
	float angle = [FSWhenGeometry nsGeometryAngleFromClockAngle:(position * TASK_DAYEV_POSITION_SPREAD_ANGLE)];
	NSPoint center = [FSWhenGeometry pointWithCenter:[FSWhenGeometry dialCenter:dial] 
											  radius:TASK_DAYEV_POSITION_RADIUS
											   angle:angle];
	
	// figure out the radius / line width
	float radius = selected ? TASK_DAYEV_SELECTION_RENDER_RADIUS : TASK_DAYEV_HIGHLIGHT_RENDER_RADIUS;
	float lineWidth = selected ? TASK_DAYEV_SELECTION_RENDER_LINE_WIDTH : TASK_DAYEV_HIGHLIGHT_RENDER_LINE_WIDTH;
	radius -= lineWidth / 2;
	
	// create the path
	NSBezierPath* rVal = [FSWhenGeometry circleWithCenter:center radius:radius];
		
	[rVal setLineWidth:lineWidth];
	return rVal;
}

+(NSBezierPath*)eventPathInDial:(int)dial 
					   interval:(FSTimeInterval*)interval 
						  track:(int)track 
							 of:(int)trackCount 
		  hasTaskDayevClearance:(BOOL)taskDayevClearance;
{
	NSPoint center = [FSWhenGeometry dialCenter:dial];
	
	// figure out the start and end angles
	NSCalendarDate* startDate = [[NSCalendarDate alloc] initWithTimeInterval:0.0 sinceDate:interval.startDate];
	NSCalendarDate* endDate = [[NSCalendarDate alloc] initWithTimeInterval:0.0 sinceDate:interval.endDate];
	float startAngle = [FSWhenGeometry degreeWithHours:[startDate hourOfDay] minutes:[startDate minuteOfHour]];
	float endAngle = [FSWhenGeometry degreeWithHours:[endDate hourOfDay] minutes:[endDate minuteOfHour]];
	[startDate release];
	[endDate release];
	
	// figure out the radiuses
	float innerClearance = TASK_DAYEV_POSITION_RADIUS + (taskDayevClearance ? 
														 (TASK_DAYEV_CLEARANCE + TASK_DAYEV_RENDER_RADIUS) : (-(TASK_DAYEV_CLEARANCE + TASK_DAYEV_RENDER_RADIUS)));
	float allTracksWidth = (DIAL_EVENT_DIAMETER / 2) - innerClearance - 
	(TRACK_CLEARANCE * (trackCount - 1));
	float trackWidth = allTracksWidth / trackCount;
	float outerRadius = (DIAL_EVENT_DIAMETER / 2) - (track * trackWidth) - (TRACK_CLEARANCE * track);
	float innerRadius = outerRadius - trackWidth;
	
	// make the path!
	NSBezierPath* rVal = [NSBezierPath bezierPath];
	[rVal appendBezierPathWithArcWithCenter:center 
									 radius:outerRadius 
								 startAngle:startAngle 
								   endAngle:endAngle 
								  clockwise:YES];
	[rVal lineToPoint:[FSWhenGeometry pointWithCenter:center radius:innerRadius angle:endAngle]];
	[rVal appendBezierPathWithArcWithCenter:center 
									 radius:innerRadius 
								 startAngle:endAngle 
								   endAngle:startAngle 
								  clockwise:NO];
	[rVal closePath];
	
	// no stroke
	[rVal setLineWidth:0.0f];
	
	return rVal;
}

+(NSBezierPath*)glossPathInDial:(int)dial
{
	NSPoint center = [FSWhenGeometry dialCenter:dial];
	float radius = (DIAL_EVENT_DIAMETER / 2) + DIAL_EVENT_CLEARANCE;
	
	// lower half
	NSBezierPath* lowerHalf = [NSBezierPath bezierPath];
	[lowerHalf appendBezierPathWithArcWithCenter:center 
										  radius:radius 
									  startAngle:180.0f 
										endAngle:0.0f 
									   clockwise:NO];
	[lowerHalf closePath];
	
	// upper half
	float height = radius * GLOSS_UPPER_HALF_HEIGHT_PROPORTION;
	NSRect upperHalfRect = NSMakeRect(center.x - radius, center.y - height, radius * 2, height * 2);
	NSBezierPath* upperHalf = [NSBezierPath bezierPathWithOvalInRect:upperHalfRect];
	
	[lowerHalf appendBezierPath:upperHalf];
	[lowerHalf setWindingRule:NSNonZeroWindingRule];
	return lowerHalf;
}

@end
