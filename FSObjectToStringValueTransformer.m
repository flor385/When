//
//  FSObjectToStringValueTransformer.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 22.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSObjectToStringValueTransformer.h"


@implementation FSObjectToStringValueTransformer

+(Class)transformedValueClass
{
    return [NSString class];
}

+(BOOL)allowsReverseTransformation
{
    return NO;
}

-(id)transformedValue:(id)value
{
	if(value == nil || value == [NSNull null])
		return nil;
	
	return [value description];
}

@end
