//
//  FSMainWindow.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 23.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FSDialsView.h"
#import "FSDialsViewController.h"
#import "FSPreferencesController.h"
#import "FSEmptyView.h"
#import "FSEmptyWindow.h"

@interface FSMainWindow : FSEmptyWindow {

	IBOutlet FSEmptyView* emptyView;
	FSDialsViewController* anchorViewController;
	
	float sizeProportion;
	int earlyDialPosition;
	int flowDirection;
	int backgroundShape;
	BOOL alwaysOnTop;
}

@property float sizeProportion;
@property int earlyDialPosition;
@property int flowDirection;
@property int backgroundShape;
@property BOOL alwaysOnTop;

-(FSDialsViewController*)anchorViewController;

-(IBAction)center:(id)sender;

-(void)updateSizesAndPositionsAndKeepCentered:(BOOL)keepCentered offsetOrigin:(NSSize)offset;
-(void)addDialViewToFront:(BOOL)toFront updateGUI:(BOOL)updateGUI;
-(void)removeDialViewFromFront:(BOOL)fromFront updateGUI:(BOOL)updateGUI;


@end
