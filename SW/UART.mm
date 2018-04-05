#include <termios.h>
#include <sys/ioctl.h>
//#import "fileNameUtils.h"
#import "UART.h"

@implementation UART

@synthesize uart_handle;
@synthesize uart_path;
@synthesize uart_nl;
@synthesize uart_logger;
@synthesize uart_filePath;


-(int)handleNumber{
    return self->uart_handle;
}

-(id) initWithPath:(NSString *)path andBaudRate:(unsigned)baud_rate logPath:(NSString *) inLogPath DebugMsg:(BOOL)debugMsg;
{//path是線編所在的路徑，dev／。。。FIXTURE2
    //25100...
    //@"/tmp/"
	self = [super init];
    
	int handle = 0;
	struct termios  options;
    
	if (self) {
        handle = open([path UTF8String], O_RDWR | O_NONBLOCK| O_NOCTTY | O_NDELAY );        
		if (handle < 0) {
			NSLog(@"Error opening serial port %@ - %s(%d) at thread %@.", path, strerror(errno), errno,[NSThread currentThread]);
			goto error;
		}
	}
	
	if (self) {
		if (ioctl(handle, TIOCEXCL) == -1) {
			NSLog(@"Error setting TIOCEXCL on %@ - %s(%d).\n", path, strerror(errno), errno);
			goto error;
		}
		
		
		if (fcntl(handle, F_SETFL, FNDELAY) == -1) {        
			NSLog(@"Error clearing O_NONBLOCK %@ - %s(%d).\n", path, strerror(errno), errno);
			goto error;
		}
		
		
		if (tcgetattr(handle, &options) == -1) {
			NSLog(@"Error getting tty attributes %@ - %s(%d).\n", path, strerror(errno), errno);
			goto error;
		}
		
		
		cfsetspeed(&options, baud_rate);
		options.c_cflag |=  (CLOCAL  |  CREAD);        
		options.c_cflag &= ~(PARENB);
		options.c_cflag &= ~(CSTOPB);
		//		options.c_cflag &= ~(CSIZE);
		options.c_lflag &= ~(ICANON  |   ECHO   |   ECHOE   |   ISIG);
		options.c_oflag &= ~(OPOST);
		
        options.c_iflag &= ~ICRNL;              //from nanokdp
        options.c_oflag &= ~ONLCR;              //from nanokdp
        // Set flow control.
        
        options.c_cflag &= ~CRTSCTS;            //from nanokdp
        options.c_iflag &= ~( IXON | IXOFF | IXANY );   //from nanokdp
        
        if (debugMsg==YES) {
            NSLog(@"UART(%@) Output baud rate changed to %d\n", path, (int) cfgetospeed(&options));
        }
		
		
		if (tcsetattr(handle, TCSANOW, &options) == -1) {
			NSLog(@"Error setting tty attributes %@ - %s(%d).\n", path, strerror(errno), errno);
			goto error;
		}
		
		self->uart_handle = handle;
		self->uart_path   = [[NSString alloc] initWithString:path];
//      self->uart_nl     = @"\r\n";
//		self->uart_nl     = @"\r";
        self->uart_nl     = @"\r\n";
		
		NSString *log_path = [NSString stringWithFormat:@"%@/UART_%@.log", inLogPath, [self->uart_path lastPathComponent] ];
		self->uart_filePath = log_path;
		
		[[NSFileManager defaultManager] createFileAtPath:log_path contents:nil attributes:nil];
		self->uart_log    = [NSFileHandle fileHandleForWritingAtPath:log_path];
	}
    
	return self;
    
error:
	if (handle >= 0) {
		close(handle);
	}
    
	self = nil;
    
	return self;
}

- (void) closePort
{
	close(uart_handle);
	
}

-(void) dealloc
{
	close(uart_handle);
    
    
}


- (void) appendToFilePure: (NSString*) inFile withString:(NSString *)inString
{
	@autoreleasepool {
	
		NSString *theAppendString = inString;
		
		FILE*   outFile = (FILE*)NULL;
		int		theStat = 0;
		
		if ((outFile = fopen ([inFile UTF8String], "a")))
		{
			theStat = (int)fwrite([theAppendString UTF8String] , [theAppendString length], 1, outFile);
			fflush(outFile);
			fclose(outFile);
		}
		else
		{
			NSLog(@"Error performing fopen on [%s]\n",[inFile UTF8String]);
		}
	}	
	
}

- (void) appendToFilePure: (NSString*) inFile withData:(NSData *)inData {
	
	char * theBytes = (char*)malloc([inData length]);
	memset(theBytes, 0x00, [inData length]);
	[inData getBytes:theBytes length:[inData length]];
    //	[self appendToFilePure: inFile withString:[NSString stringWithUTF8String:(const char*)theBytes ] ];
	FILE*   outFile = (FILE*)NULL;
	int		theStat = 0;
	
	if ((outFile = fopen ([inFile UTF8String], "a")))
	{
		theStat = (int)fwrite(theBytes , [inData length], 1, outFile);
		fflush(outFile);
		fclose(outFile);
	}
	else
	{
		NSLog(@"Error performing fopen on [%s]\n",[inFile UTF8String]);
	}
	
	
}


- (void) logData:(NSData *)data
{
	[uart_logger logData:data withContext:self];
	//NSLog(@"%@", data);
    //	[uart_log writeData:data];
	[self appendToFilePure:self->uart_filePath withData:data];
}

- (int) writeBuffer:(unsigned char*)buffer length:(unsigned)len
{
	int count=0;
	NSLog(@"String length:%d",len);
	
	char const *buf = (const char *)buffer;
	
	for (unsigned i = 0; i < len; i++) {
		
		
		int success=(int)write(self->uart_handle, buf+i, 1);
		[NSThread sleepForTimeInterval:0.001];	
		
		//NSLog(@"Success:%d",success);
		if(success==1)
		{
			//NSLog(@"Buffer:[%02X]",buf[i]);
			count++;
		} else {
			NSLog(@"Failed to write character no %d",i);
			break;
		}
	}
	return count;
}

- (int) write:(NSString *)str
{
	char const *buf = [str UTF8String];
	unsigned    len = (int)[str length];
	//NSLog(@"Writing something:[%@]",str);
	for (unsigned i= 0; i< len; i++) {
		/*
		 * pace ourselves, dock uarts do not have flow control
		 */
		//NSLog(@"Original buf:[%02X]",buf[i]);
		
		write(self->uart_handle, buf+i, 1);
		[NSThread sleepForTimeInterval:0.001];
	}
    
	return len;
}



-(int)  writeLineData:(NSData *)str;
{
	char buffer[4096];
	int count=0;
	int count_nl=0;
	/* flush input */
	//NSString *convertData = [[NSString alloc] initWithBytes:str length:20 encoding:NSASCIIStringEncoding];
	//NSLog(@"Check last time:[%@]",str);
	
	while (read(self->uart_handle, buffer, sizeof(buffer)) > 0) {
	}
	count=[self writeBuffer:(unsigned char*)[str bytes] length:(int)[str length]];
	
	count_nl=[self write:self.uart_nl];
	if (count_nl>0) {
		count=count+count_nl;
	}
    
	return count;
}
-(int) writeLine:(NSString *)str
{
	char buffer[4096];
	
	/* flush input */
	while (read(self->uart_handle, buffer, sizeof(buffer)) > 0) {
	}
	
	return [self write:[str stringByAppendingString:self.uart_nl]];
}

-(NSData *)read
{
	char      buffer[8192];
	ssize_t   numBytes;
	//NSLog(@"Trying to read");
	numBytes = read(self->uart_handle, buffer, sizeof(buffer) - 1);
	
	if (numBytes > 0) {
		int valid;
		
		[self logData:[NSData dataWithBytes:buffer length:numBytes]];
		
		/*
		 * XXX : mpetit : iBoot produces \0 after its line endings
		 */
        valid = 0;
        for (unsigned i= 0; i< numBytes; i++) {
            if (buffer[i]) {
                buffer[valid] = buffer[i];
                valid += 1;
                //printf("0x%02X\n",buffer[i]);
            }
        }
		buffer[valid] = '\0';
        
        //return [NSString stringWithCString:buffer];
        //NSLog(@"theBuffer=[%@]",buffer);
        return [NSData  dataWithBytes:buffer length: numBytes];
    }
	
	NSString *myString = @"";
	const char *utfString = [myString UTF8String];
	NSData	  *returnData = [NSData dataWithBytes:utfString length:strlen(utfString)];
	return returnData;
	
}

@end
