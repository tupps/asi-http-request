//
//  ASINSStringRFC1123DateCategory.h
//  Mac
//
//  Created by Luke Tupper on 18/11/10.
//  Copyright 2010 Black Bilby Ltd Pty. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (ASINSStringRFC1123DateCategory)

// Returns a date from a string in RFC1123 format
- (NSDate *)dateFromRFC1123;

@end
