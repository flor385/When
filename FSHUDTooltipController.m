//
//  FSHUDTooltipController.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 13.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSHUDTooltipController.h"
#import "FSPreferencesController.h"

@implementation FSHUDTooltipController

static BOOL shouldDisplay;

+ (void)initialize
{
    if (self == [FSHUDTooltipController class]){
        
		NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
		shouldDisplay = [ud boolForKey:FSDisplayItemTitlesOnHover];
		[ud addObserver:self forKeyPath:FSDisplayItemTitlesOnHover options:0 context:nil];
    }
}

+(void)observeValueForKeyPath:(NSString *)keyPath
					 ofObject:(id)object
					   change:(NSDictionary *)change
					  context:(void *)context
{
	// tool tip
	if([FSDisplayItemTitlesOnHover isEqualToString:keyPath])
		shouldDisplay = [((NSUserDefaults*)object) boolForKey:FSDisplayItemTitlesOnHover];
}

static FSHUDTooltipController* defaultController = nil;

+(FSHUDTooltipController*)defaultController
{
	if(defaultController == nil){
		defaultController = [[FSHUDTooltipController alloc] initWithWindowNibName:@"FSHUDTooltipPanel"];
	}
	
	return defaultController;
}

+(void)updateAndDisplay
{
	if(!shouldDisplay) return;
	
	[[FSHUDTooltipController defaultController] update];
	[[defaultController window] orderFrontRegardless];
}

+(void)updateOrigin
{
	[[self defaultController] updateOrigin];
}

+(void)orderOut
{
	[[[FSHUDTooltipController defaultController] window] orderOut:self];
}
	 
-(void)update
{
	[tooltipView update];
}

-(void)updateOrigin
{
	[tooltipView updateFrame];
}

-(void)awakeFromNib
{
	[[self window] setLevel:NSPopUpMenuWindowLevel];
	[tooltipView update];
}

@end
