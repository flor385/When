//
//  FSItemInfoPanel.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 4.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSItemInfoEditPanel.h"


@implementation FSItemInfoEditPanel

static FSItemInfoEditPanel* sharedPanel = nil;

+(FSItemInfoEditPanel*)sharedPanel
{
	if(sharedPanel == nil){
		NSRect frame = NSMakeRect(50, 50, 50, 50);
		sharedPanel = [[FSItemInfoEditPanel alloc] initWithContentRect:frame 
														 styleMask:NSHUDWindowMask | 
					   NSUtilityWindowMask | NSTitledWindowMask | NSClosableWindowMask
														   backing:NSBackingStoreBuffered 
															 defer:NO];
	}
	
	return sharedPanel;
}

-(id)initWithContentRect:(NSRect)contentRect 
			   styleMask:(NSUInteger)windowStyle 
				 backing:(NSBackingStoreType)bufferingType 
				   defer:(BOOL)deferCreation
{
	if(self == [super initWithContentRect:contentRect 
								styleMask:windowStyle 
								  backing:bufferingType 
									defer:deferCreation])
	{
		[self customInit];
	}
	
	return self;
}

-(void)customInit
{
	[self setTitle:@"Calendar item info"];
	
	// view controllers
	eventInfoController = [FSItemInfoController sharedEventInfoController];
	taskInfoController = [FSItemInfoController sharedTaskInfoController];
	eventEditController = [FSItemEditController sharedEventEditController];
	taskEditController = [FSItemEditController sharedTaskEditController];
	
	/* SUBVIEWS */
	
	NSView* view = [eventInfoController view];
	[[self contentView] addSubview:view];
	[view setFrameOrigin:NSZeroPoint];
	[view setHidden:NO];
	
	view = [taskInfoController view];
	[[self contentView] addSubview:view];
	[view setFrameOrigin:NSZeroPoint];
	[view setHidden:YES];
	
	view = [eventEditController view];
	[[self contentView] addSubview:view];
	[view setFrameOrigin:NSZeroPoint];
	[view setHidden:YES];
	
	view = [taskEditController view];
	[[self contentView] addSubview:view];
	[view setFrameOrigin:NSZeroPoint];
	[view setHidden:YES];
	
	[[self contentView] setAutoresizesSubviews:NO];
	
	// set the frame for the first launch, when there is no preference
	NSRect f = [self frameRectForContentRect:[[eventInfoController view] frame]];
	NSRect screenFrame = [[self screen] frame];
	f.origin.x = screenFrame.origin.x + screenFrame.size.width - (f.size.width + 50);
	f.origin.y = screenFrame.origin.y + screenFrame.size.height - (f.size.height + 50);
	[self setFrame:f display:NO animate:NO];
	
	// bind the window frame to user defaults
	[self setFrameAutosaveName:@"FSItemInfoPanel"];
	[self setFrameUsingName:@"FSItemInfoPanel" force:YES];
	
	// Resize the window
	NSRect newWindowFrame = [self frameRectForContentRect:[[eventInfoController view] frame]];
	newWindowFrame.origin = [self frame].origin;
	newWindowFrame.origin.y -= newWindowFrame.size.height - [self frame].size.height;
	[self setFrame:newWindowFrame display:NO animate:NO];
}

-(void)showEvents:(NSArray*)events
{
	currentActivity = FSCurrentlyViewing;
	[eventInfoController displayItems:events];
	[self updateDisplayState:YES editing:NO];
}

-(void)showTasks:(NSArray*)tasks
{
	currentActivity = FSCurrentlyViewing;
	[taskInfoController displayItems:tasks];
	[self updateDisplayState:NO editing:NO];
}

-(void)editEvents:(NSArray*)events
{
	currentActivity = FSCurrentlyEditing;
	[eventEditController startEditingItems:events];
	[self updateDisplayState:YES editing:YES];
}

-(void)editTasks:(NSArray*)tasks
{
	currentActivity = FSCurrentlyEditing;
	[taskEditController startEditingItems:tasks];
	[self updateDisplayState:NO editing:YES];
}

-(void)addEvents:(NSArray*)events
{
	currentActivity = FSCurrentlyAdding;
	[eventEditController startAddingItems:events];
	[self updateDisplayState:YES editing:YES];
}

-(void)addTasks:(NSArray*)tasks
{
	currentActivity = FSCurrentlyAdding;
	[taskEditController startAddingItems:tasks];
	[self updateDisplayState:NO editing:YES];
}

-(void)doTheSameWithNewItems:(NSArray*)items canContinueAdding:(BOOL)canContinueAdding;
{
	if([items count] == 0) return;
	BOOL events = [[items objectAtIndex:0] isKindOfClass:[CalEvent class]];
	
	switch(currentActivity){
		case FSCurrentlyViewing:
			if(events)
				[self showEvents:items];
			else
				[self showTasks:items];
			break;
		case FSCurrentlyEditing:
			if(events)
				[self editEvents:items];
			else
				[self editTasks:items];
			break;
		case FSCurrentlyAdding:
			if(canContinueAdding){
				if(events)
					[self addEvents:items];
				else
					[self addTasks:items];
			}else{
				if(events)
					[self editEvents:items];
				else
					[self editTasks:items];
			}
			break;
	}
}

-(void)updateDisplayState:(BOOL)events editing:(BOOL)editing;
{
	// which display are we viewing?
	NSView* toDisplayView = events ? 
	(editing ? [eventEditController view] : [eventInfoController view]) : 
	(editing ? [taskEditController view] : [taskInfoController view]);
	
	if([toDisplayView isHidden]){
		
		// hide all the views except the one we are displaying
		for(NSView* view in [[self contentView] subviews])
			if(view != toDisplayView)
				[view setHidden:view != toDisplayView];
		
		// Resize the window
		NSRect newWindowFrame = [self frameRectForContentRect:[toDisplayView frame]];
		newWindowFrame.origin = [self frame].origin;
		newWindowFrame.origin.y -= newWindowFrame.size.height - [self frame].size.height;
		[self setFrame:newWindowFrame display:YES animate:[self isVisible]];
		
		[toDisplayView setHidden:NO];
	}
	
	if(![self isVisible]) [self orderFrontRegardless];
	[NSApp activateIgnoringOtherApps:YES];
	[self makeKeyAndOrderFront:self];
}

-(BOOL)canBecomeKeyWindow{
	return YES;
}

-(BOOL)canBecomeMainWindow{
	return NO;
}

-(void)orderOut:(id)sender
{
	[super orderOut:sender];
}

@end
