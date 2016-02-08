//
//  FSMainWindow.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 23.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSMainWindow.h"
#import "FSPreferencesController.h"

@implementation FSMainWindow

-(void)awakeFromNib
{
	// we need this for all sorts of stuff
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	
	// add the anchor view
	anchorViewController = [FSDialsViewController new];
	FSDialsView* newView = (FSDialsView*)[anchorViewController view];
	newView.offset = [ud integerForKey:FSAnchorDialViewOffsetPreference];
	[emptyView addSubview:newView];
	
	// set some user defaults
	sizeProportion = [ud floatForKey:FSWhenSizePreference];
	earlyDialPosition = [ud integerForKey:FSDialPositionPreference];
	flowDirection = [ud integerForKey:FSDialFlowPreference];
	backgroundShape = [ud integerForKey:FSBackgroundShapePreference];
	self.alwaysOnTop = [ud boolForKey:FSAlwaysOnTopPreference];
	
	// bind some user defaults
	[self bind:@"sizeProportion" 
	  toObject:ud 
   withKeyPath:FSWhenSizePreference
	   options:nil];
	[self bind:@"earlyDialPosition" 
	  toObject:ud
   withKeyPath:FSDialPositionPreference
	   options:nil];
	[self bind:@"flowDirection" 
	  toObject:ud
   withKeyPath:FSDialFlowPreference
	   options:nil];
	[self bind:@"backgroundShape" 
	  toObject:ud
   withKeyPath:FSBackgroundShapePreference
	   options:nil];
	[self bind:@"alwaysOnTop" 
	  toObject:ud
   withKeyPath:FSAlwaysOnTopPreference
	   options:nil];
	
	// add the necessary forward / backward dials
	for(int i = 0, c = [ud integerForKey:FSNumberOfForwardDialsPreference] ; i < c ; i++)
		[self addDialViewToFront:YES updateGUI:NO];
	for(int i = 0, c = [ud integerForKey:FSNumberOfBackwardDialsPreference] ; i < c ; i++)
		[self addDialViewToFront:NO updateGUI:NO];
	
	// set the position
	int originX = [ud integerForKey:FSMainWindowOriginX];
	int originY = [ud integerForKey:FSMainWindowOriginY];
	[self setFrameOrigin:NSMakePoint(originX, originY)];
	
	// set the sizes and positions
	[self updateSizesAndPositionsAndKeepCentered:NO offsetOrigin:NSZeroSize];
}

-(void)addDialViewToFront:(BOOL)toFront updateGUI:(BOOL)updateGUI
{
	// figure out the offset of the view we will be adding
	int offset = toFront ? [FSDialsViewController highestOffset] : [FSDialsViewController lowestOffset];
	if(toFront) offset++;
	else offset--;
	
	// we have the offset of the view to add, initialize the view itself
	FSDialsView* newView = (FSDialsView*)[[[FSDialsViewController alloc] init] view];
	newView.offset = offset;
	[emptyView addSubview:newView];
	
	// if we don't need to manip the GUI, we are done here
	if(!updateGUI) return;
	
	// if we are adding to back, we need to modify the origin of this window
	NSSize originOffset = NSMakeSize(0.0f, 0.0f);
	NSSize anchorViewSize = [[anchorViewController view] frame].size;
	
	if((toFront && flowDirection == FSDialFlowDownward) 
			|| (!toFront && flowDirection == FSDialFlowUpward))
		originOffset.height -= anchorViewSize.height + DIAL_VIEW_SPACING;
	if((toFront && flowDirection == FSDialFlowLeftward)
			|| (!toFront && flowDirection == FSDialFlowRightward))
		originOffset.width -= anchorViewSize.width + DIAL_VIEW_SPACING;
	
	// reposition everything
	[self updateSizesAndPositionsAndKeepCentered:NO offsetOrigin:originOffset];
}

-(void)removeDialViewFromFront:(BOOL)fromFront updateGUI:(BOOL)updateGUI
{
	// remove the view and it's controller
	int offset = fromFront ? [FSDialsViewController highestOffset] : [FSDialsViewController lowestOffset];
	FSDialsViewController* controller = [FSDialsViewController existingControllerWithOffset:offset];
	[[controller view] removeFromSuperviewWithoutNeedingDisplay];
	[FSDialsViewController removeController:controller];
	
	// make all the views update their nav buttons
	for(FSDialsView* view in [FSDialsViewController allCurrentDialViewsSorted])
		[view updateNavButtonGeometry];
		
	// if we don't need to manip the GUI, we are done here
	if(!updateGUI) return;
	
	// if we are removing from the back, we need to modify the origin of this window
	NSSize originOffset = NSMakeSize(0.0f, 0.0f);
	NSSize anchorViewSize = [[anchorViewController view] frame].size;
	
	if((fromFront && flowDirection == FSDialFlowDownward) 
	   || (!fromFront && flowDirection == FSDialFlowUpward))
		originOffset.height += anchorViewSize.height + DIAL_VIEW_SPACING;
	if((fromFront && flowDirection == FSDialFlowLeftward)
	   || (!fromFront && flowDirection == FSDialFlowRightward))
		originOffset.width += anchorViewSize.width + DIAL_VIEW_SPACING;
	
	// reposition everything
	[self updateSizesAndPositionsAndKeepCentered:NO offsetOrigin:originOffset];
}

-(void)updateSizesAndPositionsAndKeepCentered:(BOOL)keepCentered offsetOrigin:(NSSize)offset
{
	// first some info
	FSDialsView* anchorView = (FSDialsView*)[anchorViewController view];
	NSSize anchorSize = [anchorView frame].size;
	float dialViewSpacing = DIAL_VIEW_SPACING * sizeProportion;
	
	// now go through all the views, set their origins
	NSArray* dialViews = [FSDialsViewController allCurrentDialViewsSorted];
	int count = [dialViews count];
	for(int i = 0 ; i < count ; i++){
		float x = 0.0f;
		float y = 0.0f;
		if(flowDirection == FSDialFlowDownward)
			y = (count - 1 - i) * (dialViewSpacing + anchorSize.height);
		else if(flowDirection == FSDialFlowUpward)
			y = i * (dialViewSpacing + anchorSize.height);
		else if(flowDirection == FSDialFlowRightward)
			x = i * (dialViewSpacing + anchorSize.width);
		else if(flowDirection == FSDialFlowLeftward)
			x = (count - 1 - i) * (dialViewSpacing + anchorSize.width);
			
		NSView* dialView = [dialViews objectAtIndex:i];
		[dialView setFrameOrigin:NSMakePoint(x, y)];
	}
		
	// finally, set the size of the frame
	BOOL flowHorizontally = flowDirection == FSDialFlowLeftward || flowDirection == FSDialFlowRightward;
	
	// figure the new width and height out
	float width = !flowHorizontally ? anchorSize.width : 
		(anchorSize.width * count + dialViewSpacing * (count - 1));
	float height = flowHorizontally ? anchorSize.height : 
		(anchorSize.height * count + dialViewSpacing * (count - 1));
	
	// update  the origin
	NSPoint origin = [self frame].origin;
	origin.x += offset.width;
	origin.y += offset.height;
	
	if(keepCentered){
		NSSize sizeBefore = [self frame].size;
		origin.x += (sizeBefore.width - width) / 2;
		origin.y += (sizeBefore.height - height) / 2;
	}
	
	[self setFrame:NSMakeRect(origin.x, origin.y, width, height) display:YES];
}

-(IBAction)center:(id)sender
{
	NSSize windowSize = [self frame].size;
	NSSize screenSize = [[self screen] frame].size;
	
	[self setFrameOrigin:NSMakePoint((screenSize.width - windowSize.width) / 2,
									 (screenSize.height - windowSize.height) / 2)];
}

#pragma mark -
#pragma mark Bound properties

-(float)sizeProportion { return sizeProportion; }

-(void)setSizeProportion:(float)newProportion
{
	sizeProportion = newProportion;
	
	// update the sizes of all the current dial views
	for(FSDialsView* dialsView in [FSDialsViewController allCurrentDialViewsSorted])
		[dialsView updateSize];
	
	// update our own size
	[self updateSizesAndPositionsAndKeepCentered:NO  offsetOrigin:NSZeroSize];
}

-(int)earlyDialPosition { return earlyDialPosition; }

-(void)setEarlyDialPosition:(int)newPosition
{
	if(earlyDialPosition == newPosition) return;
	earlyDialPosition = newPosition;
	
	// update the sizes of all the current dial views
	for(FSDialsView* dialsView in [FSDialsViewController allCurrentDialViewsSorted]){
		[dialsView setEarlyDialPosition:earlyDialPosition];
		[dialsView setNeedsDisplay:YES];
	}
		
	// update our own size
	[self updateSizesAndPositionsAndKeepCentered:YES offsetOrigin:NSZeroSize];
}

-(int)flowDirection { return flowDirection; }

-(void)setFlowDirection:(int)newDirection
{
	if(flowDirection == newDirection) return;
	flowDirection = newDirection;
	
	// update the flow of all the current dial views
	for(FSDialsView* dialsView in [FSDialsViewController allCurrentDialViewsSorted]){
		dialsView.flowDirection = flowDirection;
		[dialsView setNeedsDisplay:YES];
	}
	
	// update our own size
	[self updateSizesAndPositionsAndKeepCentered:YES offsetOrigin:NSZeroSize];
}

-(int)backgroundShape { return backgroundShape; }

-(void)setBackgroundShape:(int)newStyle
{
	if(backgroundShape == newStyle) return;
	backgroundShape = newStyle;
	
	// make all the views update
	for(FSDialsView* view in [FSDialsViewController allCurrentDialViewsSorted])
		view.backgroundShape = backgroundShape;
		
	[self invalidateShadow];
	[self display];
	[self invalidateShadow];
}

-(BOOL)alwaysOnTop { return alwaysOnTop; }

-(void)setAlwaysOnTop:(BOOL)flag
{
	alwaysOnTop = flag;
	[self setLevel:alwaysOnTop ? NSStatusWindowLevel : NSNormalWindowLevel];
}

#pragma mark -
#pragma mark Accessors

-(FSDialsViewController*)anchorViewController
{
	return anchorViewController;
}

#pragma mark -
#pragma mark NSWindow stuff

-(BOOL)canBecomeKeyWindow
{
    return YES;
}

-(void)dealloc
{
	[anchorViewController release];
	[super dealloc];
}

@end
