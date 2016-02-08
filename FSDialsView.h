//
//  FSDialsViewLogic.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 23.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FSPreferencesController.h"
#import "FSWhenGeometry.h"
#import "FSCalendarsManager.h"
#import "FSCalItemRepresentation.h"
#import "FSCalItemGeometry.h"

@interface FSDialsView : NSView {

	// properties
	int earlyDialPosition;
	int flowDirection;
	int offset;
	int taskDisplayStyle;
	int dayEventDisplayStyle;
	
	/* GEOMETRY */
	
	float sizeProportion;
	int backgroundShape;
	
	NSAffineTransform* transform;
	NSAffineTransform* transformInverted;
	
	// background of the window
	NSBezierPath* background;
	
	// dials
	NSBezierPath* dial1Background;
	NSBezierPath* dial2Background;
	
	// day break fade in / fade out
	NSBezierPath* dial1StartFade;
	NSBezierPath* dial1EndFade;
	NSBezierPath* dial2StartFade;
	NSBezierPath* dial2EndFade;
	
	// nav buttons
	NSBezierPath* navButtonForwardBackground;
	NSBezierPath* navButtonBackwardBackground;
	
	// elapsed time geometry
	NSBezierPath* dial1DayStartLine;
	NSBezierPath* dial2DayStartLine;
	NSBezierPath* dial1DayEndLine;
	NSBezierPath* dial2DayEndLine;
	NSBezierPath* dial1TimeElapsedShade;
	NSBezierPath* dial2TimeElapsedShade;
	
	// text rendering
	NSMutableDictionary* weekDayTextAttributes;
	NSMutableDictionary* weekendDayTextAttributes;
	NSMutableDictionary* dateTextAttributes;
	NSMutableDictionary* monthTextAttributes;
	NSMutableDictionary* navButtonTextAttributes;
	
	// events and tasks
	NSMutableArray* events;
	NSMutableArray* tasks;
	NSMutableArray* dayEvents;
	
	// gloss
	NSBezierPath* dial1Gloss;
	NSBezierPath* dial2Gloss;
	
	/* COLORS */
	
	NSGradient* eventInOutFade;
	NSGradient* backgroundGradient;
	NSGradient* dialMarkOverlayGradient;
	NSGradient* glossDarkGradient;
	NSGradient* glossOuterRingGrandient;
	NSColor* dialInnerCircleColor;
	NSColor* dialMarksColor;
	NSColor* timeElapsedShadeColorDarken;
}

@property int earlyDialPosition;
@property int offset;
@property int backgroundShape;
@property int taskDisplayStyle;
@property int dayEventDisplayStyle;
@property int flowDirection;

-(int)lateDialPosition;

-(void)customInit;
-(void)colorsInit;
-(void)textAttributesInit;

#pragma mark Size and subview stuff
-(void)updateSize;

#pragma mark Geometry calculations
-(void)updateAllGeometry;
-(void)updateEventGeometry;
-(void)updateTaskGeometry;
-(void)updateBackgroundGeometry;
-(void)updateElapsedTimeGeometry;
-(void)updateGlossGeometry;
-(void)updateNavButtonGeometry;
-(void)updateEventFadeGeometry;

#pragma mark Drawing
-(void)drawTransparentBackgroundGeometry;
-(void)drawBackgroundGeometry;
-(void)drawElapsedTimeGeometry;
-(void)drawText;
-(void)drawDialTickMarks;
-(void)drawTasks;
-(void)drawEvents;
-(void)drawGloss;
-(void)drawNavButtons;

@end
