#import <Cocoa/Cocoa.h>
//#import "DataLogger.h"

@protocol DataLogger

-(void) logData:(NSData *)data withContext:(id)ctx;

@end


@interface UART : NSObject
{
@private
	int       uart_handle;
	NSString *uart_path;
	NSString *uart_nl;
	NSString *uart_filePath;
	
	NSObject<DataLogger> *uart_logger;
	NSFileHandle         *uart_log;
}

@property (readonly) int                    uart_handle;
@property (readonly) NSString              *uart_path;
@property (copy)		NSString              *uart_filePath;
@property (copy)     NSString              *uart_nl;
@property (strong)   NSObject<DataLogger>  *uart_logger;


-(id)        initWithPath:(NSString *)path andBaudRate:(unsigned)baud_rate logPath:(NSString *) inLogPath DebugMsg:(BOOL)debugMsg;
-(int)       write:(NSString *)str;
-(int)       writeLine:(NSString *)str;
-(int)       writeLineData:(NSData *)str;
-(NSData *)read;
-(int) writeBuffer:(unsigned char*)buffer length:(unsigned)len;
- (void) closePort;
-(int)handleNumber;
@end
