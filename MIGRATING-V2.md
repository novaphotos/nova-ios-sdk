## Migrating from NovaSDK 1.x.x to 2.x.x

Version 2 of the NovaSDK is a complete re-write and is the API is not backwards compatible.

[See changes](CHANGES.md)

### High level changes

#### Multiple Novas and introduction of NVFlash objects

In V1, the primary interface was a single `NVFlashService` instance that could control at most 1 flash at a time.

In V2, there is still a single `NVFlashService` instance but it is responsible for  discovering potentially many
`NVFlash` instances, each of which can be controlled individually.

#### Auto connect vs manual connect

In V1, pretty much the only option was to connect to the first discovered Nova.

In V2, clients can manually connect/disconnect to/from any discovered flashes (many at a time if necessary).

In addition, V2 offers convenient and flexible auto connect rules to automatically connect to 1 or more Novas
that meet user defined criteria.

V2 also exposes unique identifiers associated with each Nova and allows auto connection to Novas with specific
identifiers, allowing apps to *remember* which Nova they should be connected to.

#### Signal strength detection

The signal strength for each Nova is exposed allowing this to be displayed in an interface or used to determine
which Nova to connect to.

The auto connection mechanism uses this to auto connect to the closest Nova(s).

### API changes

#### NVFlashService

* Removed `autoPairMode` (and `NVAutoPair` enum): This never worked and has been replaced with a new `autoConnect` mechanism.
* Removed `refesh`: To reconnect, ensure `autoConnect` is enabled and call `disconnectAll`.
* Added `flashes` (array of NVFlash instances): All known flashs that have been discovered.
* Added `connectedFlashes` (array of NVFlash instances): Subset of flashes - those that are connected.
* Added `flashWithIdentifier:` to attempt to locate a specific flash.
* Added `NVFlashServiceDelegate` protocol: Clients can set themselves as delegates to receive notification when new flashes
  discovered, connected or disconnected.
* Added `autoConnect` boolean: Set to true/YES to enable auto connect mode. Default = false.
* Added `autoConnectMaxFlashes`: Specify how many flashes to connect to. Default = 1.
* Added `autoConnectMinSignalStrength: Specifiy min signal strength required to connect to flash. Default = 0.1 (10%)
* Added `autoConnectWhitelist`/`autoConnectBlacklist`: More control of flashes to attempt to connect or not connect to.
* Moved `beginFlash`, `endFlash`, `pingFlash` methods to `NVFlash` instance.
* Changed `status`: Many of the `NVFlashServiceStatus` states associated with `NVFlashService` have now been moved 
  to `NVFlashStatus` as they are specific to a flash instance. Key value observable.

#### NVFlash

This is a new type that represents each known flash.

* Added `identifier`: Unique identifier string that can be used to remember a given flash for use later.
* Added `status`: Many of the `NVFlashServiceStatus` states associated with `NVFlashService` have now been moved 
  to `NVFlashStatus` as they are specific to a flash instance. Key value observable.
* Added `signalStrength`: Value from 0.0 (weakest) to 1.0 (strongest). Key value observable.
* Added `lit` bool: Shows whether flash is currently lit up. Key value observable.
* Added `connect`/`disconnect`: For manual connect/disconnect if autoConnect is not used.

### Examples

* [Swift example](https://github.com/novaphotos/nova-ios-sdk/blob/master/NovaHelloWorldSwift/NovaHelloWorldSwift/AppDelegate.swift)
* [Objective-C example](https://github.com/novaphotos/nova-ios-sdk/blob/master/NovaHelloWorldObjC/NovaHelloWorldObjC/AppDelegate.m)
