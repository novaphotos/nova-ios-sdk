Nova iOS SDK
============

Official iOS SDK for Nova.

http://www.kickstarter.com/projects/joewalnes/nova-a-slim-wireless-flash-for-better-iphone-photo

https://wantnova.com/

https://wantnova.com/sdk/

Here's a [test application](NovaSDKTestApp) for exploring the SDK.

-@joewalnes


Usage
-----

### Initialization

Initialize the Nova flash service. A good time to do this is in `applicationDidFinishLaunching:`.

```objective-c
#import "NVFlashService.h"

// Setup. Do this when app starts.
// A good time is applicationDidFinishLaunching:
NVFlashService *flashService = [NVFlashService new];

// Set which Nova devices to automatically pair with.
// Options: NVAutoPairClosest, NVAutoPairAll or NVAutoPairNone.
// This can be changed at any time while the app is running
// and it will reconnect.
flashService.autoPairMode = NVAutoPairClosest;
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
NVFlashServiceIdle         // No devices are connected, we will scan for some soon.
NVFlashServiceScanning     // No devices are connected, but we're currently scanning for some.
NVFlashServiceConnecting   // Device(s) found and attempting to establish a connection.
NVFlashServiceReady        // Connection to device is ready and waiting for flashes. Yay.
```

Basically, `NVFlashServiceReady` is the good one.


### Choosing the flash temperature/brightness settings

```objective-c
NVFlashSettings *flashSettings = [NVFlashSettings warm];
                                               // or off, gentle, bright, custom...
```

### Trigger the flash

Because there can be slight (and hard to predict) latencies in Bluetooth
and also in the iPhone camera shutter time, the sequence is coordinated
by a sequence of callbacks.

Triggering a flash should only be attempted when `flashService.status == NVFlashServiceReady`.

```objective-c

// Step 1: Tell flash to activate.
[flashService beginFlash:flashSettings withCallback:^ (BOOL success) {

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

