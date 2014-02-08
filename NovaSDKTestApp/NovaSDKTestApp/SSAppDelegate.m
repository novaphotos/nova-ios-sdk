//
//  SSAppDelegate.m
//  NovaSDKTestApp
//
//  Created by Joe Walnes on 2/8/14.
//  Copyright (c) 2014 Sneaky Squid. All rights reserved.
//

#import "SSAppDelegate.h"
#import "SSViewController.h"

@implementation SSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    viewController = (SSViewController *)self.window.rootViewController;
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    [viewController appSleep];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [viewController appWake];
}

@end
