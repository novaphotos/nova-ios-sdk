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

typedef NS_ENUM(NSInteger, NVFlashServiceStatus)
{
    /**
     * BluetoothLE is not available on this device. This could be because the device does
     * not support it, or the user has not enabled it in their settings.
     */
    NVFlashServiceDisabled,
    
    /**
     * No devices are connected and nothing is being scanned for.
     */
    NVFlashServiceDisconnected,
    
    /**
     * No devices are connected, but we're currently scanning for some.
     */
    NVFlashServiceScanning,
    
    /**
     * Device(s) found and attempting to establish a connection.
     */
    NVFlashServiceConnecting,
    
    /**
     * BluetoothLE connection to device has been established. Performing final handshake.
     */
    NVFlashServiceHandshaking,
    
    /**
     * Connection to device is ready and waiting for flashes. Yay.
     */
    NVFlashServiceReady,
    
    /**
     * Connection to device is established, but the device is currently busy
     * (most likely performing a flash).
     */
    NVFlashServiceBusy
};