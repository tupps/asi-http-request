//
//  ASINSStringRFC1123DataCategoryTests.m
//  Mac
//
//  Created by Luke Tupper on 18/11/10.
//  Copyright 2010 Black Bilby Ltd Pty. All rights reserved.
//

#import "ASINSStringRFC1123DataCategoryTests.h"
#import "ASINSStringRFC1123DateCategory.h"

@implementation ASINSStringRFC1123DataCategoryTests

- (void)testRFC1123DateParsing
{
	unsigned dateUnits = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSWeekdayCalendarUnit;
	NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	NSString *dateString = @"Thu, 19 Nov 1981 08:52:01 GMT";
	NSDate *date = [dateString dateFromRFC1123];
	NSDateComponents *components = [calendar components:dateUnits fromDate:date];
	BOOL success = ([components year] == 1981 && [components month] == 11 && [components day] == 19 && [components weekday] == 5 && [components hour] == 8 && [components minute] == 52 && [components second] == 1);
	GHAssertTrue(success,@"Failed to parse an RFC1123 date correctly");
	
	dateString = @"4 May 2010 00:59 CET";
	date = [dateString dateFromRFC1123];
	components = [calendar components:dateUnits fromDate:date];
	success = ([components year] == 2010 && [components month] == 5 && [components day] == 3 && [components hour] == 23 && [components minute] == 59);
	GHAssertTrue(success,@"Failed to parse an RFC1123 date correctly");
	
}

@end
