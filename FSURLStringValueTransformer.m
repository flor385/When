//
//  FSURLStringValueTransformer.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 12.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSURLStringValueTransformer.h"


@implementation FSURLStringValueTransformer

+(Class)transformedValueClass
{
    return [NSString class];
}

+(BOOL)allowsReverseTransformation
{
    return YES;
}

-(id)transformedValue:(id)value
{
	if(value == nil) return nil;
	NSURL* url = (NSURL*)value;
	return [url absoluteString];
}

- (id)reverseTransformedValue:(id)value
{
	if(value == nil) return nil;
	if(![value isKindOfClass:[NSString class]])
		value = [value description];
	
	return [NSURL URLWithString:(NSString*)value];
}

@end
