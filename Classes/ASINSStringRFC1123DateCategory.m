//
//  ASINSStringRFC1123DateCategory.m
//  Mac
//
//  Created by Luke Tupper on 18/11/10.
//  Copyright 2010 Black Bilby Ltd Pty. All rights reserved.
//

#import "ASINSStringRFC1123DateCategory.h"


@implementation NSString (ASINSStringRFC1123DateCategory)

// Based on hints from http://stackoverflow.com/questions/1850824/parsing-a-rfc-822-date-with-nsdateformatter
- (NSDate *)dateFromRFC1123
{
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease]];
	// Does the string include a week day?
	NSString *day = @"";
	if ([self rangeOfString:@","].location != NSNotFound) {
		day = @"EEE, ";
	}
	// Does the string include seconds?
	NSString *seconds = @"";
	if ([[self componentsSeparatedByString:@":"] count] == 3) {
		seconds = @":ss";
	}
	[formatter setDateFormat:[NSString stringWithFormat:@"%@dd MMM yyyy HH:mm%@ z",day,seconds]];
	return [formatter dateFromString:self];
}

@end
