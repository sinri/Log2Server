# Log2Server
A SyncLog Toolkit for iOS Application Project

There is a project called *Teleport-NSLog* (https://github.com/kennethjiang/Teleport-NSLog) on GitHub, but it request 8080 port. So I wrote a lighter Logger Framework.

## Features

Log2Server collect user defined log only, and split them into single files, each for one time periods of ten minutes long.

You can select the Local Log Storage as to Document or to Cache. By default Cache is used.

You can set the interval for sychronization with seconds. Initialized as one minute in Debug mode and 33 minutes in Product mode.

You can turn on the Debug Log for Log2Server.


## iOS Side

The framework style of Log2Server integration is recommended, instead of the previous method using Objective-C source files directly.

Add `Log2Server` Framework into your iOS project; 

Add framework to Target > Embedded Binaries; 

Note that if the Header File definition is not found, then add framework Headers path of to Build Settings Header Search Paths.

In `- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions` function of `AppDelegate` class, add the Log2Server Class register codes.
	
	[Log2ServerWorker registerServiceWithDeviceSignature:DEVICE_SIGNATURE andServerApi:SERVICE_API];
	[Log2ServerWorker setDebugMode:YES];
    [Log2ServerWorker setUseDocumentStorage:NO];
	#ifdef DEBUG
    [[Log2ServerWorker sharedInstance]setLogSyncInterval:60];
	#else
    [[Log2ServerWorker sharedInstance]setLogSyncInterval:60*5];
	#endif
    
    SLog(@"Log2ServerFrameworkDemo is Okay now if you have found these words on your server.");

If you want to use Log2Server in every file, make use of Prefix Header, and add `#import "Log2Server.h"` into `#ifdef __OBJC__` and `#endif` block. This is recommended for easy using. You can copy the sample if your project is clean enough.

	#ifdef __OBJC__
	#import <UIKit/UIKit.h>
	#import <Foundation/Foundation.h>

	#import "Log2Server.h"

	#endif

Then you can use `SLog` just as `NSLog`, by which the log would be sent to the server.

## Server Side

A PHP Demo has been provided. Just try it.

The result is like:

	root@iZu1q2meizcZ:/var/log/Log2Server/Log2ServerDemo/Log2ServerFrameworkDemo# cat 2015061422_1 
	/var/mobile/Containers/Data/Application/B352F07E-403A-4DFA-81E0-750DBD4B855C/Library/Caches/Cache/	Log2Server/2015061422_1
	[2015-06-14 22:21:55] -[AppDelegate application:didFinishLaunchingWithOptions:] [Line 26] 	Log2ServerFrameworkDemo is Okay now if you have found these words on your server.


