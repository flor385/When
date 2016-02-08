//
//  FSSoundNameValueTransformer.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 22.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSSoundNameValueTransformer.h"


@implementation FSSoundNameValueTransformer

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
	
	return [((NSSound*)value) name];
}

@end
