//
//  NSString+Distance.m
//  Wheelmap
//
//  Created by Hans Seiffert on 28/10/15.
//  Copyright (c) 2015 Sozialhelden e.V. All rights reserved.
//

#import "NSString+Distance.h"

@implementation NSString (Distance)

+ (NSString*)localizedDistanceStringFromMeters:(CGFloat)meters {
	// for larger distances, use miles or kilometres
	if (meters >= 1000.0) {

		BOOL useMetricSystem = [[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue];

		// reuse formatter instance
		static NSNumberFormatter *formatter;
		if (formatter == NO) {
			formatter = [[NSNumberFormatter alloc] init];
			formatter.roundingMode = NSNumberFormatterRoundUp;
			formatter.usesGroupingSeparator = YES;
			formatter.groupingSize = 3;
			formatter.numberStyle = NSNumberFormatterDecimalStyle;

			// use grouping and decimal separators according to locale
			formatter.groupingSeparator = [[NSLocale currentLocale] objectForKey:NSLocaleGroupingSeparator];
			formatter.decimalSeparator = [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator];
		}

		CGFloat distance = (useMetricSystem ? (meters / 1000.0) : (meters / 1609.344)); // 1 Mile = 1609.344 Meters

		// don't use decimal digits for numbers greater than 10
		formatter.maximumFractionDigits = (distance > 10.0 ? 0 : 1);

		NSString *distanceUnit = (useMetricSystem ? @"km" : @"mi");
		NSString *distanceString = [formatter stringFromNumber:@(distance)];
		return [NSString stringWithFormat: @"%@ %@", distanceString, distanceUnit];
	}

	// for smaller distances, always use meters
	return [NSString stringWithFormat: @"%.0f m", meters];
}

@end