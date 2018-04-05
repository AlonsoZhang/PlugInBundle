/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 */

#import "SWFIXTURE.h"

@implementation SWFIXTURE

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        // enter initialization code here
    }

    return self;
}

- (CTVersion *)version
{
    // Plugin version is first parameter (specified by plugin owner)
    // project build version is the version given by the build system (use compiler variable here)
    // short description is a string describing what your plugin does.
    CTVersion *version = [[CTVersion alloc] initWithVersion:@"1"
                                        projectBuildVersion:@"1"
                                           shortDescription:@"My short description"];

    return version;
}

- (BOOL)setupWithContext:(CTContext *)context error:(NSError *__autoreleasing *)error
{
    // Do plugin setup work here
    // This context is safe to store a reference of

    // Can also register for event at any time. Requires a selector that takes in one argument of CTEvent type.
    // [context registerForEvent:CTEventTypeUnitAppeared selector:@selector(handleUnitAppeared:)];
    // [context registerForEvent:@"Random event" selector:@selector(handleSomeEvent:)];
    return YES;
}

- (BOOL)teardownWithContext:(CTContext *)context error:(NSError *__autoreleasing *)error
{
    return YES;
}

- (CTCommandCollection *)commmandDescriptors
{
    // Collection contains descriptions of all the commands exposed by a plugin
    CTCommandCollection *collection = [CTCommandCollection new];
    // A command exposes its name, the selector to call, and a short description
    // Selector should take in one object of CTTestContext type
    CTCommandDescriptor *openPortcommand = [[CTCommandDescriptor alloc] initWithName:@"openPort" selector:@selector(openPort:) description:@"openPort"];
    // Commands can define the parameters they need
    [openPortcommand addParameter:@"port" type:CTParameterDescriptorTypeString defaultValue:nil allowedValues:nil required:YES description:@"UART Port"];
    CTCommandDescriptor *sendcommand = [[CTCommandDescriptor alloc] initWithName:@"send" selector:@selector(send:) description:@"send"];
    CTCommandDescriptor *receivecommand = [[CTCommandDescriptor alloc] initWithName:@"receive" selector:@selector(receive:) description:@"receive"];
    [collection addCommand:openPortcommand];
    [collection addCommand:sendcommand];
    [collection addCommand:receivecommand];
    return collection;
}

- (void)openPort:(CTTestContext *)context
{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        self.uart = [[UART alloc]initWithPath:[NSString stringWithFormat:@"%@",[context.parameters objectForKey:@"port"]] andBaudRate:115200 logPath:@"/tmp" DebugMsg:NO];
       /* NSError *err = nil;
        CTRecord *record = [[CTRecord alloc]initMeasurementRecordWithNames:@[@"openPort"]
                                                                     limit:nil
                                                               measurement:[CTMeasurement measurementWithValue:@(222) units:@"mmm"]
                                                               failureInfo:nil priority:CTRecordPriorityRequired
                                                                 startTime:[NSDate date]
                                                                   endTime:[NSDate date]
                                                                     error:&err];
        [context.records addRecord:record error:&err];*/
        return CTRecordStatusPass;
    }];
}

- (void)send:(CTTestContext *)context
{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        [self.uart writeLine:@"Hello SW"];
        return CTRecordStatusPass;
    }];
}

- (void)receive:(CTTestContext *)context
{
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        NSDate *StartTime = [NSDate date];
        NSData *receivedData  = [[NSData alloc] init];
        NSString *response = @"";
        do
        {
            [NSThread sleepForTimeInterval:0.02];
            receivedData = [[NSData alloc] initWithData:[self.uart read]];
            if ([receivedData length] > 0)
            {
                response = [NSString stringWithFormat:@"%@%@",response,[[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding]];
                response = [response stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                break;
            }
            if ([[NSDate date] timeIntervalSinceDate:StartTime] > 20)
            {
                response = @"Timeout" ;
                break;
            }
        }while(![[response stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]  hasSuffix:@"@"]);
        NSError *err = nil;
        CTRecord *record = [[CTRecord alloc]initMeasurementRecordWithNames:@[@"openPort"]
                                                                     limit:nil
                                                               measurement:[CTMeasurement measurementWithValue:@(1) units:response]
                                                               failureInfo:nil priority:CTRecordPriorityRequired
                                                                 startTime:[NSDate date]
                                                                   endTime:[NSDate date]
                                                                     error:&err];
        [context.records addRecord:record error:&err];
        return CTRecordStatusPass;
    }];
}

@end
