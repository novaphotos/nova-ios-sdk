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

#import "NVNovaV1Flash.h"

static NSTimeInterval const ackTimeout = 2; // How long before we give up waiting for ack from device, in seconds.
static NSTimeInterval const rssiInterval = 1; // How long between RSSI checks, in seconds.

NSString* const kNovaV1ServiceUUID = @"FFF0";

static NSString* const kDeviceInformationServiceUUID = @"180A";
static NSString* const kSystemIdCharacteristicUUID = @"2A23";
static NSString* const kRequestCharacteristicUUID = @"FFF3";
static NSString* const kResponseCharacteristicUUID = @"FFF4";

@implementation NVCommand
@end

@interface NVNovaV1Flash()
// Override interface declarations so we can change the value.
@property (nonatomic) NVFlashStatus status;
@property (nonatomic) float signalStrength;
@property (nonatomic) BOOL lit;
@end


@implementation NVNovaV1Flash
{
    CBPeripheral *activePeripheral;
    CBCentralManager *centralManager;
    CBCharacteristic *requestCharacteristic;
    CBCharacteristic *responseCharacteristic;
    NVCommand *awaitingAck;
    NSTimer *ackTimer;
    NSTimer *rssiTimer;
    NSTimer *flashTimeoutTimer;
    uint8_t nextRequestId;
    NSMutableArray *awaitingSend;
    NSString *_identifier;
}

- (id) initWithPeripheral:(CBPeripheral*)peripheral withCentralManager:(CBCentralManager*) cm
{
    self = [super init];
    if (self) {
        awaitingSend = [NSMutableArray array];
        activePeripheral = peripheral;
        activePeripheral.delegate = self;
        centralManager = cm;
        _identifier = peripheral.identifier.UUIDString;
        self.status = NVFlashAvailable;
        self.lit = NO;
    }
    return self;
}

- (NSString*) identifier
{
    return _identifier;
}

- (void) setRssi:(NSNumber *)rssi
{
    if (rssi.integerValue == RSSI_UNAVAILABLE) {
        self.signalStrength = 0;
        if (self.status != NVFlashUnavailable) {
            [self disconnect];
            self.status = NVFlashUnavailable;
        }
    } else {
        // Converts db rating into simpler 0.0 (weakest) to 1.0 (strongest) scale.
        // These numbers are fairly subjective and based trial and error and what 'feels right'.
        self.signalStrength = MAX(0.0, MIN(5.0, 9.0 + rssi.floatValue / 10.0)) / 5.0;
        if (self.status == NVFlashUnavailable) {
            self.status = NVFlashAvailable;
        }
    }
}

- (void) connect
{
    switch (self.status) { // defensive guard to ensure all status cases are covered
        case NVFlashConnecting:
        case NVFlashReady:
        case NVFlashBusy:
        case NVFlashUnavailable:
            return; // connect to possible at this time
        case NVFlashAvailable:
            ; // carry on with connection
    }
    
    self.status = NVFlashConnecting;
    
    // Connects to the discovered peripheral.
    // Calls [flash centralManager:didFailToConnectPeripheral:error:]
    // or [flash centralManager:didConnectPeripheral:]
    [centralManager connectPeripheral:activePeripheral options:nil];
}

- (void) discoverServices
{
    // Asks the peripheral to discover the service
    // Calls [self peripheral:didDiscoverServices:]
    NSArray *services = @[[CBUUID UUIDWithString:kNovaV1ServiceUUID]];
    [activePeripheral discoverServices:services];
}

- (void) disconnect
{
    switch (self.status) { // defensive guard to ensure all status cases are covered
        case NVFlashAvailable:
        case NVFlashUnavailable:
            return; // no bluetooth connection. nothing to do
        case NVFlashConnecting:
        case NVFlashReady:
        case NVFlashBusy:
            ; // carry on with disconnection
    }
    
    [centralManager cancelPeripheralConnection:activePeripheral];

    if (responseCharacteristic != nil) {
        [activePeripheral setNotifyValue:NO forCharacteristic:responseCharacteristic];
    }
    
    requestCharacteristic = nil;
    responseCharacteristic = nil;
    
    self.lit = NO;
    
    [ackTimer invalidate];
    ackTimer = nil;
    
    [rssiTimer invalidate];
    rssiTimer = nil;

    [flashTimeoutTimer invalidate];
    flashTimeoutTimer = nil;

    // Abort any queued requests.
    if (awaitingAck != nil) {
        awaitingAck.callback(NO);
        awaitingAck = nil;
    }
    for (NVCommand *cmd in awaitingSend) {
        cmd.callback(NO);
    }
    [awaitingSend removeAllObjects];
    
    self.status = self.signalStrength == 0 ? NVFlashUnavailable : NVFlashAvailable;
    self.signalStrength = 0;
}

- (void) beginFlash:(NVFlashSettings*)settings
{
    [self beginFlash:settings withCallback:^(BOOL success) {}];
}

- (void) beginFlash:(NVFlashSettings*)settings withCallback:(NVTriggerCallback)callback
{
    [flashTimeoutTimer invalidate];
    flashTimeoutTimer = nil;

    if ((settings.warm == 0 && settings.cool == 0) || settings.timeout == 0) {
        // settings say that flash is effectively off
        self.lit = NO;
        [self request:offCmd() withCallback:callback];
    } else {
        self.lit = YES;
        [self request:lightCmd(settings.warm, settings.cool, settings.timeout) withCallback:^(BOOL success) {
            if (success) {
                double timeout = (double)settings.timeout / 1000.0;
                flashTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:timeout
                                                            target:self
                                                          selector:@selector(flashTimeout)
                                                          userInfo:nil
                                                           repeats:NO];
            } else {
                self.lit = NO;
            }
            callback(success);
        }];
    }
}

- (void) endFlash
{
    [self endFlashWithCallback:^(BOOL success) {}];
}

- (void) endFlashWithCallback:(NVTriggerCallback)callback
{
    [flashTimeoutTimer invalidate];
    flashTimeoutTimer = nil;

    self.lit = NO;
    [self request:offCmd() withCallback:callback];
}

- (void) pingWithCallback:(NVTriggerCallback)callback
{
    [self request:pingCmd() withCallback:callback];
}


- (void)flashTimeout
{
    [flashTimeoutTimer invalidate];
    flashTimeoutTimer = nil;
    self.lit = NO;
}

#pragma mark -

// Callback from [CBPeripheral discoverServices:]
- (void) peripheral:(CBPeripheral *)peripheral
didDiscoverServices:(NSError *)error
{
    if (error) {
        [self disconnect];
        return;
    }
    
    rssiTimer = [NSTimer scheduledTimerWithTimeInterval: rssiInterval
                                                 target: self
                                               selector: @selector(checkRssi)
                                               userInfo: nil
                                                repeats: YES];
   
    for (CBService* service in peripheral.services) {
        if ([service.UUID.UUIDString isEqualToString:kNovaV1ServiceUUID]) {
            // Found Nova service
            // Discovers the characteristics for the service
            // Calls [self peripheral:didDiscoverCharacteristicsForService:error:]
            NSArray *characteristics = @[[CBUUID UUIDWithString:kRequestCharacteristicUUID],
                                         [CBUUID UUIDWithString:kResponseCharacteristicUUID]];
            [peripheral discoverCharacteristics:characteristics forService:service];
        }
        if ([service.UUID.UUIDString isEqualToString:kDeviceInformationServiceUUID]) {
            // Found device information service
            // Discovers the characteristics for the service
            // Calls [self peripheral:didDiscoverCharacteristicsForService:error:]
            NSArray *characteristics = @[[CBUUID UUIDWithString:kSystemIdCharacteristicUUID]];
            [peripheral discoverCharacteristics:characteristics forService:service];
        }
    }
}

// Callback from [CBPeripheral discoverCharacteristics:forService]
- (void)                  peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
                               error:(NSError *)error
{
    if (![service.UUID.UUIDString isEqualToString:kNovaV1ServiceUUID]
        && ![service.UUID.UUIDString isEqualToString:kDeviceInformationServiceUUID]) {
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
            // Subscribe to notifications
            [peripheral setNotifyValue:YES forCharacteristic:responseCharacteristic];
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kSystemIdCharacteristicUUID]]) {
            [peripheral readValueForCharacteristic:characteristic];
        }
    }
    
    if (requestCharacteristic != nil && responseCharacteristic != nil) {
        // All set. We're now ready to send commands to the device.
        self.status = NVFlashReady;
    } else if ([service.UUID.UUIDString isEqualToString:kNovaV1ServiceUUID]) {
        // Characteristics not found in NovaV1 service. Abort.
        [self disconnect];
    }
}

- (void)             peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
                          error:(NSError *)error
{
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kResponseCharacteristicUUID]]) {
        [self handleResponse:characteristic.value];
    } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kSystemIdCharacteristicUUID]]) {
        // TODO: systemId
        // NSLog(@"systemID %@", characteristic.value);
    }
}

- (void) handleResponse:(NSData*)data
{
    NSString* response = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    //NSLog(@"<-- %@", response);
    
    uint8_t responseId;
    if (!parseAck(response, &responseId)) {
        //NSLog(@"Failed to parse response: %@", response);
        [self disconnect];
        return;
    }
    
    if (awaitingAck == nil) {
        //NSLog(@"Was not expecting ack (got: %u)", responseId);
        [self disconnect];
        return;
    }
    
    if (awaitingAck.requestId != responseId) {
        //NSLog(@"Unexpected ack (got: %u, expected: %u)", responseId, awaitingAck.requestId);
        [self disconnect];
        return;
    }
    
    //NSLog(@"<-- %@ [ACK]", frameMsg(awaitingAck.requestId, awaitingAck.msg));
    
    NVTriggerCallback callback = awaitingAck.callback;
    
    // No longer awaiting the ack.
    awaitingAck = nil;
    
    // Cancel timeout timer.
    [ackTimer invalidate];
    ackTimer = nil;
    
    self.status = NVFlashReady;

    // Send any queued outbound messages.
    [self processSendQueue];
    
    // Trigger user callback.
    callback(YES);
}

#pragma mark - RSSI check

- (void) checkRssi
{
    switch (self.status) { // defensive guard to ensure all status cases are covered
        case NVFlashAvailable:
        case NVFlashUnavailable:
        case NVFlashConnecting:
            return;
        case NVFlashReady:
        case NVFlashBusy:
            ; // carry on with disconnection
    }
    [activePeripheral readRSSI];
}

- (void)peripheral:(CBPeripheral*)peripheral didReadRSSI:(NSNumber*)RSSI error:(NSError*)error
{
    // There appears to be bug in some versions of iOS where sometimes this callback just stops getting fired.
    // Only known workaround is to go into device settings, turn bluetooth off and on again.
    [self setRssi:RSSI];
}

#pragma mark - Protocol handling

- (void) request:(NSString*)msg withCallback:(NVTriggerCallback)callback
{
    switch (self.status) { // defensive guard to ensure all status cases are covered
        case NVFlashAvailable:
        case NVFlashUnavailable:
        case NVFlashConnecting:
            // not connected yet. fail.
            {
                dispatch_async(dispatch_get_main_queue(), ^{ callback(NO); });
            }
            return; // not connected yet
        case NVFlashReady:
        case NVFlashBusy:
            ; // carry on with disconnection
    }

    NVCommand* cmd = [NVCommand new];
    cmd.requestId = nextRequestId++; // When nextRequestId (uint8_t) hits 255 it'll naturally wrap around back to 0.
    cmd.msg = msg;
    cmd.callback = callback;

    [awaitingSend addObject:cmd];
    [self processSendQueue];
}

-(void) processSendQueue
{
    // If we're not waiting for anything to be acked, go ahead and send the next cmd in the outbound queue.
    if (awaitingAck == nil && awaitingSend.count > 0) {
        
        self.status = NVFlashBusy;
        
        // Shift first command from front of awaitingSend queue.
        NVCommand* cmd = [awaitingSend objectAtIndex:0];
        [awaitingSend removeObjectAtIndex:0];
        
        NSString* body = frameMsg(cmd.requestId, cmd.msg);
        //NSLog(@"--> %@", body);
        
        // Write to device.
        NSData *data = [body dataUsingEncoding:NSASCIIStringEncoding];
        [activePeripheral writeValue:data
                   forCharacteristic:requestCharacteristic
                                type:CBCharacteristicWriteWithResponse];
        
        // Now we're waiting for this.
        awaitingAck = cmd;
        
        // Set timer for acks so we don't hang forever waiting.
        ackTimer = [NSTimer scheduledTimerWithTimeInterval:ackTimeout
                                                    target:self
                                                  selector:@selector(ackTookTooLong)
                                                  userInfo:nil
                                                   repeats:NO];
    }
}

- (void)ackTookTooLong
{
    [ackTimer invalidate];
    ackTimer = nil;
    
    if (awaitingAck != nil) {
        //NSLog(@"Timeout waiting for %@ ack", frameMsg(awaitingAck.requestId, awaitingAck.msg));
        awaitingAck.callback(NO);
    }
    
    awaitingAck = nil;
    self.status = NVFlashReady;

    [self processSendQueue];
}

NSString* frameMsg(uint8_t requestId, NSString *body)
{
    // Requests are framed "(xx:yy)" where xx is 2 digit hex requestId and yy is body string.
    // e.g. "(00:P)"
    //      "(4A:L,00,FF,05DC)"
    return [NSString stringWithFormat:@"(%02X:%@)", requestId, body];
}

NSString *pingCmd()
{
    return @"P";
}

NSString* lightCmd(uint8_t warmPwm, uint8_t coolPwm, uint16_t timeoutMillis)
{
    // Light cmd is formatted "L,w,c,t" where w and c are warm/cool pwm duty cycles as 2 digit hex
    // and t is 4 digit hex timeout.
    // e.g. "L,00,FF,05DC" (means light with warm=0, cool=255, timeout=1500ms)
    return [NSString stringWithFormat:@"L,%02X,%02X,%04X", warmPwm, coolPwm, timeoutMillis];
}

NSString* offCmd()
{
    return @"O";
}

bool parseAck(NSString *fullmsg, uint8_t* resultId)
{
    // Parses "(xx:A)" packet where xx is hex value for resultId.
    
    NSError *regexError = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\(([0-9A-Za-z][0-9A-Za-z]):A\\)"
                                                                           options:0
                                                                             error:&regexError];
    
    NSRange range = NSMakeRange(0, [fullmsg length]);
    NSArray *matches = [regex matchesInString:fullmsg options:0 range:range];
    if (matches.count == 0) {
        *resultId = 0;
        return NO;
    }
    
    unsigned scanned;
    NSString *hex = [fullmsg substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:1]];
    [[NSScanner scannerWithString:hex] scanHexInt:(unsigned*)&scanned];
    
    *resultId = (uint8_t)scanned;
    return YES;
}

@end
