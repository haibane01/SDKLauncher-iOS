//
//  PackageResourceServer.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "PackageResourceServer.h"
#import "AQHTTPServer.h"
#import "PackageResourceConnection.h"
#import "RDPackage.h"
#import "RDPackageResource.h"


static dispatch_semaphore_t m_byteStreamResourceLock = NULL;


@implementation PackageResourceServer


+ (dispatch_semaphore_t) byteStreamResourceLock
{
    return m_byteStreamResourceLock;
}


- (void)dealloc {
	if (m_httpServer != nil && m_httpServer.isListening) {
		[m_httpServer stop];
	}

	[PackageResourceConnection setPackage:nil];
}


+ (void)initialize {
	m_byteStreamResourceLock = dispatch_semaphore_create(1);
}


- (id)initWithPackage:(RDPackage *)package {
	if (package == nil) {
		return nil;
	}

	if (self = [super init]) {
		m_package = package;

		m_httpServer = [[AQHTTPServer alloc] initWithAddress:@"localhost"
			root:[NSBundle mainBundle].resourceURL];

		if (m_httpServer == nil) {
			NSLog(@"The HTTP server is nil!");
			return nil;
		}

		[m_httpServer setConnectionClass:[PackageResourceConnection class]];

		NSError *error = nil;
		BOOL success = [m_httpServer start:&error];

		if (!success || error != nil) {
			if (error != nil) {
				NSLog(@"Could not start the HTTP server! %@", error);
			}

			return nil;
		}

		[PackageResourceConnection setPackage:package];
	}

	return self;
}


- (int)port {
	NSString *s = m_httpServer.serverAddress;
	NSRange range = [s rangeOfString:@":"];
	return range.location == NSNotFound ? 0 : [s substringFromIndex:range.location + 1].intValue;
}


@end
