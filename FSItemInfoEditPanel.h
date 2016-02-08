//
//  FSItemInfoPanel.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 4.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FSItemEditController.h"
#import "FSDialsViewInput.h"

@interface FSItemInfoEditPanel : NSPanel {

	FSItemInfoController* eventInfoController;
	FSItemInfoController* taskInfoController;
	FSItemEditController* eventEditController;
	FSItemEditController* taskEditController;
	
	int currentActivity;
}

enum{
	FSCurrentlyViewing,
	FSCurrentlyEditing,
	FSCurrentlyAdding
};

+(FSItemInfoEditPanel*)sharedPanel;

-(void)customInit;
-(void)showEvents:(NSArray*)events;
-(void)showTasks:(NSArray*)tasks;
-(void)editEvents:(NSArray*)events;
-(void)editTasks:(NSArray*)tasks;
-(void)addEvents:(NSArray*)events;
-(void)addTasks:(NSArray*)tasks;
-(void)doTheSameWithNewItems:(NSArray*)items canContinueAdding:(BOOL)canContinueAdding;
-(void)updateDisplayState:(BOOL)events editing:(BOOL)editing;

@end
