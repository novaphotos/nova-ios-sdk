// This is a super-simple 'hello world' app that demonstrates how to control
// a Nova Bluetooth flash.
//
// See https://www.novaphotos.com/
// And https://github.com/novaphotos/nova-ios-sdk
//
// To keep things simple, this iOS app has no UI or camera. It simply connects
// to the closest flash and toggles the light every second.
//
// -Joe Walnes

#import "AppDelegate.h"

@implementation AppDelegate
{
    NVFlashService *flashService;
    NSTimer *timer;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    NSLog(@"init");
    
    // Initialize flash service
    flashService = [NVFlashService new];
    
    // Optional: receive callbacks when flashes come into range or are connected/disconnected
    flashService.delegate = self;
    
    // Auto connect to closest flash
    flashService.autoConnect = YES;
    
    // Uncomment to auto connect to more than one flash
    // flashService.autoConnectMaxFlashes = 4;
    
    // Set a timer to toggle flash every second.
    timer = [NSTimer scheduledTimerWithTimeInterval:1
                                             target:self
                                           selector:@selector(toggleFlash)
                                           userInfo:nil
                                            repeats:true];
}

// When app is active enable bluetooth scanning
- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"enable");
    
    [flashService enable];
}

// When app is not active, shut down bluetooth to conserve battery life
- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"disable");
    
    [flashService disable];
}

// Called every second by timer
- (void) toggleFlash {
    
    // choose the brightness and color temperature
    // warm/gentle/neutral/bright/custom/...
    NVFlashSettings *flashSettings = [NVFlashSettings warm];
    
    // loop through all connected flashes
    // typically just 1, but change autoConnectMaxFlashes above for more
    for (id<NVFlash> flash in flashService.connectedFlashes) {
        
        // toggle flash
        if (!flash.lit) {
            NSLog(@"activate   flash %@", flash.identifier);
            [flash beginFlash:flashSettings];
        } else {
            NSLog(@"deactivate flash %@", flash.identifier);
            [flash endFlash];
        }
        
    }
}

// Optional NVFlashServiceDelegate callbacks to monitor connections

- (void) flashServiceConnectedFlash:(id<NVFlash>)flash {
    NSLog(@"connected  flash %@", flash.identifier);
}

- (void) flashServiceDisconnectedFlash:(id<NVFlash>)flash {
    NSLog(@"disconnect flash %@", flash.identifier);
}

@end
