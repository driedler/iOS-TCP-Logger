//
//  TCPLogger.h
//  JukeboxTest2
//
//  Created by Lion User on 07/02/2013.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//
//
//   Add the following lines to the apps .pch file
//   (uncommented of course!)
//
//   #define NSLog(...) tcpLogg_log(__VA_ARGS__);
//   void tcpLogg_log(NSString* fmt, ...);
//




#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

#define NETWORK_LOGGING_TCP_PORT 666


@interface TCPLogger : NSObject <GCDAsyncSocketDelegate>



void tcpLogg_log(NSString* fmt, ...);




@property (strong, atomic, readonly) GCDAsyncSocket *clientTcpSocket; 
@property (strong, atomic, readonly) NSDateFormatter *dateFormat; 


- (id)init;

- (void)deinit;

+ (void)tcpLog:(NSString*)fmt :(va_list)args;



@end
