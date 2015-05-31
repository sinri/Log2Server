# Log2Server
A SyncLog Toolkit for iOS Application Project

There is a project called *Teleport-NSLog* (https://github.com/kennethjiang/Teleport-NSLog) on GitHub, but it request 8080 port. So I wrote a lighter Logger Framework.

By default, the log cached in the Documents, you can change it to Cache by modify the codes. Any way, I might change it later. Too late today, tired.

## iOS Side

Add `Log2Server` Class to your iOS project;

In `- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions` function of `AppDelegate` class, add the Log2Server Class register codes.
	
	[Log2Server registerServiceWithDeviceSignature:DEVICE_SIGNATURE andServerApi:SERVICE_API];

If you want to use Log2Server in every file, make use of Prefix Header, and add `#import "Log2Server.h"` into `#ifdef __OBJC__` and `#endif` block. This is recommended for easy using. You can copy the sample if your project is clean enough.

	#ifdef __OBJC__
	#import <UIKit/UIKit.h>
	#import <Foundation/Foundation.h>

	#import "Log2Server.h"

	#endif

Then you can use `SLog` just as `NSLog`, by which the log would be sent to the server.

## Server Side

A PHP Demo has been provided. Just try it.