//
//  FSCalRecurrenceRuleAdditions.m
//  When
//
//  Created by Florijan Stamenkovic on 2009 07 11.
//  Copyright 2009 FloCo. All rights reserved.
//

#import "FSCalRecurrenceRuleAdditions.h"


@implementation CalRecurrenceRule (FSCalRecurrenceRuleAdditions)

-(NSString*)description{
	return [self recurrenceRuleString];
}

-(NSString*)recurrenceRuleString
{
	if(self.recurrenceInterval == 1)
		switch (self.recurrenceType) {
			case CalRecurrenceDaily:
				return @"Daily";
			case CalRecurrenceWeekly:
				return @"Weekly";
			case CalRecurrenceMonthly:
				return @"Monthly";
			case CalRecurrenceYearly:
				return @"Yearly";
			default:
				return nil;
		}
	else
		switch (self.recurrenceType) {
			case CalRecurrenceDaily:
				return [NSString stringWithFormat:@"Every %d days", self.recurrenceInterval];
			case CalRecurrenceWeekly:
				return [NSString stringWithFormat:@"Every %d weeks", self.recurrenceInterval];
			case CalRecurrenceMonthly:
				return [NSString stringWithFormat:@"Every %d months", self.recurrenceInterval];
			case CalRecurrenceYearly:
				return [NSString stringWithFormat:@"Every %d years", self.recurrenceInterval];
			default:
				return nil;
		}
}

@end
