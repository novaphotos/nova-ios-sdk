//  The MIT License (MIT)
//
//  Copyright (c) 2013 Joe Walnes, Sneaky Squid LLC.
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
#import "NVFlashServiceStatus.h"
#import "NVTriggerFlash.h"

typedef NS_ENUM(NSInteger, NVAutoPairMode)
{
    NVAutoPairNone,
    NVAutoPairClosest,
    NVAutoPairAll
};

// TODO: Count individual devices
// TODO: Simplify making this observable
@interface NVFlashService : NSObject <NVTriggerFlash, CBCentralManagerDelegate, CBPeripheralDelegate>
{
    BOOL enabled;
    CBCentralManager *central;
    CBPeripheral *strongestSignalPeripheral;
    CBPeripheral *activePeripheral;
    NSNumber *strongestSignalRSSI;
    NSTimer *startScanTimer;
    NSTimer *stopScanTimer;
}

@property (readonly) NVFlashServiceStatus status;

@property NVAutoPairMode autoPairMode;

/*!
 *  @method enable
 *
 *  @discussion					This will activate begin scanning and attempt to connect.
 *
 *  @see						disable
 */
- (void) enable;

/*!
 *  @method disable
 *
 *  @discussion					Disconnects (if connected) and stops scanning. Conserves battery life.
 *
 *  @see						enable
 */
- (void) disable;

/*!
 *  @method refresh
 *
 *  @discussion					Forgets any currently paired devices and performs a rescan.
 */
- (void) refresh;

@end
