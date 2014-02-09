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

#import "NVFlashService.h"

@interface NVFlashService()
@property NVFlashServiceStatus status; // Override interface declaration so we can change the value.
@end

@implementation NVFlashService


static NSString* const kServiceUUID = @"FFF0";
static NSString* const kRequestCharacteristicUUID = @"FFF3";
static NSString* const kResponseCharacteristicUUID = @"FFF4";

static NSTimeInterval const scanInterval = 1; // How long between scans, in seconds.
static NSTimeInterval const scanDuration = 0.5; // How long to scan for, in seconds.


#pragma mark Initialization

- (id) init
{
    self = [super init];
    if (self) {
        enabled = NO;
        central = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        
        statusCallback = ^ (NVFlashServiceStatus status) {};        
        [self addObserver:self
               forKeyPath:NSStringFromSelector(@selector(status))
                  options:0
                  context:NULL];
    }
    return self;
}

// Callback from [CBCentralManager initWithDelegate:queue:]
// Tells us whether we have access to the Bluetooth stack (i.e. running on a suitable device).
- (void)centralManagerDidUpdateState:(CBCentralManager *)cm
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        if (enabled) {
            [self startScan];
        }
    } else {
        self.status = NVFlashServiceDisabled;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == self && [keyPath isEqualToString:NSStringFromSelector(@selector(status))]) {
        statusCallback(self.status);
    }
}

- (void) observeStatus:(NVFlashServiceStatusCallback)callback
{
    statusCallback = callback;
}

#pragma mark NFFlashService lifecycle implementation

- (void) enable
{
    if (enabled) {
        return;
    }
    
    enabled = YES;
    
    [startScanTimer invalidate];
    [stopScanTimer invalidate];
    stopScanTimer = nil;
    
    self.status = NVFlashServiceIdle;
    
    startScanTimer = [NSTimer scheduledTimerWithTimeInterval:scanInterval
                                                      target:self
                                                    selector:@selector(startScan)
                                                    userInfo:nil
                                                     repeats:YES];
    [self startScan];
}

- (void) disable
{
    if (!enabled) {
        return;
    }
    
    enabled = NO;
    [central stopScan];
    
    [startScanTimer invalidate];
    [stopScanTimer invalidate];
    startScanTimer = nil;
    stopScanTimer = nil;

    [self disconnect];

    // TODO: Abort commands in progress
    self.status = NVFlashServiceDisabled;
}

- (void) refresh
{
    if (enabled) {
        [self disable];
        [self enable];
    }
}


#pragma mark Scan for devices in range.

// Periodically called by timer.
- (void)startScan
{
    if (stopScanTimer != nil) {
        return; // Scan is already in progress.
    }
    
    if (central.state != CBCentralManagerStatePoweredOn) {
        return; // Bluetooth stack is not ready yet. Try again later.
    }
    
    if (self.status != NVFlashServiceIdle) {
        return; // Either BT is disabled, or we're already attempting to connect.
    }

    strongestSignalPeripheral = nil;
    strongestSignalRSSI = nil;

    // Calls [self centralManager:didDiscoverPeripheral:advertisementData:RSSI:] when peripheral discovered.
    [central scanForPeripheralsWithServices: @[[CBUUID UUIDWithString:kServiceUUID]] options: nil];

    self.status = NVFlashServiceScanning;
    
    // Stop scanning after scanDuration.
    stopScanTimer = [NSTimer scheduledTimerWithTimeInterval:scanDuration
                                                     target:self
                                                   selector:@selector(stopScan)
                                                   userInfo:nil
                                                    repeats:NO];
}

// Callback from [CBCentralManager scanForPeripheralsWithServices:options:]
// Tells us that a peripheral that supports our service was discovered.
- (void) centralManager:(CBCentralManager *)cm
  didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary *)advertisementData
                   RSSI:(NSNumber *)rssi
{
    NSString *name = peripheral.name;
    
    BOOL isNova = ([name isEqual:@"Nova"] || [name isEqual:@"Noon"] || [name isEqual:@"S-Power"]);
    
    if (!isNova) {
        return;
    }
    
    // TODO: Support pairing to multiple devices.

    // If this device has a stronger signal than previously scanned devices, it's our best bet.
    if (strongestSignalPeripheral == nil || rssi > strongestSignalRSSI) {
        strongestSignalPeripheral = peripheral;
        strongestSignalRSSI = rssi;
    }
}

// Periodicaly called by timer, sometime after startScan.
- (void)stopScan
{
    [central stopScan];
    [stopScanTimer invalidate];
    stopScanTimer = nil;
    
    CBPeripheral* peripheral = strongestSignalPeripheral;
    strongestSignalPeripheral = nil;
    strongestSignalRSSI = nil;
    
    if (peripheral == nil) {
        self.status = NVFlashServiceIdle;
    } else {
        [self connect:peripheral];
    }
}


#pragma mark Establish connection to device


- (void)connect:(CBPeripheral *)peripheral
{
    // Connects to the discovered peripheral.
    // Calls [self centralManager:didFailToConnectPeripheral:error:]
    // or [self centralManager:didConnectPeripheral:]
    peripheral.delegate = self;
    [central connectPeripheral:peripheral options:nil];
    
    // Hang on to it so it isn't cleaned up.
    activePeripheral = peripheral;
    
    self.status = NVFlashServiceConnecting;
}

// Callback from [CBCentralManager connectPeripheral:options:]
// Failed to connect.
- (void)    centralManager:(CBCentralManager *)cm
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                     error:(NSError *)error
{
    if (activePeripheral != peripheral) {
        return;
    }

    [self disconnect];
}

// Callback from [CBCentralManager connectPeripheral:options:]
// Yay! Connected to peripheral.
- (void) centralManager:(CBCentralManager *)cm
   didConnectPeripheral:(CBPeripheral *)peripheral
{
    if (activePeripheral != peripheral) {
        return;
    }

    // Asks the peripheral to discover the service
    // Calls [self peripheral:didDiscoverServices:]
    [peripheral discoverServices:@[ [CBUUID UUIDWithString:kServiceUUID] ]];
}

- (void) centralManager:(CBCentralManager *)cm
didDisconnectPeripheral:(CBPeripheral *)peripheral
                  error:(NSError *)error
{
    if (activePeripheral != peripheral) {
        return;
    }
    
    [self disconnect];
}

// Callback from [CBPeripheral discoverServices:]
- (void) peripheral:(CBPeripheral *)peripheral
didDiscoverServices:(NSError *)error
{
    if (activePeripheral != peripheral) {
        return;
    }

    if (error) {
        [self disconnect];
        return;
    }
    
    for (CBService* service in peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]]) {
            // Found our service
            // Discovers the characteristics for the service
            // Calls [self peripheral:didDiscoverCharacteristicsForService:error:]
            NSArray *characteristics = @[[CBUUID UUIDWithString:kRequestCharacteristicUUID],
                                         [CBUUID UUIDWithString:kResponseCharacteristicUUID]];
            [peripheral discoverCharacteristics:characteristics forService:service];
            return;
        }
    }
    
    [self disconnect];
}

// Callback from [CBPeripheral discoverCharacteristics:forService]
- (void)                  peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
                               error:(NSError *)error
{
    if (activePeripheral != peripheral || ![service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]]) {
        return;
    }

    if (error) {
        [self disconnect];
        return;
    }
    
    for (CBCharacteristic* characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kRequestCharacteristicUUID]]) {
            requestCharacteristic = characteristic;
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kResponseCharacteristicUUID]]) {
            responseCharacteristic = characteristic;
        }
    }

    if (requestCharacteristic != nil && responseCharacteristic != nil) {
        // All set. We're now ready to send commands to the device.
        self.status = NVFlashServiceReady;
    } else {
        // Characteristics not found. Abort.
        [self disconnect];
    }
}

- (void) disconnect
{
    if (activePeripheral != nil) {
        [central cancelPeripheralConnection:activePeripheral];
    }
    
    activePeripheral = nil;
    requestCharacteristic = nil;
    responseCharacteristic = nil;

    self.status = NVFlashServiceIdle;
}

#pragma mark NVTriggerFlash flash control implementation

- (void) beginFlash:(NVFlashSettings*)settings
{
    [self beginFlash:settings withCallback:^(BOOL success) {}];
}

- (void) beginFlash:(NVFlashSettings*)settings withCallback:(NVTriggerCallback)callback
{
    if (self.status != NVFlashServiceReady) {
        callback(NO);
        return;
    }
    
    char packet[] = {
        'F',
        '!',
        settings.warm,
        settings.cool,
        (char)settings.timeout, // low byte
        (char)settings.timeout >> 8, // high byte
        0
    };
    
    NSData* payload = [NSData dataWithBytes:(const char*)&packet length:sizeof(packet)];
    [activePeripheral writeValue:payload
               forCharacteristic:requestCharacteristic
                            type:CBCharacteristicWriteWithResponse];
    
    // TODO: Update Nova firmware with new protocol.
    callback(YES);
}

- (void) endFlash
{
    [self endFlashWithCallback:^(BOOL success) {}];
}

- (void) endFlashWithCallback:(NVTriggerCallback)callback
{
    if (self.status != NVFlashServiceReady) {
        callback(NO);
        return;
    }
    
    // TODO: Nova is currently running old firmware - this is no-op. Update Nova firmware and implement this.
    callback(YES);
}


@end
