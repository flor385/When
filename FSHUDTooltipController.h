//
//  FSHUDTooltipController.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 13.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FSHUDTooltipView.h"

@class FSHUDTooltipView;

@interface FSHUDTooltipController : NSWindowController {

	IBOutlet FSHUDTooltipView* tooltipView;
}

+(FSHUDTooltipController*)defaultController;
+(void)updateAndDisplay;
+(void)updateOrigin;
+(void)orderOut;
-(void)update;
-(void)updateOrigin;

@end
