/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 *
 *  SW.h
 *  SW
 *
 */

 #import <CoreTestFoundation/CoreTestFoundation.h>

@interface SW : CTPluginBaseFactory <CTPluginFactory>

- (void)registerBundlePlugins;

@end