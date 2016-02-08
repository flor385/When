//
//  FSColorCell.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 12.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSColorCell.h"


@implementation FSColorCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	float smallerLength = fmin(cellFrame.size.width, cellFrame.size.height);
	NSRect ovalRect = NSMakeRect(cellFrame.origin.x + (cellFrame.size.width - smallerLength) / 2,
								 cellFrame.origin.y + (cellFrame.size.height - smallerLength) / 2,
								 smallerLength,
								 smallerLength);
	
	
	ovalRect = [self reducedRect:ovalRect by:smallerLength / 2.5];
	
	NSBezierPath* circle = [NSBezierPath bezierPathWithOvalInRect:ovalRect];
	[circle setLineWidth:smallerLength / 6];
	
	NSColor* colorValue = [self objectValue];
	[[colorValue colorWithAlphaComponent:0.3] set];
	[circle fill];
	
	[colorValue set];
	[circle stroke];
}

-(NSRect)reducedRect:(NSRect)rect by:(float)reduction
{
	float halfReduction = reduction / 2;
	return NSMakeRect(rect.origin.x + halfReduction,
					  rect.origin.y + halfReduction,
					  rect.size.width - reduction,
					  rect.size.height - reduction);
}

@end
