//
//  Log2ServerWorker.m
//  Log2Server
//
//  Created by 倪 李俊 on 15/6/14.
//  Copyright (c) 2015年 com.sinri. All rights reserved.
//

#import "Log2ServerWorker.h"

Log2ServerWorker * sharedServer=nil;

NSString * logDirName=@"Log2Server";

BOOL debugMode=NO;

BOOL useDocumentStorage=NO;

@implementation Log2ServerWorker

+(void)setDebugMode:(BOOL)isDebug{
    debugMode=isDebug;
}

+(void)setUseDocumentStorage:(BOOL)useDoc{
    useDocumentStorage=useDoc;
}

+(void)registerServiceWithDeviceSignature:(NSString*)deviceSignature andServerApi:(NSString*)serverApi{
    sharedServer=[[Log2ServerWorker alloc]initWithDeviceSignature:deviceSignature andServerApi:serverApi];
    // Timer Fire Ready
    [sharedServer prepareTimer];
}

+(Log2ServerWorker*)sharedInstance{
    //    if(!sharedServer){
    //        sharedServer=[[Log2Server alloc]init];
    //    }
    return sharedServer;
}

#pragma mark - Logger Initialization

-(instancetype)initWithDeviceSignature:(NSString*)deviceSignature andServerApi:(NSString*)serverApi{
    self=[super init];
    if(self){
        _deviceSignature=deviceSignature;
        _serverApi=serverApi;
#ifdef DEBUG
        _logSyncInterval=60;
#else
        _logSyncInterval=60*33;
#endif
    }
    return self;
}

#pragma mark - Timer

-(void)prepareTimer{
    if(_theTimer){
        [_theTimer invalidate];
        _theTimer=nil;
    }
    _theTimer = [NSTimer scheduledTimerWithTimeInterval:_logSyncInterval target:self selector:@selector(onRegularLogSend) userInfo:nil repeats:NO];
}

-(void)onRegularLogSend{
    //send
    NSArray * logList=[[NSFileManager defaultManager]subpathsAtPath:(useDocumentStorage?[Log2ServerWorker DocumentPath:logDirName]:[Log2ServerWorker CachePath:logDirName])];
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
    if(debugMode)NSLog(@"%@",str);
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
    return [Log2ServerWorker UserDirectoryPath:(NSDocumentDirectory)];
}

//
+(NSString *)DocumentPath:(NSString *)file
{
    return [[Log2ServerWorker DocumentPath] stringByAppendingPathComponent:file];
}


+(NSString *)CachePath
{
    return [[Log2ServerWorker UserDirectoryPath:(NSCachesDirectory) ] stringByAppendingPathComponent:@"Cache"];
}


//
+(void) ClearCache
{
    [[NSFileManager defaultManager] removeItemAtPath:[Log2ServerWorker CachePath] error:nil];
}

//
+(NSString *)CachePath:(NSString *)file
{
    NSString *dir = [Log2ServerWorker CachePath];
    if(![[NSFileManager defaultManager] fileExistsAtPath:dir])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [dir stringByAppendingPathComponent:file];
}

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
    if(useDocumentStorage){
        return [Log2ServerWorker DocumentPath:currentFile];
    }else{
        return [Log2ServerWorker CachePath:currentFile];
    }
}

-(void)writeLogToCache:(NSString*)logText{
    NSError * error = nil;
    
    NSString * dirPath=(useDocumentStorage?[Log2ServerWorker DocumentPath:logDirName]:[Log2ServerWorker CachePath:logDirName]);
    if(![[NSFileManager defaultManager]fileExistsAtPath:dirPath]){
        [[NSFileManager defaultManager]createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
        if(debugMode)NSLog(@"prepare log dir %@ with error %@",dirPath,error);
    }
    
    NSString * path=[self currentCacheFilePath];
    
    
    BOOL file_prepared=YES;
    if(![[NSFileManager defaultManager]fileExistsAtPath:path]){
        NSString * initialStr=[NSString stringWithFormat:@"%@\r\n",path];
        file_prepared=[initialStr writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if(debugMode)NSLog(@"prepare log file %@ with error %@",path,error);
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
    NSString * fullPath=(useDocumentStorage?[Log2ServerWorker DocumentPath:[logDirName stringByAppendingPathComponent:logName]]:[Log2ServerWorker CachePath:[logDirName stringByAppendingPathComponent:logName]]);
    
    NSError * error = nil;
    NSString * content=[NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:&error];
    
    if(content){
        NSString * url=[NSString stringWithFormat:@"%@?device=%@&name=%@",_serverApi,_deviceSignature,logName];
        NSMutableURLRequest * request=[[NSMutableURLRequest alloc]initWithURL:([NSURL URLWithString:url]) cachePolicy:(NSURLRequestReloadIgnoringCacheData) timeoutInterval:120];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[content dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSHTTPURLResponse * response = nil;
        NSData*reply=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if(debugMode)NSLog(@"Log2Server->sendCacheToServer(%@) url=%@ response %@ data %@",logName,url,response,[[NSString alloc]initWithData:reply encoding:NSUTF8StringEncoding]);
        
        if([response statusCode]==200){
            NSDictionary * dict=[NSJSONSerialization JSONObjectWithData:reply options:(NSJSONReadingMutableLeaves) error:&error];
            if(debugMode)NSLog(@"reply: %@ Error: %@",dict,error);
            if([dict[@"result"] isEqualToString:@"ok"]){
                if(![[self currentCacheFilePath] isEqualToString:fullPath]){
                    //kill the file
                    BOOL killed=[[NSFileManager defaultManager]removeItemAtPath:fullPath error:&error];
                    if(debugMode)NSLog(@"killed %@ = %d error:%@",fullPath,killed,error);
                    return YES;
                }
            }
        }
    }
    return NO;
}



@end
