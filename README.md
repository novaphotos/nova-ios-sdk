Nova iOS SDK
============

Official iOS SDK for [Nova](https://novaphotos.com/).

-@joewalnes

Features
--------

The Nova SDK takes care of:
* Discovering a nearby Nova device and automatically pairing with it. Users do not need to manually pair.
* Establishing a connection with a Nova device whenever it is in range. Connection status can be monitored in apps using KVO.
* At request of app triggering the flash with specified warm and cool LED brightness.


Installation
------------

Easiest way to get the library is via [CocoaPods](http://cocoapods.org/):
```ruby
  pod 'NovaSDK'
```

If that's not your cup of cocoa, then clone the repo and include the source in your project. It has no extra third party dependencies.

You also need to include **Core Bluetooth Framework** in your project dependencies. 

Usage
-----

### Initialization

Initialize the Nova flash service. A good time to do this is in `applicationDidFinishLaunching:`.

```objective-c
#import "NVFlashService.h"

// Setup. Do this when app starts.
// A good time is applicationDidFinishLaunching:
NVFlashService *flashService = [NVFlashService new];

```

In `applicationDidBecomeActive:` you should enable the service, which
activates the Bluetooth radio and begins scanning:

```objective-c
[flashService enable];
```

In `applicationWillResignActive:` you should disable the service, which
shuts down the BluetoothLE scanning, conserving the battery life of
both the iPhone and Nova:

```objective-c
[flashService disable];
```


### Monitoring connection status

You can read the status of `flashService.status` at any time.

You can observe when the status changes, using standard Objective-C key-value-observing.

The enum values of `NVFlashServiceStatus` are:

``` 
NVFlashServiceDisabled     // BluetoothLE is not available on this device.
NVFlashServiceIdle         // No device connected, we will scan soon.
NVFlashServiceScanning     // No device  onnected, but we're currently scanning.
NVFlashServiceConnecting   // Device found and attempting to establish a connection.
NVFlashServiceReady        // Connection to device is ready and waiting for flashes. Yay.
```

Basically, `NVFlashServiceReady` is the good one.


### Choosing the flash temperature/brightness settings

```objective-c
NVFlashSettings *flashSettings = [NVFlashSettings warm];

// or
NVFlashSettings *flashSettings = [NVFlashSettings gentle];

// or
NVFlashSettings *flashSettings = [NVFlashSettings neutral];

// or
NVFlashSettings *flashSettings = [NVFlashSettings bright];

// or (custom settings in range 0-255)
NVFlashSettings *flashSettings = [NVFlashSettings customWarm:255 cool:127];
```

### Trigger the flash

Because there can be slight (and hard to predict) latencies in Bluetooth
and also in the iPhone camera shutter time, the sequence is coordinated
by a sequence of callbacks.

Triggering a flash should only be attempted when `flashService.status == NVFlashServiceReady`.

The basic flow of control in a camera app should be:

1. User requests a photo should be taken
2. Camera app asks SDK to begin flash (with given brightness settings)
3. SDK calls back to app when the flash is lit
4. Camera app should wait for focus/exposure/whitebalance to finish adjusting
5. Camera app should capture photo
6. When photo is captured, camera app should ask SDK to end flash

```objective-c

// Step 1: Tell flash to activate.
[flashService beginFlash:flashSettings withCallback:^ (BOOL success) {

  // Step 2: This callback is called when the flash has acknowledged that
  //         it is lit.

  // Check whether flash activated succesfully.
  if (success) {

    // Step 3: Tell camera to take photo. Wait for focus/exposure to stop adjusting.
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

Supported Devices
-----------------

This SDK requires Apple's CoreBluetooth framework that relies on iOS 5 or greater.

Phones need to be equiped with BluetoothLE hardware in order to connect to Nova. Supported devices:
* iPhone 5s, 5c, 5, 4s
* iPad Air, Mini, 4, 3
* iPod Touch 5th generation

If a phone is not supported, the SDK will report it's status as `NVFlashServiceReady`.


Example App
-----------

There's a [test application](NovaSDKTestApp) for exploring the SDK. It doesn't have any camera capabilities but it offers controls for manually exploring the API and triggering the flash with different settings.
