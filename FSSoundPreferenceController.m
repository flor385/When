//
//  FSSoundPreferenceController.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 21.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSSoundPreferenceController.h"
#import "FSSound.h"

@implementation FSSoundPreferenceController

+(FSSoundPreferenceController*)instance
{
	FSSoundPreferenceController* rVal = 
	[[FSSoundPreferenceController alloc] initWithNibName:@"SoundPreferenceView" 
													   bundle:nil];
	
	[rVal autorelease];
	return rVal;
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if(self == [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]){
		
		systemSounds = [[NSArray arrayWithArray:[[FSSound sharedSound] systemSoundNames]] retain];
	}
	
	return self;
}

-(IBAction)newSoundSelected:(id)sender
{
	NSPopUpButton* popup = sender;
	[[FSSound sharedSound] playSound:[[popup selectedItem] representedObject]];
}

-(IBAction)gongPreferenceChanged:(id)sender
{
	if([((NSButton*)sender) state] == NSOnState)
		[[FSSound sharedSound] playGong];
}

- (NSString *)title
{
	return @"Sound";
}

-(NSString *)identifier
{
	return @"FSWhenSoundPreferencePane";
}

-(NSImage *)image
{
	return [NSImage imageNamed:@"Sound"];
}

-(void)dealloc
{
	[systemSounds release];
	[super dealloc];
}

@end
