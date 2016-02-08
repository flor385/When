//
//  FSWhenUtil.h
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 19.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FSWhenUtil : NSObject {
	
}

typedef struct _FSRange {
	NSInteger location;
	NSUInteger length;
} FSRange;

+(FSRange)rangeWithLoc:(NSInteger)location lenght:(NSUInteger)length;
+(BOOL)integer:(NSInteger)integer isInRange:(FSRange)range;

@end
