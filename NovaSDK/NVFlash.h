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
#import "NVFlashSettings.h"



/** 
 * Enum to represent current status of a specific flash device.
 */
typedef NS_ENUM(NSInteger, NVFlashStatus)
{
    /**
     * Flash detected in range, and available to connect to.
     */
    NVFlashAvailable,

    /**
     * Flash that was previously in range is no longer available.
     * It may be out of range or run out of battery charge.
     */
    NVFlashUnavailable,

    /**
     * Flash is in the process of being connected to.
     */
    NVFlashConnecting,
    
    /**
     * Flash connected and ready for action.
     */
    NVFlashReady,
    
    /**
     * Flash is connected and currently processing a command.
     * It may not respond until the existing command has completed.
     * This state typically lasts 100-200ms.
     */
    NVFlashBusy

};



/**
 * Convenience function to convert NFFlashStatus into string (e.g. "Connecting").
 * These strings are not localized and are meant primarily for debug logging.
 */
NSString *NVFlashStatusString(NVFlashStatus status);



/**
 * User defined callback block that will be triggered when a flash command completes.
 * The BOOL indicates whether the command was successful.
 */
typedef void (^NVTriggerCallback)(BOOL);



/**
 * Flash protocol. An instance of this is assigned to each physical flash device 
 * in the vicinity. This allows individual control of each flash.
 *
 * All properties are key-value-observable.
 */
@protocol NVFlash <NSObject>

/**
 * A unique string assigned to each flash. This is a long UUID-like string, that
 * may not be understandable by humans, but can be used as a key in apps to identify
 * the device.
 *
 * The unique string is consistent across multiple apps on the same iOS phone, however
 * the string will vary across multiple phones. This is a privacy feature of CoreBluetooth.
 *
 * Once an NVFlash is instantiated, the identifier will never change.
 */
@property (nonatomic, readonly) NSString* identifier;

/**
 * Status of flash. See NVFlashStatus.
 *
 * Key-value-observable.
 */
@property (nonatomic, readonly) NVFlashStatus status;

/**
 * Signal strength of flash. Range from 0.0 (weakest) to 1.0 (strongest).
 *
 * This can be used to display an indicator, and also to estimate which flashes are closer
 * or further away from the iOS phone.
 *
 * Key-value-observable.
 */
@property (nonatomic, readonly) float signalStrength;

/**
 * Is the flash currently lit?
 *
 * Note that this is best-guess optimistic estimate. The flash can take up to 300ms to acknowledge
 * the response, and this bool will be set before the result is known. Use it for displaying feedback 
 * user interface feedback and to prevent additional flashes before the last has completed.
 * However, it should not be used to time the camera (see beginFlash:withCallback: for that).
 *
 * Key-value-observable.
 */
@property (nonatomic, readonly) BOOL lit;

/**
 * Connect to the flash (if not already connected).
 *
 * Observe status property to monitor result.
 */
- (void) connect;

/**
 * Disconnect from the flash (if connected).
 *
 * Observe status property to monitor result.
 */
- (void) disconnect;

/**
 * Begins the flash (turns the light on). The brightness, color temperature and 
 * timeout are passed as NVFlashSettings.
 *
 * The callback signals that the flash is on. It is the time to actually take
 * a photo. The callback is also passed a success bool which should be checked
 * to confirm that the flash actually began successfully.
 *
 * To turn the flash off, call endFlash or endFlashWithCallback:.
 *
 * Timeout (a property of NVFlashSettings) is a safety mechanism to ensure the
 * flash eventually turns itself off in the event endFlash is not called (e.g.
 * if the app hangs).
 */
- (void) beginFlash:(NVFlashSettings*)settings withCallback:(NVTriggerCallback)callback;

/**
 * See beginFlash:withCallback:. Convience method with no-op callback.
 */
- (void) beginFlash:(NVFlashSettings*)settings;

/**
 * Ends the flash (turns the light off). See beginFlash:withCallback:.
 */
- (void) endFlashWithCallback:(NVTriggerCallback)callback;

/**
 * See endFlashWithCallback:. Convience method with no-op callback.
 */
- (void) endFlash;

/**
 * Pings the flash. Sends a roundtrip no-op message. Can be used to verify flash
 * is working and measure roundtrip communication time.
 */
- (void) pingWithCallback:(NVTriggerCallback)callback;

// Include key-value-observer methods in NVFlash protocol for convenience.

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context;
- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void *)context;
- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;

@end