Nova iOS SDK
============

![](http://cdn.photojojo.net/store/awesomeness/productImages/nova-wireless-phone-flash-e5fb.0000001402246485.gif)

Official iOS SDK for [Nova Bluetooth iPhone flash](https://www.novaphotos.com).

*This is version 2 of the SDK which has undergone [significant changes](CHANGES.md) from version 1.
If you are migrating, see migration guide below.*

What does this do?
------------------

* Uses BluetoothLE to discover nearby Nova flashes and communicate with them
* Allows control of multiple flashes (each can be uniquely identified)
* Monitor signal strength of each flash (e.g. which is closest to the phone)
* Supports both automatic and manual connect modes
* Manual connect: clients can explore Nova flashes in range, signal strength and explicitly connect and disconnect as needed
* Automatic connect: SDK will automatically connect to closest flash (single or multiple flashes) or a previously remembered flash
* Provides seamless connection user experience from app - the user does *not* need to explictly pair a flash in Bluetooth settings
* Allow connected flashes to be lit and unlit with user defined brightness and color temperature

What could be done with it?
---------------------------

Just some ideas...

* Integrate with a custom camera app to provide 
* Create a flashlight app
* Morse code beacon
* Use Nova devices as beacons in a location aware app
* Some sweet art

Examples
--------

A hello world app is provided that simply connects to the closest flash and toggles the light on and off every second.

* [Swift example](https://github.com/novaphotos/nova-ios-sdk/blob/master/NovaHelloWorldSwift/NovaHelloWorldSwift/AppDelegate.swift)
* [Objective-C example](https://github.com/novaphotos/nova-ios-sdk/blob/master/NovaHelloWorldObjC/NovaHelloWorldObjC/AppDelegate.m)

Installation
------------

Use [Cocoapods](http://cocoapods.org) and add to your `Podfile`:

```
pod 'NovaSDK', '~> 2.0.0'
```

The library is small and its only dependency is the system CoreBluetooth framework.

Core types
----------

* `NVFlashService`: The core service used to discover nearby flashes. Clients can iterate through available nearby flashes, set rules for auto-connection and pause/resume scanning when the app moves to the background.

* `NVFlashServiceDelegate`: Optional delegate protocol that can be implemented by client to receive callbacks when new flashes are discovered, connected or disconnected.

* `NVFlash`: Each discovered flash. Clients can explicitly connect/disconnect, monitor signal strength and connectivity status, and control the light emitted from each flash.

* `NVFlashSettings`: A configuration used when telling the flash to light up. Includes warm LED brightness, cool LED brightness and a timeout to automatically shutdown the flash.

* `NVFlashStatus`: Enum type describing status of a flash.
   * `Available`: in range and available to be connected to
   * `Unavailable`: no longer in range
   * `Connecting`: connection in progress
   * `Ready`: connected and ready for use
   * `Busy`: connected but currently processing an existing command

Usage
-----

### Initialization

Initialize the Nova flash service. A good time to do this is in `applicationDidFinishLaunching:`.

```objective-c
// Objective-C

// Setup. Do this when app starts.
// A good time is applicationDidFinishLaunching:
NVFlashService *flashService = [NVFlashService new];

// Optionally, set a delegate implementing NVFlashServiceDelegate to be
// notified of flash discovery/connection events.
flashService.delegate = self;
```

```swift
// Swift

// Setup. Do this when app starts.
// A good time is applicationDidFinishLaunching:
let flashService = NVFlashService()

// Optionally, set a delegate implementing NVFlashServiceDelegate to be
// notified of flash discovery/connection events.
flashService.delegate = self
```

In `applicationDidBecomeActive:` you should enable the service, which
activates the Bluetooth radio and begins scanning:

```objective-c
// Objective-C
[flashService enable];
```

```swift
// Swift
flashService.enable()
```

In `applicationWillResignActive:` you should disable the service, which
shuts down the BluetoothLE scanning, conserving the battery life of
both the iPhone and Nova:

```objective-c
// Objective-C
[flashService disable];
```

```swift
// Swift
flashService.disable()
```

### Discovering nearby flashes

While the flash service is enabled it will automatically perform Bluetooth scans to discover
nearby flashes.

There are two options for knowing which flashes are in range:
1. Periodically at the contents of `flashService.flashes` or `flashService.connectedFlashes` array
2. Receive a callback by implementing the `NVFlashServiceDelegate` protocol

#### Iterating over flashes array

The `NVFlashService.flashes` array contains `NVFlash` objects and can be queried at any time and returns all flashes that have been discovered.

The `NVFlashService.connectedFlashes` is similar except it contains the subset of flashes that are currently connected.

```objective-c
// Objective-C
for (id<NVFlash> flash in flashService.flashes) { // alternatively flashService.connectedFlashes
  NSLog(@"flash: identifier=%@, status=%@, signalStrength=%f",
        flash.identifier,                  // unique ID assigned to each flash
        NVFlashStatusString(flash.status), // connectivity status
        flash.signalStrength);             // value from 0.0 (weakest) to 1.0 (strongest)
}
```

```swift
// Swift
for flash in flashService.flashes as [NVFlash] { // alternatively flashService.connectedFlashes
  NSLog("flash: identifier=%@, status=%@, signalStrength=%f",
        flash.identifier,                  // unique ID assigned to each flash
        NVFlashStatusString(flash.status), // connectivity status
        flash.signalStrength)              // value from 0.0 (weakest) to 1.0 (strongest)
}
```

#### Receiving delegate callbacks

Optionally, a client may implement the `NVFlashServiceDelegate` protocol and set it as the `flashService.delegate` to receive callbacks as discovery and connection events occur.

```objective-c
// Objective-C

// Implement NVFlashServiceDelegate protocol. All methods are optional.

- (void) flashServiceAddedFlash:(id<NVFlash>)flash {
  NSLog(@"added flash %@", flash.identifier);
}

- (void) flashServiceRemovedFlash:(id<NVFlash>)flash {
  NSLog(@"removed flash %@", flash.identifier);
}

- (void) flashServiceConnectedFlash:(id<NVFlash>)flash {
  NSLog(@"connected flash %@", flash.identifier);
}

- (void) flashServiceDisconnectedFlash:(id<NVFlash>)flash {
  NSLog(@"disconnected flash %@", flash.identifier);
}

```

```swift
// Swift

// Implement NVFlashServiceDelegate protocol. All methods are optional.

func flashServiceAddedFlash(flash: NVFlash) {
  NSLog("added flash %@", flash.identifier)
}

func flashServiceRemovedFlash(flash: NVFlash) {
  NSLog("removed flash %@", flash.identifier)
}

func flashServiceConnectedFlash(flash: NVFlash) {
  NSLog("connected flash %@", flash.identifier)
}

func flashServiceDisconnectedFlash(flash: NVFlash) {
  NSLog("disconnected flash %@", flash.identifier)
}
```

### Connecting to flashes

There are two ways to connect to flashes:
1. Manually call `connect`/`disconnect` on `NVFlash` instances of interest. This gives the most control.
2. Enable `autoConnect` and allow the flash service to automatically connect to the closest Nova for you. This is the simplest.

#### Auto connect

This is the recommend approach as it lets the flash service do the hard work for you.

When `autoConnect` is enabled,the flash service will periodically attempt to connect to a suitable Nova (or multiple Novas). Clients will know when a Nova is connected by looking at the `flashService.connectedFlashes` array or handling `flashServiceConnectedFlash:`/`flashServiceDisconnectedFlash:` callbacks.

##### Auto connect to the closest Nova

```objective-c
// Objective-C

// call this after initializing NVFlashService
flashService.autoConnect = YES;
```

```swift
// Swift

// call this after initializing NVFlashService
flashService.autoConnect = true
```

The default auto connect rules will attempt to connect to:
* just **1** Nova at a time
* the Nova with the strongest signal strength
* from the set **all** discovered Novas with signal strength >0.1 (10%)

##### Auto connect to multiple Novas

The above rules can be changed. For example:

```objective-c
// Objective-C

flashService.autoConnectMaxDevices = 4;          // connect to the 4 closest Novas
flashService.autoConnectMinSignalStrength = 0.5; // require signal strength >=50%
```

```swift
// Swift

flashService.autoConnectMaxDevices = 4           // connect to the 4 closest Novas
flashService.autoConnectMinSignalStrength = 0.5  // require signal strength >=50%
```

##### Remember a Nova and only auto connect to that

In some cases clients may wish to remember a flash and only reconnect to that same flash (or flashes) in the future.

To do this, clients should store a list of `NVFlash.identifier` values. These are strings that could be persisted locally. Each string is unique for a given flash.

Upon reconnecting:

```objective-c
// Objective-C

// Only auto connect to specific flashes.
// Identifiers are strings previously obtained from NVFlash.identifier
flashService.autoConnectWhiteList = @[identifier1, identifier2];
```
```swift
// Swift

// Only auto connect to specific flashes.
// Identifiers are strings previously obtained from NVFlash.identifier
flashService.autoConnectWhiteList = [identifier1, identifier2]
```

#### Manual connection

For clients that want more control over which Novas to connect to, the individual `NVFlash` instances can be iterated over (see above) and explicitly connected/disconnected at appropriate times.

**Important**: Do not attempt to manually connect to flashes if `autoConnect` is enabled. If in doubt use `autoConnect` instead (see above) - it's much simpler.

```objective-c
// Objective-C

id<NVFlash> flash = /* whichever flash instance */;

// to connect
[flash connect];

// to disconnect
[flash disconnect];
```

```objective-c
// Objective-C

let flash: NVFlash = /* whichever flash instance */

// to connect
flash.connect()

// to disconnect
flash.disconnect()
```

#### Lighting up Nova

Nova contains banks of LEDs, half of which have a warm white tint and the other half have a cool white tint. The brightness of both banks can be controlled individually for different variations of brightness and color temperature.

##### Choosing brightness and color temperature

The `NVFlashSettings` object holds the desired brightness/temperature settings. The fields are:
* `warm`: Brightness of warm LEDs from 0 (off) to 255 (full brightness)
* `cool`: Brightness of cool LEDs from 0 (off) to 255 (full brightness)

For convenience, there are presets used for commonly used settings:

```objective-c
// Objective-C

NSFlashSettings *settings = [NFFlashSettings bright];

// or...
NSFlashSettings *settings = [NFFlashSettings gentle];
NSFlashSettings *settings = [NFFlashSettings neutral];
NSFlashSettings *settings = [NFFlashSettings warm];
NSFlashSettings *settings = [NFFlashSettings customWarm:123, cool:201];
```

```swift
// Swift

let settings = NFFlashSettings.bright()

// or...
let settings = NFFlashSettings.gentle()
let settings = NFFlashSettings.neutral()
let settings = NFFlashSettings.warm()
let settings = NFFlashSettings.custom()
let settings = NFFlashSettings.customWarm(123, cool: 201)
```

##### Turning on the lights

Once the settings (see above) have been defined, use `beginFlash` to send a message to the flash to activate the LEDs.

*Important*: Due to the nature of BluetoothLE, there is a slight delay between making this call and the LEDs actually lighting up. If timing is important, you can pass a callback that will be called when the flash has acknowledged that the LEDs are on.

```objective-c
// Objective-C

id<NVFlash> flash = /* whichever flash you want to control */;

// Fire and forget. Flash typically lights up within 100-200 milliseconds.
[flash beginFlash:settings];

// Alternatively, fire and pass a callback to know when flash has responded
[flash beginFlash:settings withCallback:^(BOOL success) {
  if (success) {
    NSLog(@"Flash is now lit up");
  } else {
    NSLog(@"Flash failed to light. Try charging it.");
  }
}];
```

```swift
// Swift

let flash: NVFlash = // whichever flash you want to control

// Fire and forget. Flash typically lights up within 100-200 milliseconds.
flash.beginFlash(settings)

// Alternatively, fire and pass a callback to know when flash has responded
flash.beginFlash(settings) {success in
  if (success) {
    NSLog("Flash is now lit up")
  } else {
    NSLog("Flash failed to light. Try charging it.")
  }
}
```

##### Turning off the lights

To turn off the lights, call `endFlash`.

```objective-c
// Objective-C

[flash.endFlash];
```

```swift
// Swift

flash.endFlash()
```

Like `beginFlash`, you may also pass a callback to `endFlash` to get notified when the flash has acknowledged that it's now off.

##### Flash timeouts

The Nova hardware includes a timeout feature to automatically turn the flash off after a certain amount of time. This is a safety mechanism to ensure that if an app crashes or other unexpected events occur on the phone, the flash will not remain on and drain all the battery.

The **default timeout is 10 seconds**. This is approximate because Nova does not contain a high resolution timer. In reality it will be accurate with about 20% tolerance.

To change the timeout, you can modify the `NVFlashSettings`.

```objective-c
// Objective-C

NVFlashSettings *settings = [[NVFlashSettings warm] flashSettingsWithTimeout:20000)]; // in milliseconds
```

```swift
// Swift

let settings = NVFlashSettings.warm().flashSettingsWithTimeout(20000) // in milliseconds
```

### Putting it all together

Here's that hello world app again. It demonstrates initializing the service, auto connecting to the closest Nova, listening to connect/disconnect events and controlling the light.

* [Swift example](https://github.com/novaphotos/nova-ios-sdk/blob/master/NovaHelloWorldSwift/NovaHelloWorldSwift/AppDelegate.swift)
* [Objective-C example](https://github.com/novaphotos/nova-ios-sdk/blob/master/NovaHelloWorldObjC/NovaHelloWorldObjC/AppDelegate.m)

Coordinating a camera flash
---------------------------

If you are integrating Nova into a camera app, here is the basic flow of events for taking a photo.

Triggering a flash should only be attempted when `flashService.status == NVFlashServiceReady`.

```objective-c
// Objective-C

// Step 1: Tell flash to activate.
[flash beginFlash:settings withCallback:^ (BOOL success) {
  
  // Step 2: This callback is called when the flash has acknowledged that
  //         it is lit.
  
  // Check whether flash activated succesfully.
  if (success) {
    
    // Step 3: Tell camera to take photo.
    [myCameraAbstraction takePhotoWithCallback:(^ {
      
      // Step 4: When photo has been captured, turn the flash off.
      [flashService:endFlashWithCallback:(^ {
        // Step 5: Done. Ready to take another photo.
      })];
        
    })];
        
  } else {
    // Error: flash could not be triggered.
  }
}];
```

```swift
// Swift

// Step 1: Tell flash to activate.
flash.beginFlash(settings) { success in

  // Step 2: This callback is called when the flash has acknowledged that
  //         it is lit.
  
  // Check whether flash activated succesfully.
  if (success) {
    
    // Step 3: Tell camera to take photo.
    myCameraAbstraction.takePhotoWithCallback() {
      
      // Step 4: When photo has been captured, turn the flash off.
      flashService.endFlash() { success in
        // Step 5: Done. Ready to take another photo.
      }
        
    }
        
  } else {
    // Error: flash could not be triggered.
  }
}
```

Hints and tips. Tints and hips.
-------------------------------

### Observing flash property changes

Standard [key-value observing](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html) can be used on the `NVFlash` instance fields (e.g. `status`, `signalStrength`,  `lit`) to monitor when something about the flash changes. It is recommend to add/remove observers in either `flashServiceFlashAdded:`/`flashServiceFlashRemoved:` or `flashServiceConnectedFlash:`/`flashServiceDisconnectedFlash:` delegate callbacks.

### Threading

This library should only ever be called from the main thread. All calls are fast and non-blocking.

### Short light burts

For short bursts of light, it's often simpler to use a timeout on `NVFlashSettings` instead of explicitly calling `endFlash`.

Need help?
----------

The Nova hardware and software was created by [Joe Walnes](https://github.com/joewalnes). For help email hello@novaphotos.com or raise a GitHub issue.

Links
-----

* [www.novaphotos.com](https://www.novaphotos.com)
* [Nova Camera App on AppStore](https://itunes.apple.com/us/app/novacamera/id837854692) (uses this SDK)
* [Where to buy](https://www.novaphotos.com/shop) (including Apple Store, Amazon, Photojojo...)
* @joewalnes on [GitHub](https://github.com/joewalnes), [Twitter](https://twitter.com/joewalnes], [Medium](https://medium.com/@joewalnes)
* [More Nova open source repositories](https://github.com/novaphotos) (including apps, Android SDK and protocol documentation)

 
Photo by [Photojojo](http://photojojo.com/store/awesomeness/nova-wireless-phone-flash/)
