/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 *
 *  SW.h
 *  SW
 *
 */

#import "SW.h"
#import "SWFIXTURE.h"

@implementation SW

- (void)registerBundlePlugins
{
	[self registerPluginName:@"SWFIXTURE" withPluginCreator:^id<CTPluginProtocol>(){
		return [[SWFIXTURE alloc] init];
	}];
}

@end
