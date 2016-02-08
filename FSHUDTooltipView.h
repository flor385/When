//
//  FSHUDTooltipView.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 13.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FSHUDTooltipView : NSView {

	NSString* text;
	NSDictionary* textAttributes;
	NSBezierPath* background;
	NSColor* backgroundColor;
}

-(void)customInit;
-(void)update;
-(void)updateFrame;

@end
