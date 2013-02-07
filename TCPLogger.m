//
//  TCPLogger.m
//  JukeboxTest2
//
//  Created by Lion User on 07/02/2013.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "TCPLogger.h"



static TCPLogger *sharedSingleton = nil;



void tcpLogg_log(NSString* fmt, ...)
{
    if(sharedSingleton == nil)
    {
        TCPLogger *logger = [[TCPLogger alloc] init]; 
        logger = nil; // just to keep the compiler happy (doesn't matter size sharedSingleton is set in the init function)
    }
    
    va_list args;
    va_start(args, fmt);
    [TCPLogger tcpLog:fmt :args];
    va_end(args);
}


@implementation TCPLogger
{
    dispatch_queue_t loggingQueue;
    GCDAsyncSocket *loggingTcpSocket;
    GCDAsyncSocket *_clientTcpSocket;
    NSDateFormatter *_dateFormat;
}

@synthesize clientTcpSocket = _clientTcpSocket;
@synthesize dateFormat = _dateFormat;


- (id)init
{
    self = [super init];
    
    sharedSingleton = self;
    
    loggingQueue = dispatch_queue_create("logging_queue", NULL);
    _dateFormat = [[NSDateFormatter alloc]init];
    [_dateFormat setDateFormat:@"HH:mm:ss.SSS"];
    
    [self startTCPSever];
    
    return self;
}

- (void)deinit
{
    [self stopTCPSever];
    dispatch_release(loggingQueue);
    loggingQueue = nil;
}


+ (void)tcpLog:(NSString*)fmt :(va_list)args
{
    NSLogv(fmt, args);

    if(sharedSingleton != nil && sharedSingleton.clientTcpSocket != nil)
    {
        NSString *time = [sharedSingleton.dateFormat stringFromDate:[NSDate date]];
        NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
        mach_port_t tid = pthread_mach_thread_np(pthread_self());
        
        NSString *str = [NSString stringWithFormat:@"%@[%X]: %@\r\n", time, tid, msg];
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        dispatch_async([sharedSingleton getLoggingQueue], ^{                     
            @autoreleasepool {                                 
                [sharedSingleton.clientTcpSocket writeData:data withTimeout:NETWORK_CLIENT_TIMEOUT_PERIOD tag:0];                                                
        }});
    }
}

- (dispatch_queue_t)getLoggingQueue
{
    return loggingQueue;
}

- (void)startTCPSever
{
    _clientTcpSocket = nil;
    loggingTcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:loggingQueue];
    [loggingTcpSocket setIPv6Enabled:FALSE];
    
    NSLog(@"Starting Logging TCP server...");
    
    NSError *error = nil;
    if(![loggingTcpSocket acceptOnPort:NETWORK_LOGGING_TCP_PORT error:&error])
    {
        NSLog(@"Error starting logging TCP server: %@", error);
    }
    else 
    {
        NSLog(@"Logging TCP server running.");
    }
}

- (void)stopTCPSever
{
    [_clientTcpSocket disconnect];
    _clientTcpSocket = nil;
    
    [loggingTcpSocket disconnect];
    loggingTcpSocket = nil;
    
    
    NSLog(@"Logging TCP server stopped");
}


- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    if(_clientTcpSocket != nil)
    {
        NSLog(@"Forceful rejecting logging TCP client");
        [sock disconnect];
    }
    else 
    {
        NSLog(@"Logging TCP client connected");
        _clientTcpSocket = newSocket;
    }
}


- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if(loggingTcpSocket != sock)
    {
        NSLog(@"Logging TCP client disconnected");
        [_clientTcpSocket disconnect];
        _clientTcpSocket = nil;
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"Received logging TCP client data...");
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    //NSLog(@"wrote data!");
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock 
shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length
{
    NSLog(@"TCP logging READ timeout");
    
    return -1;
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length
{
    NSLog(@"TCP logging WRITE timeout");
    
    return -1;
}

@end
