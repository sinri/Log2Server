//
//  Log2Server.m
//  Log2Server
//
//  Created by 倪 李俊 on 15/5/28.
//  Copyright (c) 2015年 com.sinri. All rights reserved.
//

#import "Log2Server.h"

Log2Server * sharedServer=nil;

NSString * logDirName=@"Log2Server";

@implementation Log2Server

+(void)registerServiceWithDeviceSignature:(NSString*)deviceSignature andServerApi:(NSString*)serverApi{
    sharedServer=[[Log2Server alloc]initWithDeviceSignature:deviceSignature andServerApi:serverApi];
    // Timer Fire Ready
    [sharedServer prepareTimer];
}

+(Log2Server*)sharedInstance{
//    if(!sharedServer){
//        sharedServer=[[Log2Server alloc]init];
//    }
    return sharedServer;
}

#pragma mark - Logger Initialization

//-(instancetype)init{
//    self = [super init];
//    if(self){
//        _deviceSignature=[[NSUUID UUID]UUIDString];
//        _serverApi=@"http://www.baidu.com/";
//    }
//    return self;
//}

-(instancetype)initWithDeviceSignature:(NSString*)deviceSignature andServerApi:(NSString*)serverApi{
    self=[super init];
    if(self){
        _deviceSignature=deviceSignature;
        _serverApi=serverApi;
    }
    return self;
}

#pragma mark - Timer

-(void)prepareTimer{
#ifdef DEBUG
    NSTimeInterval interval=60;
#else
    NSTimeInterval interval=60*33;
#endif
    _theTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(onRegularLogSend) userInfo:nil repeats:NO];
}

-(void)onRegularLogSend{
    //send
    NSArray * logList=[[NSFileManager defaultManager]subpathsAtPath:[Log2Server DocumentPath:logDirName]];
    NSString * report=[NSString stringWithFormat:@"[%@] %@",[NSDate date],@"Regular Log Sending...\n"];
    for (NSString * filepath in logList) {
        BOOL done=[self sendCacheToServer:filepath];
        report = [report stringByAppendingFormat:@"Send %@: %@!\n",filepath,(done?@"Done":@"Failed")];
    }
    report = [report stringByAppendingString:@"Oshimai.\n"];
    [self prepareTimer];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"Log2ServerRegularLogSendNotification" object:report];
}

/*
 + (va_list)getVAList:(NSObject*)string, ... {// parms must be end with nil
 va_list args;
 va_start(args, string);
 if (string) {
 _Log(@"Do something with First: %@", string);
 NSObject *other;
 while ((other = va_arg(args, NSObject *))) {
 _Log(@"Do something with other: %@", other);
 }
 }
 va_end(args);
 return args;
 }
 */

-(void)logToServer:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2){
    va_list args;
    va_start(args, format);
    NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    //First, log to device console
    NSLog(@"%@",str);
    //Then, log to cache file
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *date = [NSDate date];
    NSString *formattedDateString = [dateFormatter stringFromDate:date];
    
    NSString * logText=[NSString stringWithFormat:@"[%@] %@",formattedDateString,str];
    [self writeLogToCache:logText];
    //...
}

#pragma mark - Cache File Handle

+(NSString *)UserDirectoryPath:(NSSearchPathDirectory) directory
{
    return [NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES) objectAtIndex:0];
}

//
+(NSString *)DocumentPath
{
    return [Log2Server UserDirectoryPath:(NSDocumentDirectory)];
}

//
+(NSString *)DocumentPath:(NSString *)file
{
    return [[Log2Server DocumentPath] stringByAppendingPathComponent:file];
}

/*
+(NSString *)CachePath
{
    //return DocumentPath(@"Cache");
    return [[Log2Server UserDirectoryPath:(NSCachesDirectory) ] stringByAppendingPathComponent:@"Cache"];
}


//
+(void) ClearCache
{
    [[NSFileManager defaultManager] removeItemAtPath:[Log2Server CachePath] error:nil];
}

//
+(NSString *)CachePath:(NSString *)file
{
    NSString *dir = [Log2Server CachePath];
    if(![[NSFileManager defaultManager] fileExistsAtPath:dir])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [dir stringByAppendingPathComponent:file];
}
*/
-(NSString*)currentCacheFilePath{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMddHH";//@"yyyy-MM-dd HH:mm:ss";
    
    NSDate *date = [NSDate date];
    
    NSString *formattedDateString = [dateFormatter stringFromDate:date];
    
    dateFormatter.dateFormat = @"mm";
    NSString *formattedMinuteString = [dateFormatter stringFromDate:date];
    NSNumber * min_num = @([formattedMinuteString intValue] / 20);
    
    NSString * logName = [NSString stringWithFormat:@"%@_%@", formattedDateString,min_num.stringValue];
    
    //NSString * currentFile = [[logDirName stringByAppendingPathComponent:formattedDateString] stringByAppendingPathExtension:@"log"];
    NSString * currentFile = [logDirName stringByAppendingPathComponent:logName];
    return [Log2Server DocumentPath:currentFile];
}

-(void)writeLogToCache:(NSString*)logText{
    NSError * error = nil;
    
    NSString * dirPath=[Log2Server DocumentPath:logDirName];
    if(![[NSFileManager defaultManager]fileExistsAtPath:dirPath]){
        [[NSFileManager defaultManager]createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
        NSLog(@"prepare log dir %@ with error %@",dirPath,error);
    }
    
    NSString * path=[self currentCacheFilePath];
    
    
    BOOL file_prepared=YES;
    if(![[NSFileManager defaultManager]fileExistsAtPath:path]){
        NSString * initialStr=[NSString stringWithFormat:@"%@\r\n",path];
        file_prepared=[initialStr writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
        NSLog(@"prepare log file %@ with error %@",path,error);
    }
    if(file_prepared){
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[[NSString stringWithFormat:@"%@\r\n",logText] dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    }
}

#pragma mark - Send logs to server

-(BOOL)sendCacheToServer:(NSString*)logName{
    NSString * fullPath=[Log2Server DocumentPath:[logDirName stringByAppendingPathComponent:logName]];
    
    NSError * error = nil;
    NSString * content=[NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:&error];
    
    if(content){
        NSString * url=[NSString stringWithFormat:@"%@?device=%@&name=%@",_serverApi,_deviceSignature,logName];
        NSMutableURLRequest * request=[[NSMutableURLRequest alloc]initWithURL:([NSURL URLWithString:url]) cachePolicy:(NSURLRequestReloadIgnoringCacheData) timeoutInterval:120];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[content dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSHTTPURLResponse * response = nil;
        NSData*reply=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        NSLog(@"Log2Server->sendCacheToServer(%@) url=%@ response %@ data %@",logName,url,response,[[NSString alloc]initWithData:reply encoding:NSUTF8StringEncoding]);
        
        if([response statusCode]==200){
            NSDictionary * dict=[NSJSONSerialization JSONObjectWithData:reply options:(NSJSONReadingMutableLeaves) error:&error];
            NSLog(@"reply: %@ Error: %@",dict,error);
            if([dict[@"result"] isEqualToString:@"ok"]){
                if(![[self currentCacheFilePath] isEqualToString:fullPath]){
                    //kill the file
                    BOOL killed=[[NSFileManager defaultManager]removeItemAtPath:fullPath error:&error];
                    NSLog(@"killed %@ = %d error:%@",fullPath,killed,error);
                    return YES;
                }
            }
        }
    }
    return NO;
}


@end
