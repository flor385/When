//
//  FSCalendarsPreferenceController.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 06 12.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSCalendarsPreferenceController.h"
#import "FSCalendarsManager.h"
#import "FSCalendarMapping.h"
#import "FSColorCell.h"
#import "FSCalCalendarAdditions.h"

#define TABLE_ROW_INDICES_PB_TYPE @"TableRowIndicesPBType"

@implementation FSCalendarsPreferenceController

#pragma mark -
#pragma mark Instance creation, MBPreferencesModule implementation

+(FSCalendarsPreferenceController*)instance
{
	FSCalendarsPreferenceController* rVal = 
	[[FSCalendarsPreferenceController alloc] initWithNibName:@"CalendarsPreferenceView" 
													  bundle:nil];
	
	[rVal autorelease];
	return rVal;
}

- (NSString *)title
{
	return @"Calendars";
}

-(NSString *)identifier
{
	return @"FSWhenCalendarsPerferenceModule";
}

-(NSImage *)image
{
	return [NSImage imageNamed:@"CalendarsPreference"];
}

#pragma mark -
#pragma mark Init and setup

-(id)initWithNibName:(NSString*)nibName bundle:(NSBundle*)bundle
{
	if(self == [super initWithNibName:nibName bundle:bundle]){
		// we are interested in hearing about changes to preferences
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(prefsChanged:) 
													 name:NSUserDefaultsDidChangeNotification 
												   object:[NSUserDefaults standardUserDefaults]];
	}
	
	return self;
}

-(void)awakeFromNib
{
	// tweak the table
	// enable drag and drop
	[calendarsTable registerForDraggedTypes:[NSArray arrayWithObject:TABLE_ROW_INDICES_PB_TYPE]];
	
	// set the second column of the table to have a button cell editor
	NSArray* tableColumns = [calendarsTable tableColumns];
	NSButtonCell* checkboxCell = [NSButtonCell new];
	[checkboxCell setButtonType:NSSwitchButton];
	[checkboxCell setTitle:nil];
	[checkboxCell setImagePosition:NSImageOnly];
	[checkboxCell setControlSize:NSSmallControlSize];
	[[tableColumns objectAtIndex:1] setDataCell:checkboxCell];
	[[tableColumns objectAtIndex:4] setDataCell:[FSColorCell new]];
	
	// set the identifiers of table column to be their initial index
	for(int i = 0 , c = [tableColumns count] ; i < c ; i++)
		[((NSTableColumn*)[tableColumns objectAtIndex:i]) setIdentifier:[NSNumber numberWithInt:i]];
}

-(void)prefsChanged:(NSNotification*)notification
{
	[calendarsTable reloadData];
}


#pragma mark -
#pragma mark Calendars table data source methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[FSCalendarsManager sharedManager].calendarMappings count];
}

- (id)tableView:(NSTableView *)aTableView 
objectValueForTableColumn:(NSTableColumn *)aTableColumn 
			row:(NSInteger)rowIndex
{
	FSCalendarMapping* calMap = [[FSCalendarsManager sharedManager].calendarMappings objectAtIndex:rowIndex];
	
	NSNumber* columnID = [aTableColumn identifier];
	switch([columnID intValue]){
		case 0 : return [NSNumber numberWithInteger:rowIndex +1];
		case 1 : return calMap.enabled;
		case 2 : return calMap.calendar.title;
		case 3 : return [calMap.calendar typeString];
		case 4 : return calMap.calendar.color;
		
		default : return nil;
	}
}

- (void)tableView:(NSTableView *)aTableView 
   setObjectValue:(id)anObject 
   forTableColumn:(NSTableColumn *)aTableColumn 
			  row:(NSInteger)rowIndex
{
	
	NSNumber* columnID = [aTableColumn identifier];
	switch([columnID intValue]){
		
		// calendar name (title)
		case 2 : {
			
			// ignore empty strings
			if([((NSString*)anObject) length] == 0){
				NSRunAlertPanel(@"The calendar must have a name", 
								@"Empty calendar names are not allowed", @"OK", nil, nil);
				return;
			}
				
			CalCalendar* calendar = ((FSCalendarMapping*)[[FSCalendarsManager sharedManager].calendarMappings 
										 objectAtIndex:rowIndex]).calendar;
			
			NSString* oldTitle = [[calendar.title copy] autorelease];
			calendar.title = anObject;
			if([calendar saveChangesToSelf])
				return;
			else{
				// failed to save, revert the change
				calendar.title = oldTitle;
				[calendarsTable reloadData];
			}
		}
		
		// cal map enabled state change
		case 1 : {
			FSCalendarMapping* calMap = [[FSCalendarsManager sharedManager].calendarMappings 
										 objectAtIndex:rowIndex];
			[calMap setEnabled:(NSNumber*)anObject];
			return;
		}
		default : return;
	}	
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    // Copy the row numbers to the pasteboard.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:TABLE_ROW_INDICES_PB_TYPE] owner:self];
    [pboard setData:data forType:TABLE_ROW_INDICES_PB_TYPE];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv 
				validateDrop:(id <NSDraggingInfo>)info 
				 proposedRow:(NSInteger)row 
	   proposedDropOperation:(NSTableViewDropOperation)op
{
	if(op != NSTableViewDropAbove) return NSDragOperationNone;
	
	// get the row indexes being dragged
	NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:TABLE_ROW_INDICES_PB_TYPE];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
	int rowBeingDragged = [rowIndexes firstIndex];
	
	if(rowBeingDragged == row || rowBeingDragged == row - 1)
		return NSDragOperationNone;
	
	return NSDragOperationMove;
}

- (BOOL)tableView:(NSTableView *)aTableView
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(NSInteger)row
	dropOperation:(NSTableViewDropOperation)operation
{
	 // get the row indexes being dragged
	NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:TABLE_ROW_INDICES_PB_TYPE];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
	int rowBeingDragged = [rowIndexes firstIndex];
	
	// perform the reordering
	[[FSCalendarsManager sharedManager] moveCalendarWithPriority:rowBeingDragged toPriority:row];
	
	return YES;
}

#pragma mark -
#pragma mark Calendar adding / removal

-(IBAction)deleteCalendar:(id)sender
{
	FSCalendarsManager* calManager = [FSCalendarsManager sharedManager];
	
	// get the calendar being deleted
	int clickedRow = [calendarsTable clickedRow];
	FSCalendarMapping* clickedMapping = [calManager.calendarMappings objectAtIndex:clickedRow];
	CalCalendar* calendar = clickedMapping.calendar;
	
	NSString* title = [NSString stringWithFormat:@"Are you sure you want to delete \"%@\"?", calendar.title];
	NSBeginAlertSheet(
					  title,					// sheet message
					  @"Delete",              // default button label
					  nil,                    // no third button
					  @"Cancel",              // other button label
					  [[self view] window],   // window sheet is attached to
					  self,                   // we’ll be our own delegate
					  @selector(sheetDidEndShouldDelete:returnCode:contextInfo:),
					  // did-end selector
					  NULL,                   // no need for did-dismiss selector
					  calendar,                 // context info
					  @"All the items in the calendar will be permanently deleted.");
	
	
}

-(void)sheetDidEndShouldDelete:(NSWindow *)sheet 
					returnCode:(int)returnCode 
				   contextInfo:(void*)contextInfo
{
	if(returnCode == NSAlertDefaultReturn)
		[((CalCalendar*)contextInfo) deleteSelf];
}

-(BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	SEL action = [menuItem action];
	
	if(action == @selector(deleteCalendar:)){
		
		int clickedIndex = [calendarsTable clickedRow];
		if(clickedIndex == -1) return NO;
		
		// a row was clicked
		// find out it if it is deletable calendar
		FSCalendarMapping* calMap = 
			[[FSCalendarsManager sharedManager].calendarMappings objectAtIndex:clickedIndex];
		NSString* calendarType = calMap.calendar.type;
	
		return [CalCalendarTypeLocal isEqualToString:calendarType] 
			|| [CalCalendarTypeSubscription isEqualToString:calendarType]
			|| [CalCalendarTypeBirthday isEqualToString:calendarType];
	}
		
	else if(action == @selector(newCalendar:))
		return YES;
	
	return YES;
}

@end
