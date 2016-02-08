//
//  FSCalPriorityIndexValueTransformer.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 13.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSCalPriorityIndexValueTransformer.h"
#import <CalendarStore/CalendarStore.h>

@implementation FSCalPriorityIndexValueTransformer

+(Class)transformedValueClass
{
    return [NSNumber class];
}

+(BOOL)allowsReverseTransformation
{
    return YES;
}

-(id)transformedValue:(id)value
{
	switch([value intValue]){
		case CalPriorityNone : return [NSNumber numberWithInt:0];
		case CalPriorityLow : return [NSNumber numberWithInt:1];
		case CalPriorityMedium : return [NSNumber numberWithInt:2];
		case CalPriorityHigh : return [NSNumber numberWithInt:3];
		default : return [NSNumber numberWithInt:-1];
	}
}

- (id)reverseTransformedValue:(id)value
{
	switch([value intValue]){
		case 0 : return [NSNumber numberWithInt:CalPriorityNone];
		case 1 : return [NSNumber numberWithInt:CalPriorityLow];
		case 2 : return [NSNumber numberWithInt:CalPriorityMedium];
		case 3 : return [NSNumber numberWithInt:CalPriorityHigh];
		default : return [NSNumber numberWithInt:CalPriorityNone];
	}
}

@end
