//
//  FSEmptyView.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 23.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSEmptyView.h"


@implementation FSEmptyView

-(id)initWithCoder:(NSCoder*)coder
{
	if(self == [super initWithCoder:coder])
		[self setAutoresizesSubviews:NO];
	
	return self;
}

-(id)initWithFrame:(NSRect)frame
{
	if(self == [super initWithFrame:frame])
		[self setAutoresizesSubviews:NO];
	
	return self;
}

-(void)drawRect:(NSRect)dirtyRect
{
	[[NSColor clearColor] set];
	NSRectFill([self bounds]);
}

@end
