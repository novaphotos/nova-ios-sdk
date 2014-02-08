//
//  SSAppDelegate.h
//  NovaSDKTestApp
//
//  Created by Joe Walnes on 2/8/14.
//  Copyright (c) 2014 Sneaky Squid. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSViewController.h"

@interface SSAppDelegate : UIResponder <UIApplicationDelegate>
{
    SSViewController *viewController;
}

@property (strong, nonatomic) UIWindow *window;

@end
