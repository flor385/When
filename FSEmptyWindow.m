//
//  FSEmptyWindow.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 13.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSEmptyWindow.h"

@implementation FSEmptyWindow

-(id)initWithContentRect:(NSRect)contentRect 
			   styleMask:(NSUInteger)aStyle 
				 backing:(NSBackingStoreType)bufferingType 
				   defer:(BOOL)flag
{
    // Using NSBorderlessWindowMask results in a window without a title bar.
    self = [super initWithContentRect:contentRect 
							styleMask:NSBorderlessWindowMask 
							  backing:bufferingType 
								defer:flag];
    if (self != nil) {
		// some tweaking
		[self setOpaque:NO];
	}
	
    return self;
}

@end
