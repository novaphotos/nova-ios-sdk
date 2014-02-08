//
//  SSViewController.m
//  NovaSDKTestApp
//
//  Created by Joe Walnes on 2/8/14.
//  Copyright (c) 2014 Sneaky Squid. All rights reserved.
//

#import "SSViewController.h"

@interface SSViewController ()

@end

@implementation SSViewController


#pragma mark Application lifecycle

// Setup
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self logFrom:@"App" msg:@"Launched"];
    status.text = @"Ready";
}

// Called by AppDelegate on applicationWillResignActive
- (void)appSleep
{
    [self logFrom:@"App" msg:@"Sleep"];
}

// Called by AppDelegate on applicationWillBecomeActive
- (void)appWake
{
    [self logFrom:@"App" msg:@"Wake"];
}


#pragma mark Respond to user interaction

// Called when user taps 'enable'
- (IBAction)tapEnable:(id)sender
{
    [self logFrom:@"User" msg:@"Enable"];
}

// Called when user taps 'disable'
- (IBAction)tapDisable:(id)sender
{
    [self logFrom:@"User" msg:@"Disable"];
}

// Called when user changes pairing mode
- (IBAction)changePairMode:(id)sender
{
    NSString *modeText = @"???";
    switch (pairMode.selectedSegmentIndex) {
        case 0:
            modeText = @"None";
            break;
        case 1:
            modeText = @"Closest";
            break;
        case 2:
            modeText = @"All";
            break;
    }
    [self logFrom:@"User" msg:[@"Change pair mode: " stringByAppendingString:modeText]];
}

// Called when user taps 'refresh'
- (IBAction)tapRefresh:(id)sender
{
    [self logFrom:@"User" msg:@"Refresh"];
}

// Called when user changes chooses a new flash segment
- (IBAction)changeFlashPreset:(id)sender
{
    // TODO: Support custom flash settings.
    NSString *presetText = @"???";
    switch (pairMode.selectedSegmentIndex) {
        case 0:
            presetText = @"Off";
            break;
        case 1:
            presetText = @"Gentle";
            break;
        case 2:
            presetText = @"Warm";
            break;
        case 3:
            presetText = @"Bright";
            break;
    }
    [self logFrom:@"User" msg:[@"Change flash preset: " stringByAppendingString:presetText]];
}

// Called when user presses flash button down
- (IBAction)flashButtonDown:(id)sender
{
    // TODO: Allow user to specify timeout.
    [self logFrom:@"User" msg:@"Flash button down" ];
}

// Called when user releases flash button
- (IBAction)flashButtonUp:(id)sender
{
    [self logFrom:@"User" msg:@"Flash button up"];
}


#pragma mark Display information to user

// Log a message to the user. The source indicates what generated the message (e.g. "App", "User", "Bluetooth"...).
- (void)logFrom:(NSString*)source msg:(NSString*)msg
{
    NSLog(@"[%@] %@", source, msg);

    NSString *formatted = [NSString stringWithFormat:@"\n%@ [%@] %@", [self timestamp], source, msg];
    log.text = [log.text stringByAppendingString: formatted];
    [self scrollToEnd:log];
}


#pragma mark Utils

// Return the time as a string. e.g. "3:22.15PM"
- (NSString *)timestamp
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    return [dateFormatter stringFromDate:[NSDate date]];
}

// Scroll UITextView to end
- (void)scrollToEnd:(UITextView *)textView
{
    [textView scrollRangeToVisible:NSMakeRange(textView.text.length - 1, 1)];
    // iOS7 glitch: http://stackoverflow.com/questions/19124037/
    textView.scrollEnabled = NO;
    textView.scrollEnabled = YES;
}

@end
