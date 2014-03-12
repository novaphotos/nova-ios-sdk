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
    
    flashService = [NVFlashService new];
    
    // Defaults
    
    flashSettings = [NVFlashSettings warm];
    flashPresets.selectedSegmentIndex = 2;
    
    flashService.autoPairMode = NVAutoPairClosest;
    pairMode.selectedSegmentIndex = 1;
    
    [self showFlashServiceStatus:flashService.status];
    // Watch for flashService.status changes.
    [flashService addObserver:self
                   forKeyPath:NSStringFromSelector(@selector(status))
                      options:0
                     context:NULL];
    
    [self changeFlashPreset:0];
}

// KVO event fired when flashService.status changes.
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == flashService && [keyPath isEqualToString:NSStringFromSelector(@selector(status))]) {
        [self showFlashServiceStatus: flashService.status];
    }
}

// Called by AppDelegate on applicationWillBecomeActive
- (void)appWake
{
    [self logFrom:@"App" msg:@"Wake"];
    [flashService enable];
}

// Called by AppDelegate on applicationWillResignActive
- (void)appSleep
{
    [self logFrom:@"App" msg:@"Sleep"];
    [flashService disable];
}


#pragma mark Respond to user interaction

// Called when user taps 'enable'
- (IBAction)tapEnable:(id)sender
{
    [self logFrom:@"User" msg:@"Enable"];
    [flashService enable];
}

// Called when user taps 'disable'
- (IBAction)tapDisable:(id)sender
{
    [self logFrom:@"User" msg:@"Disable"];
    [flashService disable];
}

// Called when user changes pairing mode
- (IBAction)changePairMode:(id)sender
{
    NSString *modeText;
    switch (pairMode.selectedSegmentIndex) {
        case 0:
            modeText = @"None";
            flashService.autoPairMode = NVAutoPairNone;
            break;
        case 1:
            modeText = @"Closest";
            flashService.autoPairMode = NVAutoPairClosest;
            break;
        case 2:
            modeText = @"All";
            flashService.autoPairMode = NVAutoPairAll;
            break;
        default:
            [self panic:@"changePairMode invalid value"];
            return;
    }
    [self logFrom:@"User" msg:[@"Change pair mode: " stringByAppendingString:modeText]];
}

// Called when user taps 'refresh'
- (IBAction)tapRefresh:(id)sender
{
    [self logFrom:@"User" msg:@"Refresh"];
    [flashService refresh];
}

// Called when user changes chooses a new flash segment
- (IBAction)changeFlashPreset:(id)sender
{
    NSString *presetText;
    bool enableCustomSlider = NO;
    switch (flashPresets.selectedSegmentIndex) {
        case 0:
            presetText = @"Off";
            flashSettings = [NVFlashSettings off];
            break;
        case 1:
            presetText = @"Gentle";
            flashSettings = [NVFlashSettings gentle];
            break;
        case 2:
            presetText = @"Warm";
            flashSettings = [NVFlashSettings warm];
            break;
        case 3:
            presetText = @"Bright";
            flashSettings = [NVFlashSettings bright];
            break;
        case 4:
            presetText = @"Custom";
            enableCustomSlider = YES;
            [self customSliderChange:sender]; // Update custom values
            break;
        default:
            [self panic:@"changeFlashPreset invalid value"];
            return;
    }
    warmValue.hidden = !enableCustomSlider;
    coolValue.hidden = !enableCustomSlider;
    warmSlider.hidden = !enableCustomSlider;
    coolSlider.hidden = !enableCustomSlider;
    [self logFrom:@"User" msg:[@"Change flash preset: " stringByAppendingString:presetText]];
}

- (IBAction)customSliderChange:(id)sender
{
    uint8_t warm = warmSlider.value;
    uint8_t cool = coolSlider.value;
    warmValue.text = [NSString stringWithFormat:@"Warm: %d", warm];
    coolValue.text = [NSString stringWithFormat:@"Cool: %d", cool];
    flashSettings = [NVFlashSettings customWarm:warm cool:cool];
}

// Called when user presses flash button down
- (IBAction)flashButtonDown:(id)sender
{
    [self logFrom:@"User" msg:@"Flash button down"];
    
    [flashService beginFlash:flashSettings withCallback:^ (BOOL success) {
        [self logFrom:@"Nova" msg:(success ? @"Flash activated" : @"Flash FAILED to activate")];
        [self updateFlashButton];
    }];
    [self updateFlashButton];
}

// Called when user releases flash button
- (IBAction)flashButtonUp:(id)sender
{
    [self logFrom:@"User" msg:@"Flash button up"];

    [flashService endFlashWithCallback:^ (BOOL success) {
        [self logFrom:@"Nova" msg:(success ? @"Flash deactivated" : @"Flash FAILED to deactivate")];
        [self updateFlashButton];
    }];
    [self updateFlashButton];
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

- (void)showFlashServiceStatus:(NVFlashServiceStatus) serviceStatus
{
    switch (serviceStatus) {
        case NVFlashServiceDisabled:
            status.text = @"Disabled";
            status.textColor = [UIColor redColor];
            break;
        case NVFlashServiceIdle:
        case NVFlashServiceScanning:
            status.text = @"Scanning...";
            status.textColor = [UIColor orangeColor];
            break;
        case NVFlashServiceConnecting:
            status.text = @"Connecting...";
            status.textColor = [UIColor blueColor];
            break;
        case NVFlashServiceReady:
            status.text = @"Ready";
            status.textColor = [UIColor colorWithRed:0 green:0.7 blue:0 alpha:1];
            break;
        default:
            [self panic:@"Invalid service status"];
    }
    [self logFrom:@"Nova" msg:[@"Status changed: " stringByAppendingString:status.text]];
    [self updateFlashButton];
}

- (void)updateFlashButton
{
    flash.enabled = flashService.status == NVFlashServiceReady && !flashService.commandInProgress;
}

#pragma mark Utils

// Something bad happened.
- (void)panic:(NSString *) msg
{
    NSLog(@"PANIC: %@", msg);
    exit(1);
}

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
