/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 *
 *  SWFIXTURE.h
 *  SW
 *
 */

#import <Foundation/Foundation.h>
#import <CoreTestFoundation/CoreTestFoundation.h>
#import "UART.h"

@interface SWFIXTURE : NSObject<CTPluginProtocol>

- (void)openPort:(CTTestContext *)context;

@property UART *uart;

@end
