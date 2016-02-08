//
//  FSSeparator.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 22.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSSeparator.h"


@implementation FSSeparator

-(id)initWithFrame:(NSRect)frame
{
	if(self == [super initWithFrame:frame]){
		color = [NSColor blackColor];
	}
	
	return self;
}

-(NSColor*)color
{
	return color;
}

-(void)setColor:(NSColor*)newColor
{
	[newColor retain];
	[color release];
	color = newColor;
	
	[self setNeedsDisplay:YES];
}

-(void)drawRect:(NSRect)rect
{
	[color setStroke];
	[NSBezierPath setDefaultLineWidth:1.0f];
	
	NSRect bounds = [self bounds];
	
	// if width is greater then height, draw hoizontal line
	if(bounds.size.width >= bounds.size.height){
		int y = (int)(bounds.origin.y + (bounds.size.height / 2));
		[NSBezierPath strokeLineFromPoint:NSMakePoint(bounds.origin.x, y) 
								  toPoint:NSMakePoint(bounds.origin.x + bounds.size.width, y)];
	
	// otherwise draw vertical line
	}else{
		int x = (int)(bounds.origin.x + (bounds.size.width / 2));
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x, bounds.origin.y) 
								  toPoint:NSMakePoint(x, bounds.origin.y + bounds.size.height)];
	}
}

@end
