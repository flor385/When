//
//  FSWhenUtil.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 19.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSWhenUtil.h"


@implementation FSWhenUtil

+(FSRange)rangeWithLoc:(NSInteger)location lenght:(NSUInteger)length
{
	FSRange rVal;
	rVal.location = location;
	rVal.length = length;
	
	return rVal;
}

+(BOOL)integer:(NSInteger)integer isInRange:(FSRange)range
{
	return integer >= range.location && integer < ((NSInteger)(range.location + range.length));
}

@end
