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

import UIKit

@UIApplicationMain
class AppDelegate: NSObject, UIApplicationDelegate, NVFlashServiceDelegate {

    var flashService: NVFlashService!
    var timer: NSTimer!

    func applicationDidFinishLaunching(application: UIApplication) {
        NSLog("init")

        // Initialize flash service
        flashService = NVFlashService()
        
        // Optional: receive callbacks when flashes come into range or are connected/disconnected
        flashService.delegate = self
        
        // Auto connect to closest flash
        flashService.autoConnect = true
        
        // Uncomment to auto connect to more than one flash
        // flashService.autoConnectMaxFlashes = 4
        
        // Set a timer to toggle flash every second.
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self,
            selector: Selector("toggleFlash"), userInfo: nil, repeats: true)
    }

    // When app is active enable bluetooth scanning
    func applicationDidBecomeActive(application: UIApplication) {
        NSLog("enable")

        flashService.enable()
    }
    
    // When app is not active, shut down bluetooth to conserve battery life
    func applicationWillResignActive(application: UIApplication) {
        NSLog("disable")

        flashService.disable()
    }

    // Called every second by timer
    func toggleFlash() {
        
        // choose the brightness and color temperature
        // warm/gentle/neutral/bright/custom/...
        let flashSettings = NVFlashSettings.warm()
        
        // loop through all connected flashes
        // typically just 1, but change autoConnectMaxFlashes above for more
        for flash in flashService.connectedFlashes as [NVFlash] {
            
            // toggle flash
            if (!flash.lit) {
                NSLog("activate   flash %@", flash.identifier)
                flash.beginFlash(flashSettings)
            } else {
                NSLog("deactivate flash %@", flash.identifier)
                flash.endFlash()
            }
            
        }
    }

    // Optional NVFlashServiceDelegate callbacks to monitor connections

    func flashServiceConnectedFlash(flash: NVFlash) {
        NSLog("connected  flash %@", flash.identifier)
    }

    func flashServiceDisconnectedFlash(flash: NVFlash) {
        NSLog("disconnect flash %@", flash.identifier)
    }

}

