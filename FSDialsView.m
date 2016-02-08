//
//  FSDialsViewLogic.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 23.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSDialsView.h"


@implementation FSDialsView

@synthesize earlyDialPosition;
@synthesize offset;

#pragma mark -
#pragma mark Custom initialization

-(id)initWithFrame:(NSRect)frame
{
	if(self == [super initWithFrame:frame])
		[self customInit];

	return self;
}

-(id)initWithCoder:(NSCoder*)coder
{
	if(self == [super initWithCoder:coder])
		[self customInit];
	
	return self;
}

-(void)customInit
{
	// properties
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	earlyDialPosition = [ud integerForKey:FSDialPositionPreference];
	backgroundShape = [ud integerForKey:FSBackgroundShapePreference];
	taskDisplayStyle = [ud integerForKey:FSTaskDisplayStyle];
	dayEventDisplayStyle = [ud integerForKey:FSDayEventDisplayStyle];
	flowDirection = [ud integerForKey:FSDialFlowPreference];
	
	// bound properties
	[self bind:@"taskDisplayStyle" toObject:ud withKeyPath:FSTaskDisplayStyle options:nil];
	[self bind:@"dayEventDisplayStyle" toObject:ud withKeyPath:FSDayEventDisplayStyle options:nil];
	
	// initialize caches
	tasks = [NSMutableArray new];
	events = [NSMutableArray new];
	dayEvents = [NSMutableArray new];
	
	// init the colors and geometry
	[self colorsInit];
	[self textAttributesInit];
	[self updateSize];
	[self updateAllGeometry];
}

-(void)colorsInit
{
	dialInnerCircleColor = [[NSColor colorWithDeviceWhite:0.0 alpha:0.5] retain];
	dialMarksColor = [[NSColor colorWithDeviceWhite:0.0 alpha:0.5] retain];
	
	eventInOutFade = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:1.0 
																					   alpha:0.0]
												   endingColor:[NSColor colorWithDeviceWhite:1.0 
																					   alpha:1.0]];
	backgroundGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.0 
																						 alpha:0.5]
													   endingColor:[NSColor colorWithDeviceWhite:0.0 
																						  alpha:0.5]];
	dialMarkOverlayGradient = [[NSGradient alloc] initWithColorsAndLocations:
							   [NSColor colorWithDeviceWhite:1.0 alpha:1.0],
							   (CGFloat)0.35,
							   [NSColor colorWithDeviceWhite:1.0 alpha:0.0],(CGFloat)1.0, nil];
	timeElapsedShadeColorDarken = [[NSColor colorWithDeviceRed:226.0/255.0 
												   green:234.0/255.0 
													blue:246.0/255.0 
												   alpha:1.0] retain];
	glossDarkGradient  = [[NSGradient alloc] initWithColorsAndLocations:
						  [NSColor colorWithDeviceWhite:0.0 alpha:0.025],
						  (CGFloat)0.0,
						  [NSColor colorWithDeviceWhite:0.0 alpha:0.0],(CGFloat)0.75, nil];
	glossOuterRingGrandient  = [[NSGradient alloc] initWithColorsAndLocations:
								[NSColor colorWithDeviceWhite:1.0 alpha:0.0],
								(CGFloat)0.4,
								[NSColor colorWithDeviceWhite:1.0 alpha:0.1],(CGFloat)1.0, nil];
}

-(void)textAttributesInit
{
	// weekday text rendering attributes
	weekDayTextAttributes = [NSMutableDictionary new];
	NSColor* color = [NSColor colorWithCalibratedRed:158.0/255.0 green:180.0/255.0 blue:213.0/255.0 alpha:1.0];
	[weekDayTextAttributes setValue:color forKey:NSForegroundColorAttributeName];
	[weekDayTextAttributes setValue:[NSFont fontWithName:@"Georgia-Bold" size:10.0] forKey:NSFontAttributeName];
	
	// weekend text rendering attributes
	weekendDayTextAttributes = [[NSMutableDictionary alloc] initWithDictionary:weekDayTextAttributes];
	color = [NSColor colorWithCalibratedRed:229.0/255.0 green:161.0/255.0 blue:161.0/255.0 alpha:1.0];
	[weekendDayTextAttributes setValue:color forKey:NSForegroundColorAttributeName];
	
	// date (number) text rendering attributes
	dateTextAttributes = [NSMutableDictionary new];
	[dateTextAttributes setValue:[NSNumber numberWithFloat:7.0f] forKey:NSFontSizeAttribute];
	[dateTextAttributes setValue:[NSColor colorWithCalibratedWhite:120.0/255.0 alpha:1.0f] forKey:NSForegroundColorAttributeName];
	[dateTextAttributes setValue:[NSFont fontWithName:@"Georgia" size:11.0] forKey:NSFontAttributeName];
	
	// month (3 letters) text rendering attributes
	monthTextAttributes = [[NSMutableDictionary alloc] initWithDictionary:dateTextAttributes];
	[monthTextAttributes setValue:[NSFont fontWithName:@"Georgia" size:9.0] forKey:NSFontAttributeName];
	[monthTextAttributes setValue:[NSColor colorWithCalibratedWhite:180.0/255.0 alpha:1.0f] forKey:NSForegroundColorAttributeName];
	
	// nav buttons
	navButtonTextAttributes = [[NSMutableDictionary alloc] initWithDictionary:dateTextAttributes];
	[navButtonTextAttributes setValue:[NSFont fontWithName:@"Georgia" size:9.0] forKey:NSFontAttributeName];
	[navButtonTextAttributes setValue:[NSColor colorWithCalibratedWhite:0.25 alpha:1.0f] forKey:NSForegroundColorAttributeName];
	
}

-(NSComparisonResult)compare:(FSDialsView*)anotherView
{
	if(self.offset < anotherView.offset) return NSOrderedAscending;
	return self.offset > anotherView.offset ? NSOrderedDescending : NSOrderedSame;
}

#pragma mark -
#pragma mark Size and subview stuff

-(void)updateSize
{
	// get the base size
	NSSize size = [FSWhenGeometry baseSize:earlyDialPosition];
	
	// consider scaling
	sizeProportion = [[NSUserDefaults standardUserDefaults] floatForKey:FSWhenSizePreference];
	
	// apply scaling
	if(sizeProportion > 1.00f){
		size.width *= sizeProportion;
		size.height *= sizeProportion;
	}
	
	// create transforms
	[transform release];
	transform = [[NSAffineTransform transform] retain];
	[transform scaleBy:sizeProportion];
	[transformInverted release];
	transformInverted = [[NSAffineTransform alloc] initWithTransform:transform];
	[transformInverted invert];
	
	// we have the desired size, apply it
	[self setFrameSize:size];
}

#pragma mark -
#pragma mark Properties

-(void)setEarlyDialPosition:(int)newPosition
{
	if(earlyDialPosition == newPosition) return;
	
	BOOL oldHorizontal = earlyDialPosition == FSDialPositionLeft || earlyDialPosition == FSDialPositionRight;
	BOOL newHorizontal = newPosition == FSDialPositionLeft || newPosition == FSDialPositionRight;
	
	earlyDialPosition = newPosition;
	
	if(oldHorizontal != newHorizontal) [self updateSize];
	[self updateAllGeometry];
}

-(void)setOffset:(int)newOffset
{
	if(offset == newOffset) return;
	offset = newOffset;
	[self updateEventGeometry];
	[self updateTaskGeometry];
	[self updateElapsedTimeGeometry];
	[self setNeedsDisplay:YES];
}

-(int)backgroundShape { return backgroundShape; }

-(void)setBackgroundShape:(int)newShapeType
{
	if(newShapeType == backgroundShape) return;
	backgroundShape = newShapeType;
	
	[self updateBackgroundGeometry];
	[self setNeedsDisplay:YES];
}

-(int)lateDialPosition
{
	if(earlyDialPosition == FSDialPositionLeft)
		return FSDialPositionRight;
	if(earlyDialPosition == FSDialPositionDown)
		return FSDialPositionTop;
	if(earlyDialPosition == FSDialPositionRight)
		return FSDialPositionLeft;
	if(earlyDialPosition == FSDialPositionTop)
		return FSDialPositionDown;
	
	[NSException raise:@"Unknown early dial position" format:@"Early dial position = %d", earlyDialPosition];
	return 0;
}

-(int)taskDisplayStyle { return taskDisplayStyle; }

-(void)setTaskDisplayStyle:(int)newStyle
{
	if(taskDisplayStyle == newStyle) return;
	taskDisplayStyle = newStyle;
	
	[self updateTaskGeometry];
	[self updateElapsedTimeGeometry];
	[self updateEventGeometry];
	[self setNeedsDisplay:YES];
}

-(int)dayEventDisplayStyle { return dayEventDisplayStyle; }

-(void)setDayEventDisplayStyle:(int)newStyle
{
	if(dayEventDisplayStyle == newStyle) return;
	dayEventDisplayStyle = newStyle;
	
	[self updateEventGeometry];
	[self updateElapsedTimeGeometry];
	[self updateEventGeometry];
	[self setNeedsDisplay:YES];
}

-(int)flowDirection { return flowDirection; }

-(void)setFlowDirection:(int)newDirection
{
	if(flowDirection == newDirection) return;
	flowDirection = newDirection;
	
	[self updateNavButtonGeometry];
	[self setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark Geometry calculations

-(void)updateAllGeometry
{
	[self updateBackgroundGeometry];
	[self updateElapsedTimeGeometry];
	[self updateTaskGeometry];
	[self updateEventGeometry];
	[self updateGlossGeometry];
	[self updateNavButtonGeometry];
	[self updateEventFadeGeometry];
}

-(void)updateBackgroundGeometry
{
	// bounds
	NSRect bounds;
	bounds.origin = NSMakePoint(0.0f, 0.0f);
	bounds.size = [FSWhenGeometry baseSize:earlyDialPosition];
	
	// background
	[background release];
	background = nil;
	
	float rounding = backgroundShape == FSBackgroundShapeRectangular ?
	fminf(bounds.size.width, bounds.size.height) * BACKGROUND_RECT_ROUNDING
	:	fminf(bounds.size.width, bounds.size.height) / 2;
	background = [[NSBezierPath bezierPathWithRoundedRect:bounds
												  xRadius:rounding
												  yRadius:rounding] retain];
	
	// dials
	[dial1Background release];
	[dial2Background release];
	
	NSPoint d1Center = [FSWhenGeometry dialCenter:earlyDialPosition];
	NSPoint d2Center = [FSWhenGeometry dialCenter:[self lateDialPosition]];
	float backgroundRadius = (DIAL_EVENT_DIAMETER / 2) + DIAL_EVENT_CLEARANCE;
	dial1Background = [[FSWhenGeometry circleWithCenter:d1Center radius:backgroundRadius] retain];
	dial2Background = [[FSWhenGeometry circleWithCenter:d2Center radius:backgroundRadius] retain];
}

-(void)updateEventGeometry
{
	/* NORMAL EVENT GEOMETRY */
	
	[events removeAllObjects];
	[events addObjectsFromArray:[FSCalItemGeometry eventRepresentationsForOffset:offset dial:earlyDialPosition]];
	
	
	
	/* DAY EVENT GEOMETRY */
	
	[dayEvents removeAllObjects];
	
	if(dayEventDisplayStyle == FSDoNotDisplay) return;
	int dayEventDialPosition = dayEventDisplayStyle == FSDisplayInEarlyDial ? 
		earlyDialPosition : [self lateDialPosition];
	
	// if we are currently before day start, then we need to display the tasks
	// for one day before (offset - 1)
	NSCalendarDate* date = [FSWhenTime currentTime];
	BOOL beforeDayStart = [date hourOfDay] < [FSWhenTime dayStartHours]
		|| ([date hourOfDay] == [FSWhenTime dayStartHours] && [date minuteOfHour] < [FSWhenTime dayStartMinutes]);
	
	int dayevOffset = beforeDayStart ? offset - 1 : offset;
	
	[dayEvents addObjectsFromArray:[FSCalItemGeometry dayEventRepresentationsForOffset:dayevOffset 
																				dial:dayEventDialPosition]];
}

-(void)updateTaskGeometry
{
	[tasks removeAllObjects];
	
	if(taskDisplayStyle == FSDoNotDisplay) return;
	int taskDialPosition = taskDisplayStyle == FSDisplayInEarlyDial ? 
		earlyDialPosition : [self lateDialPosition];
	
	// if we are currently before day start, then we need to display the tasks
	// for one day before (offset - 1)
	NSCalendarDate* date = [FSWhenTime currentTime];
	BOOL beforeDayStart = [date hourOfDay] < [FSWhenTime dayStartHours]
		|| ([date hourOfDay] == [FSWhenTime dayStartHours] && [date minuteOfHour] < [FSWhenTime dayStartMinutes]);
	
	int taskOffset = beforeDayStart ? offset - 1 : offset;
	
	[tasks addObjectsFromArray:[FSCalItemGeometry taskRepresentationsForOffset:taskOffset dial:taskDialPosition]];
}

-(void)updateElapsedTimeGeometry
{
	// release existing stuff
	[dial1DayStartLine release]; dial1DayStartLine = nil;
	[dial2DayStartLine release]; dial2DayStartLine = nil;
	[dial1DayEndLine release]; dial1DayEndLine = nil;
	[dial2DayEndLine release]; dial2DayEndLine = nil;
	[dial1TimeElapsedShade release]; dial1TimeElapsedShade = nil;
	[dial2TimeElapsedShade release]; dial2TimeElapsedShade = nil;
	
	// first we need to know the time limit
	int hours = [FSWhenTime dayStartHours];
	int minutes = [FSWhenTime dayStartMinutes];
	
	// some stuff we will use
	float angle = [FSWhenGeometry degreeWithHours:hours minutes:minutes];
	float outerRadius = (DIAL_EVENT_DIAMETER / 2) + DIAL_EVENT_CLEARANCE;
	float innerRadius = TASK_DAYEV_POSITION_RADIUS;
	BOOL hasTaskDayevClearance = dayEventDisplayStyle != FSDoNotDisplay || taskDisplayStyle != FSDoNotDisplay;
	if(hasTaskDayevClearance)
		innerRadius += (TASK_DAYEV_CLEARANCE + TASK_DAYEV_RENDER_RADIUS);
	else
		innerRadius -= (TASK_DAYEV_CLEARANCE + TASK_DAYEV_RENDER_RADIUS);
	NSPoint dial1Center = [FSWhenGeometry dialCenter:earlyDialPosition];
	NSPoint dial2Center = [FSWhenGeometry dialCenter:[self lateDialPosition]];
	
	// now create stuff
	
	// first the start lines
	NSPoint p1 = [FSWhenGeometry pointWithCenter:dial1Center radius:outerRadius angle:angle];
	NSPoint p2 = [FSWhenGeometry pointWithCenter:dial1Center radius:innerRadius angle:angle];
	dial1DayStartLine = [[FSWhenGeometry lineFrom:p1 to:p2 width:DIAL_ELAPSED_TIME_LINE_LINE_WIDTH] retain];
	p1 = [FSWhenGeometry pointWithCenter:dial2Center radius:outerRadius angle:angle];
	p2 = [FSWhenGeometry pointWithCenter:dial2Center radius:innerRadius angle:angle];
	dial2DayStartLine = [[FSWhenGeometry lineFrom:p1 to:p2 width:DIAL_ELAPSED_TIME_LINE_LINE_WIDTH] retain];
	
	// if this view is showing a day in the future, then we are done
	if(offset > 0) return;
	
	// now the end lines and the shape, if necessary
	
	// some more stuff we will need
	NSCalendarDate* now = [FSWhenTime currentTime];
	int hoursNow = [now hourOfDay];
	int minutesNow = [now minuteOfHour];
	
	// some decision making switches
	BOOL currentlyBeforeDayStart = hoursNow < hours || (hoursNow == hours && minutesNow < minutes);
		
	// create the early shade and current time
	// early dial is full (angle2 is the same as angle1) if any of the following conditions are met
	BOOL earlyDialFull = offset < 0
	|| currentlyBeforeDayStart 
	|| hoursNow > hours + 12 
	|| (hoursNow == hours + 12 && minutesNow > minutes);
	
	float angle2 = earlyDialFull ?
	angle : [FSWhenGeometry degreeWithHours:hoursNow minutes:minutesNow];
	
	// create the day end line only if not all of the dial is elapsed
	if(!earlyDialFull){
		p1 = [FSWhenGeometry pointWithCenter:dial1Center radius:outerRadius angle:angle2];
		p2 = [FSWhenGeometry pointWithCenter:dial1Center radius:innerRadius angle:angle2];
		dial1DayEndLine = [[FSWhenGeometry lineFrom:p1 to:p2 width:DIAL_ELAPSED_TIME_LINE_LINE_WIDTH * 2] retain];
	}
	
	// create the shade but only if we are not at the day start
	BOOL exactlyOnDayStart = offset == 0 && hours == hoursNow && minutes == minutesNow;
	if(!exactlyOnDayStart)
		dial1TimeElapsedShade = [[FSWhenGeometry trackWithCenter:dial1Center 
														 radius1:innerRadius 
														 radius2:outerRadius 
														  angle1:angle 
														  angle2:angle2 
													   clockwise:YES] retain];
	
	// create the late shade, as necessary
	BOOL needLateShade = offset < 0
		|| currentlyBeforeDayStart
		|| hoursNow - hours > 12
		|| (hoursNow - hours == 12 && minutesNow > minutes);
	if(needLateShade){
		
		hoursNow -= 12;
		
		// angle2 is the same as angle1 if the diff is greater then 12 hours
		float angle2 = offset < 0 ? angle : [FSWhenGeometry degreeWithHours:hoursNow minutes:minutesNow];
		
		// the line
		if(angle != angle2){
			p1 = [FSWhenGeometry pointWithCenter:dial2Center radius:outerRadius angle:angle2];
			p2 = [FSWhenGeometry pointWithCenter:dial2Center radius:innerRadius angle:angle2];
			dial2DayEndLine = [[FSWhenGeometry lineFrom:p1 to:p2 width:DIAL_ELAPSED_TIME_LINE_LINE_WIDTH * 2] retain];
		}
		
		// the shade
		dial2TimeElapsedShade = [[FSWhenGeometry trackWithCenter:dial2Center 
														 radius1:innerRadius 
														 radius2:outerRadius 
														  angle1:angle 
														  angle2:angle2 
													   clockwise:YES] retain];
	}
}

-(void)updateGlossGeometry
{
	[dial1Gloss release];
	[dial2Gloss release];
	
	dial1Gloss = [[FSWhenGeometry glossPathInDial:earlyDialPosition] retain];
	dial2Gloss = [[FSWhenGeometry glossPathInDial:[self lateDialPosition]] retain];
}

-(void)updateNavButtonGeometry
{
	// release!
	[navButtonForwardBackground release];
	[navButtonBackwardBackground release];
	
	NSPoint forwardCenter = [FSWhenGeometry navigationButtonCenterForwards:YES 
														 earlyDialPosition:earlyDialPosition 
															 flowDirection:flowDirection];
	NSPoint backwardCenter = [FSWhenGeometry navigationButtonCenterForwards:NO 
														  earlyDialPosition:earlyDialPosition 
															  flowDirection:flowDirection];
	
	navButtonForwardBackground = [[FSWhenGeometry circleWithCenter:forwardCenter 
															radius:NAV_BUTTON_RADIUS] retain];
	navButtonBackwardBackground = [[FSWhenGeometry circleWithCenter:backwardCenter 
															 radius:NAV_BUTTON_RADIUS] retain];
}

-(void)updateEventFadeGeometry
{
	[dial1StartFade release];
	[dial1EndFade release];
	[dial2StartFade release];
	[dial2EndFade release];
	
	// create them at 3 o'clock as that's where the NS geometry system sees 0 degrees
	float width = (DIAL_EVENT_DIAMETER / 2) + DIAL_EVENT_CLEARANCE;
	float height = EVENT_FADE_WIDTH;
	dial1StartFade = [[NSBezierPath bezierPathWithRect:
					  NSMakeRect(0, -height, width, height)] retain];
	dial1EndFade = [[NSBezierPath bezierPathWithRect:
					   NSMakeRect(0, 0, width, height)] retain];
	dial2StartFade = [[NSBezierPath bezierPathWithRect:
					   NSMakeRect(0, -height, width, height)] retain];
	dial2EndFade = [[NSBezierPath bezierPathWithRect:
					 NSMakeRect(0, 0, width, height)] retain];
	
	// transform these shapes to reflect the position of the day start
	NSAffineTransform* d1Transform = [NSAffineTransform transform];
	NSAffineTransform* d2Transform = [NSAffineTransform transform];
	
	// first apply the movement transform
	NSPoint d1Origin = [FSWhenGeometry dialCenter:earlyDialPosition];
	NSPoint d2Origin = [FSWhenGeometry dialCenter:[self lateDialPosition]];
	[d1Transform translateXBy:d1Origin.x yBy:d1Origin.y];
	[d2Transform translateXBy:d2Origin.x yBy:d2Origin.y];
	
	// now apply the rotation transfrom
	int hours = [FSWhenTime dayStartHours];
	int minutes = [FSWhenTime dayStartMinutes];
	float rotation = [FSWhenGeometry degreeWithHours:hours minutes:minutes];
	[d1Transform rotateByDegrees:rotation];
	[d2Transform rotateByDegrees:rotation];
	
	// apply the transformations
	[dial1StartFade transformUsingAffineTransform:d1Transform];
	[dial1EndFade transformUsingAffineTransform:d1Transform];
	[dial2StartFade transformUsingAffineTransform:d2Transform];
	[dial2EndFade transformUsingAffineTransform:d2Transform];
}

#pragma mark -
#pragma mark Painting methods

-(void)drawRect:(NSRect)dirtyRect
{
	// we need to set some scaling
	[transform concat];
	
	[self drawTransparentBackgroundGeometry];
	[self drawNavButtons];
	[self drawBackgroundGeometry];
	[self drawDialTickMarks];
	
	[self drawTasks];
	[self drawEvents];
	[self drawElapsedTimeGeometry];
	[self drawText];
	[self drawGloss];}

-(void)drawTransparentBackgroundGeometry
{
	[backgroundGradient drawInBezierPath:background angle:270.0];
}

-(void)drawBackgroundGeometry
{
	/* DIALS */
	
	// background
	[[NSColor whiteColor] set];
	[[NSBezierPath bezierPathWithRect:[FSWhenGeometry boundingRectForDial:earlyDialPosition]] setClip];
	[dial1Background fill];
	[[NSBezierPath bezierPathWithRect:[FSWhenGeometry boundingRectForDial:[self lateDialPosition]]] setClip];
	[dial2Background fill];
	NSRect clippingRect;
	clippingRect.size = [FSWhenGeometry baseSize:earlyDialPosition];
	clippingRect.origin = NSZeroPoint;
	[[NSBezierPath bezierPathWithRect:clippingRect] setClip];
}

-(void)drawDialTickMarks
{
	// some stuff we need
	[dialMarksColor set];
	[NSBezierPath setDefaultLineWidth:DIAL_MARKS_LINE_WIDTH];
	NSPoint d1Center = [FSWhenGeometry dialCenter:earlyDialPosition];
	NSPoint d2Center = [FSWhenGeometry dialCenter:[self lateDialPosition]];
	float backgroundRadius = (DIAL_EVENT_DIAMETER / 2) + DIAL_EVENT_CLEARANCE;
	
	// hour marks
	for(int j = 0; j < 6 ; j++){
		NSPoint p1 = [FSWhenGeometry pointWithCenter:d1Center 
											  radius:backgroundRadius 
											   angle:[FSWhenGeometry degreeWithHours:j minutes:0]];
		NSPoint p2 = [FSWhenGeometry pointWithCenter:d1Center 
											  radius:backgroundRadius 
											   angle:[FSWhenGeometry degreeWithHours:j + 6 minutes:0]];
		[NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
		p1 = [FSWhenGeometry pointWithCenter:d2Center 
									  radius:backgroundRadius 
									   angle:[FSWhenGeometry degreeWithHours:j minutes:0]];
		p2 = [FSWhenGeometry pointWithCenter:d2Center 
									  radius:backgroundRadius 
									   angle:[FSWhenGeometry degreeWithHours:j + 6 minutes:0]];
		[NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
	}
	
	// minute marks
	[[dialMarksColor colorWithAlphaComponent:[dialMarksColor alphaComponent] / 2] set];
	for(int hours = 0 ; hours < 12 ; hours++)
		for(int minutes = 15 ; minutes < 60 ; minutes += 15){
			float smallRadius = backgroundRadius - (minutes == 30 ? 4 : 1 ) * DIAL_MARKS_MINUTE_LINE_LENGHT;
			
			NSPoint p1 = [FSWhenGeometry pointWithCenter:d1Center 
												  radius:backgroundRadius 
												   angle:[FSWhenGeometry degreeWithHours:hours minutes:minutes]];
			NSPoint p2 = [FSWhenGeometry pointWithCenter:d1Center 
												  radius:smallRadius 
												   angle:[FSWhenGeometry degreeWithHours:hours minutes:minutes]];
			[NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
			p1 = [FSWhenGeometry pointWithCenter:d2Center 
										  radius:backgroundRadius 
										   angle:[FSWhenGeometry degreeWithHours:hours minutes:minutes]];
			p2 = [FSWhenGeometry pointWithCenter:d2Center 
										  radius:smallRadius 
										   angle:[FSWhenGeometry degreeWithHours:hours minutes:minutes]];
			[NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
		}
	
	// dial marks gradient
	[dialMarkOverlayGradient drawInBezierPath:dial1Background relativeCenterPosition:NSMakePoint(0, 0)];
	[dialMarkOverlayGradient drawInBezierPath:dial2Background relativeCenterPosition:NSMakePoint(0, 0)];
}

-(void)drawElapsedTimeGeometry
{
	NSGraphicsContext* gc = [NSGraphicsContext currentContext];
	
	// first the shade
	[timeElapsedShadeColorDarken set];
	NSCompositingOperation opBefore = [gc compositingOperation];
	[gc setCompositingOperation:NSCompositePlusDarker];
	[[NSBezierPath bezierPathWithRect:[FSWhenGeometry boundingRectForDial:earlyDialPosition]] setClip];
	[dial1TimeElapsedShade fill];
	[[NSBezierPath bezierPathWithRect:[FSWhenGeometry boundingRectForDial:[self lateDialPosition]]] setClip];
	[dial2TimeElapsedShade fill];
	[gc setCompositingOperation:opBefore];
	
	// reset the clipping rect
	NSRect baseSizeRect;
	baseSizeRect.size = [FSWhenGeometry baseSize:earlyDialPosition];
	baseSizeRect.origin = NSZeroPoint;
	[[NSBezierPath bezierPathWithRect:baseSizeRect] setClip];
	
	// then the lines
	[dialInnerCircleColor set];
	[dial1DayStartLine stroke];
	[dial2DayStartLine stroke];
	[dial1DayEndLine stroke];
	[dial2DayEndLine stroke];
}

-(void)drawText
{
	// some stuff we need
	NSPoint earlyDialCenter = [FSWhenGeometry dialCenter:earlyDialPosition];
	NSPoint lateDialCenter = [FSWhenGeometry dialCenter:[self lateDialPosition]];
	NSCalendarDate* date = [FSWhenTime calendarDateForOffset:offset];
	NSDateFormatter* dateFormatter = [[NSDateFormatter new] autorelease];
	
	// day
	int dayOfWeek = [date dayOfWeek];
	NSDictionary* attributes = (dayOfWeek == 0 ? weekendDayTextAttributes : weekDayTextAttributes);
	NSString* day = [[dateFormatter shortStandaloneWeekdaySymbols] objectAtIndex:dayOfWeek];
	NSSize size = [day sizeWithAttributes:attributes];
	NSFont* font = [attributes valueForKey:NSFontAttributeName];
	NSPoint origin = NSMakePoint(earlyDialCenter.x - size.width / 2, 
								 earlyDialCenter.y - (([font xHeight] / 2) + abs([font descender])));
	[day drawAtPoint:origin withAttributes:(dayOfWeek == 0 ? weekendDayTextAttributes : weekDayTextAttributes)];
	
	// month and date
	int overlap = 4.0f;
	NSString* dateOfMonth = [[NSNumber numberWithInt:[date dayOfMonth]] stringValue];
	NSString* month = [[[dateFormatter shortMonthSymbols] objectAtIndex:[date monthOfYear] - 1] lowercaseString];
	NSSize dateSize = [dateOfMonth sizeWithAttributes:dateTextAttributes];
	NSSize monthSize = [month sizeWithAttributes:monthTextAttributes];
	NSSize total = NSMakeSize(fmaxf(dateSize.width, monthSize.width), 
							  dateSize.height + monthSize.height - overlap);
	origin = [FSWhenGeometry dialCenter:[self lateDialPosition]];
	origin = NSMakePoint(lateDialCenter.x - dateSize.width / 2, 
						 lateDialCenter.y - total.height / 2);
	[dateOfMonth drawAtPoint:origin withAttributes:dateTextAttributes];
	origin = NSMakePoint(lateDialCenter.x - monthSize.width / 2, 
						 origin.y + (dateSize.height - overlap));
	[month drawAtPoint:origin withAttributes:monthTextAttributes];
}

-(void)drawTasks
{
	for(FSCalItemRepresentation* rep in tasks){
		[[rep fillColor] set];
		[rep.path fill];
		
		if([rep.path lineWidth] > 0.0f){
			[[rep strokeColor] set];
			[rep.path stroke];
		}
	}
}

-(void)drawEvents
{
	/* NORMAL EVENTS */
	
	// first figure out the angle for the fade gradient
	float angle1 = 90.0f + [FSWhenGeometry degreeWithHours:[FSWhenTime dayStartHours] 
												  minutes:[FSWhenTime dayStartMinutes]];
	if(angle1 > 360.0f) angle1 -= 360.0f;
	float angle2 = angle1 + 180.0f;
	if(angle2 > 360.0f) angle2 -= 360.0f;
	
	// render items one by one
	NSRect baseRect;
	baseRect.size = [FSWhenGeometry baseSize:earlyDialPosition];
	baseRect.origin = NSZeroPoint;
	NSBezierPath* baseRectPath = [NSBezierPath bezierPathWithRect:baseRect];
	for(FSCalItemRepresentation* rep in events){
		[[rep fillColor] set];
		[rep.path fill];
		
		if([rep.path lineWidth] > 0.0f){
			[[rep strokeColor] set];
			[rep.path stroke];
		}
		
		if(rep.brokenStart){
			[rep.path setClip];
			if(rep.dial == earlyDialPosition)
				[eventInOutFade drawInBezierPath:dial1StartFade angle:angle1];
			else
				[eventInOutFade drawInBezierPath:dial2StartFade angle:angle1];
			[baseRectPath setClip];
		}
		
		if(rep.brokenEnd){
			[rep.path setClip];
			if(rep.dial == earlyDialPosition)
				[eventInOutFade drawInBezierPath:dial1EndFade angle:angle2];
			else
				[eventInOutFade drawInBezierPath:dial2EndFade angle:angle2];
			[baseRectPath setClip];
		}
	}
	
	/* DAY EVENTS */
	
	for(FSCalItemRepresentation* rep in dayEvents){
		[[rep fillColor] set];
		[rep.path fill];
		
		if([rep.path lineWidth] > 0.0f){
			[[rep strokeColor] set];
			[rep.path stroke];
		}
	}
}

-(void)drawGloss
{
	NSGraphicsContext* gc = [NSGraphicsContext currentContext];
	NSCompositingOperation cop = [gc compositingOperation];
	
	// first dial
	[[NSBezierPath bezierPathWithRect:[FSWhenGeometry boundingRectForDial:earlyDialPosition]] setClip];
	[gc setCompositingOperation:NSCompositePlusDarker];
	[glossDarkGradient drawInBezierPath:dial1Gloss angle:270.f];
	[gc setCompositingOperation:NSCompositePlusLighter];
	[glossOuterRingGrandient drawInBezierPath:dial1Background relativeCenterPosition:NSMakePoint(0, 0)];
	
	// second dial
	[[NSBezierPath bezierPathWithRect:[FSWhenGeometry boundingRectForDial:[self lateDialPosition]]] setClip];
	[gc setCompositingOperation:NSCompositePlusDarker];
	[glossDarkGradient drawInBezierPath:dial2Gloss angle:270.f];
	[gc setCompositingOperation:NSCompositePlusLighter];
	[glossOuterRingGrandient drawInBezierPath:dial2Background relativeCenterPosition:NSMakePoint(0, 0)];
	
	// reset the state of the gc
	[gc setCompositingOperation:cop];
	NSRect baseRect;
	baseRect.origin = NSZeroPoint;	
	baseRect.size = [FSWhenGeometry baseSize:earlyDialPosition];
	[[NSBezierPath bezierPathWithRect:baseRect] setClip];
}

-(void)drawNavButtons
{
	// backward text
	if(offset == [FSDialsViewController lowestOffset]){
		[[NSColor colorWithDeviceWhite:1.0 alpha:0.9] set];
		[navButtonBackwardBackground fill];
		
		NSCalendarDate* date = [FSWhenTime calendarDateForOffset:offset - 1];
		NSString* string = [[NSNumber numberWithInt:[date dayOfMonth]] stringValue];
		NSFont* font = (NSFont*)[navButtonTextAttributes valueForKey:NSFontAttributeName];
		float yOffset = [font xHeight] / 2 + fabsf([font descender]);
		NSPoint origin = [FSWhenGeometry navigationButtonCenterForwards:NO 
													  earlyDialPosition:earlyDialPosition 
														  flowDirection:flowDirection];
		origin.y -= yOffset;
		origin.x -= [string sizeWithAttributes:navButtonTextAttributes].width / 2;
		[string drawAtPoint:origin withAttributes:navButtonTextAttributes];
	}
	
	// forward text
	if(offset == [FSDialsViewController highestOffset]){
		[[NSColor colorWithDeviceWhite:1.0 alpha:0.9] set];
		[navButtonForwardBackground fill];
		
		NSCalendarDate* date = [FSWhenTime calendarDateForOffset:offset + 1];
		NSString* string = [[NSNumber numberWithInt:[date dayOfMonth]] stringValue];
		NSFont* font = (NSFont*)[navButtonTextAttributes valueForKey:NSFontAttributeName];
		float yOffset = [font xHeight] / 2 + fabsf([font descender]);
		NSPoint origin = [FSWhenGeometry navigationButtonCenterForwards:YES 
													  earlyDialPosition:earlyDialPosition 
														  flowDirection:flowDirection];
		origin.y -= yOffset;
		origin.x -= [string sizeWithAttributes:navButtonTextAttributes].width / 2;
		[string drawAtPoint:origin withAttributes:navButtonTextAttributes];
	}
}

#pragma mark -

-(void)dealloc
{
	[transform release];
	[transformInverted release];
	
	[background release];
	[dial1Background release];
	[dial2Background release];
	
	[dial1StartFade release];
	[dial1EndFade release];
	[dial2StartFade release];
	[dial2EndFade release];
	
	[dial1DayStartLine release];
	[dial2DayStartLine release];
	[dial1DayEndLine release];
	[dial2DayEndLine release];
	[dial1TimeElapsedShade release];
	[dial2TimeElapsedShade release];
	
	[navButtonForwardBackground release];
	[navButtonBackwardBackground release];
	
	[eventInOutFade release];
	[backgroundGradient release];
	[dialMarkOverlayGradient release];
	[glossDarkGradient release];
	[glossOuterRingGrandient release];
	[dialInnerCircleColor release];
	[dialMarksColor release];
	[timeElapsedShadeColorDarken release];
	
	[weekDayTextAttributes release];
	[weekendDayTextAttributes release];
	[dateTextAttributes release];
	[monthTextAttributes release];
	[navButtonTextAttributes release];
	
	[dial1Gloss release];
	[dial2Gloss release];
	
	[events release];
	[tasks release];
	[dayEvents release];
	 
	[super dealloc];
}

@end
