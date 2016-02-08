//
//  FSArrayObjectTransformer.m
//  ArrayPopupBinding
//
//  Created by Florijan Stamenkovic on 2009 08 13.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSArrayProxyObjectTransformer.h"

@implementation FSArrayProxyObjectTransformer

+(BOOL)allowsReverseTransformation
{
	return YES;
}

+(Class)transformedValueClass
{
	return [NSArray class];
}

-(id)transformedValue:(id)value
{
	if(value == nil) return nil;
	
	NSArray* array = (NSArray*)value;
	
	switch([array count]){
		case 0 : return nil;
		case 1 : return [array objectAtIndex:0];
		default : {
			return [[[FSArrayProxy alloc] initWithArray:array] autorelease];
		}
	}
}

-(id)reverseTransformedValue:(id)value
{
	if(value == nil) return nil;
	
	if([value isKindOfClass:[FSArrayProxy class]])
		return ((FSArrayProxy*)value).array;
	
	if([value isKindOfClass:[NSArray class]])
		return value;
	
	return [NSArray arrayWithObject:value];
}

@end






@implementation FSArrayProxy

static NSString* description = @"Multiple items";

+(void)setDescription:(NSString*)aDescription
{
	[aDescription retain];
	[description release];
	description = aDescription;
}

+(NSString*)description
{
	return description;
}

@synthesize array;

-(id)initWithArray:(NSArray*)anArray
{
	[super init];
	array = [anArray retain];
	return self;
}

-(NSString*)description
{
	return description;
}

-(void)dealloc
{
	[array release];
	[super dealloc];
}

@end
