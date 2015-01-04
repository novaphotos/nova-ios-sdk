//  The MIT License (MIT)
//
//  Copyright (c) 2013-2015 Joe Walnes, Sneaky Squid LLC.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "NVFlash.h"

#define RSSI_UNAVAILABLE 127


/**
 * Status of flash service.
 */
typedef NS_ENUM(NSInteger, NVFlashServiceStatus)
{
    
    /**
     * BluetoothLE is not available on this device. This could be because the device does
     * not support it, it's currently disabled, or the user has not granted the app
     * permission to use it.
     */
    NVFlashServiceDisabled,
    
    /**
     * Not currently scanning for nearby devices.
     */
    NVFlashServiceIdle,
    
    /**
     * Currently scanning for nearby devices.
     */
    NVFlashServiceScanning
    
};


/**
 * Convenience function to convert NFFlashServiceStatus into string (e.g. "Scanning").
 * These strings are not localized and are meant primarily for debug logging.
 */
NSString *NVFlashServiceStatusString(NVFlashServiceStatus status);



/**
 * Protocol implemented by user delegate to receive notifications when new flash
 * devices are discoved in range or are connected.
 */
@protocol NVFlashServiceDelegate<NSObject>

@optional

/**
 * A new flash device device detected.
 *
 * Clients can use key-value-observing on the flash instances to observe changes in state.
 */
- (void) flashServiceAddedFlash:(id<NVFlash>) flash;

/**
 * Flash device no longer available.
 *
 * After this is called the client should release any references it has to the instance 
 * of the flash, remove it from the user interface and not call/read any of its
 * properties/methods.
 *
 * When `disable` is called, all flash instances will be removed.
 */
- (void) flashServiceRemovedFlash:(id<NVFlash>) flash;

/**
 * A flash has been connected.
 *
 * Clients can use key-value-observing on the flash instances to observe changes in state.
 */
- (void) flashServiceConnectedFlash:(id<NVFlash>) flash;

/**
 * A flash has been disconnected.
 *
 * Clients can use key-value-observing on the flash instances to observe changes in state.
 */
- (void) flashServiceDisconnectedFlash:(id<NVFlash>) flash;

@end



@interface NVFlashService : NSObject <CBCentralManagerDelegate>

@property (nonatomic, weak) id<NVFlashServiceDelegate> delegate;

@property (nonatomic, readonly) NVFlashServiceStatus status;

/**
 * Enable Bluetooth flash service and begin scanning for nearby flashes.
 */
- (void) enable;

/**
 * Disabled Bluetooth flash service, stop scanning for nearby flashes,
 * disconnect any that are connected and remove all flashes.
 */
- (void) disable;

/**
 * All flashes. This includes flashes that
 * may not be connected, or may no longer be in range.
 *
 * Array contains instances of id<NVFlash>.
 */
@property (nonatomic, readonly) NSArray *flashes;

/**
 * Contains all flashes that are currently connected.
 *
 * To be specific, any flash with status NVFlashReady or NVFlashBusy.
 *
 * Array contains instances of id<NVFlash>.
 */
@property (nonatomic, readonly) NSArray *connectedFlashes;

/**
 * Retrieve a flash with a given identifier.
 *
 * This identifier is the `identifier` property of a previously seen
 * NVFlash instance.
 *
 * This allows app to remember a previously seen flash and attempt to
 * retrieve it.
 *
 * If the flash has not been detected since the service was enabled,
 * nil will be returned.
 */
- (id<NVFlash>) flashWithIdentifier:(NSString*)identifier;

/**
 * Disconnect all connected devices.
 *
 * Note that if autoConnectMaxFlashes > 0, this may result in new
 * flashes being auto connected to shortly afterwards.
 */
- (void) disconnectAll;

#pragma mark - Auto connect

/**
 * Enable/disable auto connection. When enabled, the flash service
 * will automatically attempt to connect to flashes in range using
 * specified criteria.
 *
 * By default this is disabled.
 *
 * When enabled, the default criteria is to connect to the single closest
 * flash (based on signal strength), so long as the signal strength
 * is greater than 0.1 (10%).
 *
 * To connect to more than one flash, set `autoConnectMaxFlashes`.
 *
 * To connect to a specific flash (e.g. a previously seen flash) set
 * `autoConnectWhitelist`.
 *
 * Auto connection happens periodically after each scan. Once a flash is
 * auto connected to, it shall remain connected to until it becomes unavailable,
 * falls below the signal strength criteria, is explicitly disconnected,
 * or autoConnectMaxFlashes is decreased. After disconnection, the next
 * scan will attempt to reconnect to the new best candidates until
 * autoConnectMaxFlashes is met.
 */
@property (nonatomic) BOOL autoConnect;

/**
 * Auto connect behavior: Max number of flashes to auto connect.
 *
 * Only used when `autoConnect` is YES.
 *
 * When more candidate flashes are available those with stronger signal
 * strength shall be connected to first.
 *
 * To auto connect to just the closest flash, set to 1. This is the default.
 * Likewise, to auto connect to the closest N, set to N.
 * To connect to ALL available flashes, set this to a high number like MAX_UINT.
 */
@property (nonatomic) unsigned int autoConnectMaxFlashes;

/**
 * Auto connect behavior: Minimum signal strength required by flash in
 * order to trigger an auto connection. Defaults to 0.1 (10%).
 *
 * Only used when `autoConnect` is YES.
 */
@property (nonatomic) float autoConnectMinSignalStrength;

/**
 * Auto connect behavior: Explicitly define which flashes to auto connect to.
 *
 * Only used when `autoConnect` is YES.
 *
 * This allows apps to implement behaviour to remember previously connected
 * flashes and easily reconnect.
 *
 * The array should contain NSString's of the NVFlash.identifier.
 *
 * An empty array means no white list is used (effectively any flash will be allowed).
 */
@property (nonatomic, retain) NSArray *autoConnectWhitelist;

/**
 * Auto connect behavior: Never attempt to connect to any of these flashes.
 *
 * Only used when `autoConnect` is YES.
 *
 * The array should contain NSString's of the NVFlash.identifier.
 */
@property (nonatomic, retain) NSArray *autoConnectBlacklist;

@end


// Internal use only.
@protocol NVBluetoothFlash<NVFlash>
- (void) setRssi:(NSNumber *)rssi;
- (void) discoverServices;
@end