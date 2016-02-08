//
//  FSHUDTooltipView.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 13.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSHUDTooltipView.h"
#import "FSDialsViewController.h"
#import <CalendarStore/CalendarStore.h>

#define TEXT_CLEARANCE_HORIZONTAL 7.5
#define TEXT_CLEARANCE_VERTICAL 5.0
#define RECT_ROUNDING 5.0

@implementation FSHUDTooltipView

-(id)initWithFrame:(NSRect)frame
{
	if(self == [super initWithFrame:frame]){
		[self customInit];
	}
	
	return self;
}

-(id)initWithCoder:(NSCoder*)coder
{
	if(self == [super initWithCoder:coder]){
		[self customInit];
	}
	
	return self;
}

-(void)customInit
{
	// init the text Attributes dict
	NSMutableDictionary* dict = [NSMutableDictionary new];
	NSFont* font = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]];
	[dict setValue:font forKey:NSFontAttributeName];
	[dict setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	textAttributes = dict;
	
	backgroundColor = [[NSColor colorWithDeviceWhite:0.0 alpha:0.66] retain];
}

-(void)update
{
	// first update the text
	NSArray* selectedItems = [FSDialsViewController highlightCalItems];
	[text release];
	if([selectedItems count] == 0)
		text = @"Nothing";
	else{
		NSMutableArray* selectedItemTitles = [[NSMutableArray alloc] initWithCapacity:[selectedItems count]];
		for(CalCalendarItem* item in selectedItems){
			[selectedItemTitles addObject:item.title];
		}
			
		text = [[selectedItemTitles componentsJoinedByString:@"\n"] retain];
		[selectedItemTitles release];
	}
	
	// now update the size of self
	NSSize textSize = [text sizeWithAttributes:textAttributes];
	NSRect selfRect = NSMakeRect(0, 0, textSize.width + 2 * TEXT_CLEARANCE_HORIZONTAL, 
								 textSize.height + 2 * TEXT_CLEARANCE_VERTICAL);
	
	// now the background
	[background release];
	background = [NSBezierPath bezierPathWithRoundedRect:selfRect xRadius:RECT_ROUNDING yRadius:RECT_ROUNDING];
	[background retain];
	
	// redraw
	[self setNeedsDisplay:YES];
	
	[self updateFrame];
}

-(void)updateFrame
{
	// now update the size of self
	NSSize textSize = [text sizeWithAttributes:textAttributes];
	NSRect selfRect = NSMakeRect(0, 0, textSize.width + 2 * TEXT_CLEARANCE_HORIZONTAL, 
								 textSize.height + 2 * TEXT_CLEARANCE_VERTICAL);
	
	// update the size and position of the window containing this view
	// first do the basic positioning calc
	NSPoint topLeftWindowCorner = [NSEvent mouseLocation];
	topLeftWindowCorner.x += 10;
	topLeftWindowCorner.y -=10;
	NSRect windowRect = [[self window] frameRectForContentRect:selfRect];
	windowRect.origin.x = topLeftWindowCorner.x;
	windowRect.origin.y = topLeftWindowCorner.y - windowRect.size.height;
	
	// now make sure that the tooltip is inside frame borders
	NSRect screenFrame = [[[self window] screen] visibleFrame];
	float horizontallyClippedOut = (windowRect.origin.x + windowRect.size.width + 10.0f) - screenFrame.size.width;
	if(horizontallyClippedOut > 0.0f)
		windowRect.origin.x -= horizontallyClippedOut;
	
	BOOL isVerticallyClipped = (windowRect.origin.y - windowRect.size.height - 10.f) < 0.0f;
	if(isVerticallyClipped)
		windowRect.origin.y += 20.0f + windowRect.size.height;
	
	[[self window] setFrame:windowRect display:YES];
}

-(void)drawRect:(NSRect)dirtyRect
{
	[[NSColor clearColor] set];
	NSRectFill([self bounds]);
	[backgroundColor set];
	[background fill];
	[text drawAtPoint:NSMakePoint(TEXT_CLEARANCE_HORIZONTAL, TEXT_CLEARANCE_VERTICAL) withAttributes:textAttributes];
}

-(void)dealloc
{
	[textAttributes release];
	[background release];
	[backgroundColor release];
	[super dealloc];
}

@end
