//
//  Log2Server.h
//  Log2Server
//
//  Created by 倪 李俊 on 15/5/28.
//  Copyright (c) 2015年 com.sinri. All rights reserved.
//

#import <Foundation/Foundation.h>

// SLog (or other name you want), a grammar sugar similar to NSLog(fmt,...) for convinence.
#define SLog(fmt, ...) [[Log2Server sharedInstance]logToServer:(@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__]

@interface Log2Server : NSObject

+(Log2Server*)sharedInstance;

/**
 * Register Log2Server Service with Device Information and Service Interface URL.
 * Commonly it would have to be executed in AppDelegate Initialization Codes.
 */
+(void)registerServiceWithDeviceSignature:(NSString*)deviceSignature andServerApi:(NSString*)serverApi;

@property NSString * deviceSignature;
@property NSString * serverApi;

@property NSTimer * theTimer;

-(instancetype)initWithDeviceSignature:(NSString*)deviceSignature andServerApi:(NSString*)serverApi;

-(void)logToServer:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);

-(NSString*)currentCacheFilePath;

-(void)writeLogToCache:(NSString*)logText;

@end
