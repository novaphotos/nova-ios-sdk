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

extern uint16_t const NV_DEFAULT_FLASH_TIMEOUT;

@interface NVFlashSettings : NSObject

// Set intensity of warm LEDs. Any value from 0-255, where 0=off and 255=max.
@property (readonly) uint8_t warm;

// Set intensity of cool LEDs. Any value from 0-255, where 0=off and 255=max.
@property (readonly) uint8_t cool;

// Time (in milliseconds) between beginFlash and endFlash that the flash hardware will wait
// before automatically shutting off.
//
// This serves two purposes:
//
// 1. To act as a fallback mechanism in case the application crashes between beginning
//    the flash and ending it. This will ensure the flash eventually turns off and doesn't
//    waste too much battery power.
//
// 2. For very short flashes (say < 10ms), it is more effictive to begin a flash with a
//    timeout, than to explicitly end the flash. This should only be used for short flashes
//    as the timer on the hardware is not very accurate (it can drift +/- 20%).
@property (readonly) uint16_t timeout;

// Constructor. Better to use the static helper functions.
// e.g. [NVFlashSettings warm], [NVFlashSettings customWarm:123 cool:20], etc...
- (id) initWithWarm:(uint8_t)warm cool:(uint8_t)cool timeout:(uint16_t)timeout;

// Preset settings for flash 'off'. No flash will occur.
+ (NVFlashSettings *)off;

// Preset settings for 'gentle' flash.
// A slight warm light, ideal for closeup photos.
+ (NVFlashSettings *)gentle;

// Preset settings for 'warm' flash.
// A bright natural looking warm light, ideal for people portraits at night.
+ (NVFlashSettings *)warm;

// Preset settings for 'neutral' flash.
// For whiter light. No added warmth.
+ (NVFlashSettings *)neutral;

// Preset settings for 'bright' flash.
// The brightest mode, with all LEDs at full brightness.
+ (NVFlashSettings *)bright;

// Custom brightness settings. Warm and cool LEDs are each in range 0-255, where 0=off and 255=max.
+ (NVFlashSettings *)customWarm:(uint8_t)warm cool:(uint8_t)cool;

+ (NVFlashSettings *)customWarm:(uint8_t)warm cool:(uint8_t)cool timeout:(uint16_t)timeout;

@end