//
//  ASIDownloadCacheTests.m
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 03/05/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//

#import "ASIDownloadCacheTests.h"
#import "ASIDownloadCache.h"
#import "ASIHTTPRequest.h"

@implementation ASIDownloadCacheTests

- (void) cacheInitialisation 
{
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
	[[ASIDownloadCache sharedCache] setDefaultCachePolicy:ASIUseDefaultCachePolicy];
	[ASIHTTPRequest setDefaultCache:[ASIDownloadCache sharedCache]];
}

- (void) testReadingFromCache 
{
	[self cacheInitialisation];
	
	// Test read from the cache
	//Pre Read
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/cache-away"]];
	[request startSynchronous];
	
	//Post Read
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/cache-away"]];
	[request startSynchronous];
	BOOL success = [request didUseCachedResponse];
	GHAssertTrue(success,@"Failed to use cached response");	
}


- (void) testRequestCachePolicyStopsCaching
{
	[self cacheInitialisation];
	
	// Test read from the cache
	//Pre Read
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/cache-away"]];
	[request startSynchronous];
	
	//Post Read
	// Test preventing reads from the cache
	[[ASIDownloadCache sharedCache] setShouldRespectCacheControlHeaders:YES];
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/cache-away"]];
	[request setCachePolicy:ASIAskServerIfModifiedWhenStaleCachePolicy|ASIDoNotReadFromCacheCachePolicy];
	[request startSynchronous];
	BOOL success = ![request didUseCachedResponse];
	GHAssertTrue(success,@"Used the cache when reads were not enabled");
}

- (void) testCachePolicyPreventsWritesToCache
{
	[self cacheInitialisation];

	// Test preventing reads from the cache
	// Test preventing writes to the cache
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/cache-away"]];
	[request setCachePolicy:ASIAskServerIfModifiedWhenStaleCachePolicy|ASIDoNotWriteToCacheCachePolicy];
	[request startSynchronous];
	
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/cache-away"]];
	[request setCachePolicy:ASIAskServerIfModifiedWhenStaleCachePolicy];
	[request startSynchronous];
	BOOL success = ![request didUseCachedResponse];
	GHAssertTrue(success,@"Used cached response when the cache should have been empty");
}

- (void)testRespectingETag 
{
	[self cacheInitialisation];
	
	// Test respecting etag
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/content-always-new"]];
	[request startSynchronous];
	BOOL success = ![request didUseCachedResponse];
	GHAssertTrue(success,@"Used cached response when we shouldn't have");
	
	// Etag will be different on the second request
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/content-always-new"]];
	
	// Note: we are forcing it to perform a conditional GET
	[request setCachePolicy:ASIDoNotReadFromCacheCachePolicy|ASIAskServerIfModifiedCachePolicy];
	[request startSynchronous];
	success = ![request didUseCachedResponse];
	GHAssertTrue(success,@"Used cached response when we shouldn't have");	
}

- (void) testIgnoresServerHeaders 
{
	[self cacheInitialisation];
	
	// Test ignoring server headers
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/no-cache"]];
	[[ASIDownloadCache sharedCache] setShouldRespectCacheControlHeaders:NO];
	[request startSynchronous];
	
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/no-cache"]];
	[[ASIDownloadCache sharedCache] setShouldRespectCacheControlHeaders:NO];
	[request startSynchronous];
	
	BOOL success = [request didUseCachedResponse];
	GHAssertTrue(success,@"Failed to use cached response");
}

- (void) testOnlyLoadIfNotCachedCachePolicy 
{
	[self cacheInitialisation];
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/content-always-new"]];
	[request startSynchronous];
	
	// Test ASIOnlyLoadIfNotCachedCachePolicy
	[[ASIDownloadCache sharedCache] setShouldRespectCacheControlHeaders:YES];
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/content-always-new"]];
	[[ASIDownloadCache sharedCache] setDefaultCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
	[request startSynchronous];
	BOOL success = [request didUseCachedResponse];
	GHAssertTrue(success,@"Failed to use cached response");	
}

- (void) testAskServerIfModifiedWhenStaleCachePolicy 
{
	[self cacheInitialisation];
	
	// Test ASIAskServerIfModifiedWhenStaleCachePolicy
	[[ASIDownloadCache sharedCache] setDefaultCachePolicy:ASIUseDefaultCachePolicy];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/content-always-new"]];
	[request setSecondsToCache:2];
	[request startSynchronous];
	
	// This request should not go to the network
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/content-always-new"]];
	[request startSynchronous];
	BOOL success = [request didUseCachedResponse];
	GHAssertTrue(success,@"Failed to use cached response");
	
	[NSThread sleepForTimeInterval:2];
	
	// This request will perform a conditional GET
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/content-always-new"]];
	[request setSecondsToCache:2];
	[request startSynchronous];
	success = ![request didUseCachedResponse];
	GHAssertTrue(success,@"Failed to use cached response");	
}

- (void) testCacheClearedExpiredContent 
{
	[self cacheInitialisation];
	
	// Test ASIAskServerIfModifiedWhenStaleCachePolicy
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/no-cache"]];
	[[ASIDownloadCache sharedCache] setShouldRespectCacheControlHeaders:NO];
	[request startSynchronous];
	
	// This request should not go to the network
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/no-cache"]];
	[[ASIDownloadCache sharedCache] setShouldRespectCacheControlHeaders:NO];
	[request setCachePolicy:ASIDontLoadCachePolicy];
	[request startSynchronous];
	GHAssertTrue([request didUseCachedResponse], @"Should have read cached response");
		
	//Conditionally clear cache. 
	[[ASIDownloadCache sharedCache] clearExpiredContentForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	
	// This request will perform a conditional GET
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/no-cache"]];
	[[ASIDownloadCache sharedCache] setShouldRespectCacheControlHeaders:NO];
	[request setCachePolicy:ASIDontLoadCachePolicy];
	[request startSynchronous];
	GHAssertFalse([request didUseCachedResponse], @"The file should not have been in the cache");	
}

- (void) testCacheClearedExpiredContentLeavesValidContent 
{
	[self cacheInitialisation];
	
	// Test ASIAskServerIfModifiedWhenStaleCachePolicy
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/cache-away"]];
	[[ASIDownloadCache sharedCache] setShouldRespectCacheControlHeaders:NO];
	[request startSynchronous];
	
	// This request should not go to the network
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/cache-away"]];
	[[ASIDownloadCache sharedCache] setShouldRespectCacheControlHeaders:NO];
	[request setCachePolicy:ASIDontLoadCachePolicy];
	[request startSynchronous];
	GHAssertTrue([request didUseCachedResponse], @"Should have read cached response");
	
	//Conditionally clear cache. 
	[[ASIDownloadCache sharedCache] clearExpiredContentForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	
	// This request will perform a conditional GET
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/cache-away"]];
	[[ASIDownloadCache sharedCache] setShouldRespectCacheControlHeaders:NO];
	[request setCachePolicy:ASIDontLoadCachePolicy];
	[request startSynchronous];
	GHAssertTrue([request didUseCachedResponse], @"The file should have been left in the cache");	
}


- (void) testFallbackToCacheIfLoadFailsCachePolicy
{
	[self cacheInitialisation];
	
	// Test ASIFallbackToCacheIfLoadFailsCachePolicy
	// Store something in the cache
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/content-always-new"]];
	[request startSynchronous];
	
	//Fake an entry in the cache. 
	[request setURL:[NSURL URLWithString:@"http://192.168.122.222"]];
	[request setResponseHeaders:[NSDictionary dictionaryWithObject:@"test" forKey:@"test"]];
	[request setRawResponseData:(NSMutableData *)[@"test" dataUsingEncoding:NSUTF8StringEncoding]];
	[[ASIDownloadCache sharedCache] storeResponseForRequest:request maxAge:0];
	
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://192.168.122.222"]];
	[request retain]; //Stops request being dealloced in run loop!
	[request setCachePolicy:ASIFallbackToCacheIfLoadFailsCachePolicy];
	[request startSynchronous];
	
	//Not 100% sure if this run
	GHAssertTrue([request didUseCachedResponse], @"Failed to set didUseCachedResponse flag");
	
	BOOL success = [[[request responseHeaders] valueForKey:@"test"] isEqualToString:@"test"];
	GHAssertTrue(success, @"Failed to read cached response headers");
	
	success = [[request responseString] isEqualToString:@"test"];
	GHAssertTrue(success, @"Response wasn't to original string");
	[request release];
}



- (void) testDontLoadCachePolicy 
{
	// Test ASIDontLoadCachePolicy
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/content-always-new"]];
	[request setCachePolicy:ASIDontLoadCachePolicy];
	[request startSynchronous];
	BOOL success = ![request error];
	GHAssertTrue(success,@"Request had an error");
	success = ![request contentLength];
	GHAssertTrue(success,@"Request had a response");	
}

- (void)testDontDownloadFromCache
{
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
	[[ASIDownloadCache sharedCache] setDefaultCachePolicy:ASIUseDefaultCachePolicy];
	[ASIHTTPRequest setDefaultCache:nil];

	ASIHTTPRequest *request;
	BOOL success;
	
	// Ensure a request without a download cache does not pull from the cache
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/cache-away"]];
	[request startSynchronous];
	success = ![request didUseCachedResponse];
	GHAssertTrue(success,@"Used cached response when we shouldn't have");
}

- (void) testDontDownloadFromCacheWhenCleared 
{	
	// Make all requests use the cache
	[ASIHTTPRequest setDefaultCache:[ASIDownloadCache sharedCache]];
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
	
	// Check a request isn't setting didUseCachedResponse when the data is not in the cache
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/cache-away"]];
	[request startSynchronous];
	BOOL success = ![request didUseCachedResponse];
	GHAssertTrue(success,@"Cached response should not have been available");	
}

- (void)testClearingTheCache 
{
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
	[[ASIDownloadCache sharedCache] setDefaultCachePolicy:ASIUseDefaultCachePolicy];
	[ASIHTTPRequest setDefaultCache:[ASIDownloadCache sharedCache]];
	
	ASIHTTPRequest *request;
	
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/cache-away"]];
	[request startSynchronous];
	
	// Test clearing the cache
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
	
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/cache-away"]];
	[request startSynchronous];
	GHAssertFalse([request didUseCachedResponse] ,@"Clearing cache should have results in not using cache");	
}

- (void)testDefaultPolicy
{
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/the_great_american_novel_(abridged).txt"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request startSynchronous];
	BOOL success = ([request cachePolicy] == [[ASIDownloadCache sharedCache] defaultCachePolicy]);
	GHAssertTrue(success,@"Failed to use the cache policy from the cache");
	
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/the_great_american_novel_(abridged).txt"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
	[request startSynchronous];
	success = ([request cachePolicy] == ASIOnlyLoadIfNotCachedCachePolicy);
	GHAssertTrue(success,@"Failed to use the cache policy from the cache");
}

- (void)testNoCache
{

	// Test server no-cache headers
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	NSArray *cacheHeaders = [NSArray arrayWithObjects:@"cache-control/no-cache",@"cache-control/no-store",@"pragma/no-cache",nil];
	for (NSString *cacheType in cacheHeaders) {
		NSString *url = [NSString stringWithFormat:@"http://allseeing-i.com/ASIHTTPRequest/tests/%@",cacheType];
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
		[request setDownloadCache:[ASIDownloadCache sharedCache]];
		[request startSynchronous];
		
		request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
		[request setDownloadCache:[ASIDownloadCache sharedCache]];
		[request startSynchronous];
		BOOL success = ![request didUseCachedResponse];
		GHAssertTrue(success,@"Data should not have been stored in the cache");
	}
}

- (void)testSharedCache
{
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];

	// Make using the cache automatic
	[ASIHTTPRequest setDefaultCache:[ASIDownloadCache sharedCache]];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/the_great_american_novel_(abridged).txt"]];
	[request startSynchronous];
	
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/the_great_american_novel_(abridged).txt"]];
	[request startSynchronous];
	BOOL success = [request didUseCachedResponse];
	GHAssertTrue(success,@"Failed to use data cached in default cache");
	
	[ASIHTTPRequest setDefaultCache:nil];
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/the_great_american_novel_(abridged).txt"]];
	[request startSynchronous];
	success = ![request didUseCachedResponse];
	GHAssertTrue(success,@"Should not have used data cached in default cache");
}

- (void)testExpiry
{
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	[[ASIDownloadCache sharedCache] setDefaultCachePolicy:ASIAskServerIfModifiedCachePolicy];

	NSArray *headers = [NSArray arrayWithObjects:@"last-modified",@"etag",@"expires",@"max-age",nil];
	for (NSString *header in headers) {
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://allseeing-i.com/ASIHTTPRequest/tests/content-always-new/%@",header]]];
		[request setDownloadCache:[ASIDownloadCache sharedCache]];
		[request startSynchronous];

		if ([header isEqualToString:@"last-modified"]) {
			[NSThread sleepForTimeInterval:2];
		}

		request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://allseeing-i.com/ASIHTTPRequest/tests/content-always-new/%@",header]]];
		[request setDownloadCache:[ASIDownloadCache sharedCache]];
		[request startSynchronous];
		BOOL success = ![request didUseCachedResponse];
		GHAssertTrue(success,@"Cached data should have expired");
	}
}

- (void)testCustomExpiry
{
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	[[ASIDownloadCache sharedCache] setDefaultCachePolicy:ASIUseDefaultCachePolicy];
	[[ASIDownloadCache sharedCache] setShouldRespectCacheControlHeaders:YES];

	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/cache-away"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request setSecondsToCache:-2];
	[request startSynchronous];

	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/cache-away"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request startSynchronous];

	BOOL success = ![request didUseCachedResponse];
	GHAssertTrue(success,@"Cached data should have expired");

	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/cache-away"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request setSecondsToCache:20];
	[request startSynchronous];

	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/cache-away"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request startSynchronous];

	success = [request didUseCachedResponse];
	GHAssertTrue(success,@"Cached data should have been used");
}

- (void)test304
{
	// Test default cache policy
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	[[ASIDownloadCache sharedCache] setDefaultCachePolicy:ASIUseDefaultCachePolicy];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/the_great_american_novel_(abridged).txt"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request startSynchronous];

	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/the_great_american_novel_(abridged).txt"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request startSynchronous];
	BOOL success = ([request responseStatusCode] == 200);
	GHAssertTrue(success,@"Failed to perform a conditional get");

	success = [request didUseCachedResponse];
	GHAssertTrue(success,@"Cached data should have been used");

	success = ([[request responseData] length]);
	GHAssertTrue(success,@"Response was empty");
}

- (void)testStringEncoding
{
	[ASIHTTPRequest setDefaultCache:[ASIDownloadCache sharedCache]];
	[[ASIDownloadCache sharedCache] setShouldRespectCacheControlHeaders:NO];
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	[[ASIDownloadCache sharedCache] setDefaultCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];

	NSURL *url = [NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/Character-Encoding/UTF-16"];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request startSynchronous];
	BOOL success = ([request responseEncoding] == NSUnicodeStringEncoding);
	GHAssertTrue(success,@"Got the wrong encoding back, cannot proceed with test");

	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request startSynchronous];
	success = [request responseEncoding] == NSUnicodeStringEncoding;
	GHAssertTrue(success,@"Failed to set the correct encoding on the cached response");

	[ASIHTTPRequest setDefaultCache:nil];
}

- (void)testCookies
{
	[ASIHTTPRequest setDefaultCache:[ASIDownloadCache sharedCache]];
	[[ASIDownloadCache sharedCache] setShouldRespectCacheControlHeaders:NO];
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	[[ASIDownloadCache sharedCache] setDefaultCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];

	NSURL *url = [NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/set_cookie"];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request startSynchronous];
	NSArray *cookies = [request responseCookies];

	BOOL success = ([cookies count]);
	GHAssertTrue(success,@"Got no cookies back, cannot proceed with test");

	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request startSynchronous];

	NSUInteger i;
	for (i=0; i<[cookies count]; i++) {
		if (![[[cookies objectAtIndex:i] name] isEqualToString:[[[request responseCookies] objectAtIndex:i] name]]) {
			GHAssertTrue(success,@"Failed to set response cookies correctly");
			return;
		}
	}

	[ASIHTTPRequest setDefaultCache:nil];
}

// Text fix for a bug where the didFinishSelector would be called twice for a cached response using ASIReloadIfDifferentCachePolicy
- (void)testCacheOnlyCallsRequestFinishedOnce
{
	// Run this request on the main thread to force delegate calls to happen synchronously
	[self performSelectorOnMainThread:@selector(runCacheOnlyCallsRequestFinishedOnceTest) withObject:nil waitUntilDone:YES];
}

- (void)runCacheOnlyCallsRequestFinishedOnceTest
{
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/i/logo.png"]];
	[request setCachePolicy:ASIUseDefaultCachePolicy];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request setDelegate:self];
	[request startSynchronous];

	requestsFinishedCount = 0;
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/i/logo.png"]];
	[request setCachePolicy:ASIUseDefaultCachePolicy];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request setDidFinishSelector:@selector(finishCached:)];
	[request setDelegate:self];
	[request startSynchronous];

	BOOL success = (requestsFinishedCount == 1);
	GHAssertTrue(success,@"didFinishSelector called more than once");
}

- (void)finishCached:(ASIHTTPRequest *)request
{
	requestsFinishedCount++;
}

@end
