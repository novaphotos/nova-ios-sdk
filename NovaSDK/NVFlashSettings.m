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

#import "NVFlashSettings.h"

double const NV_DEFAULT_FLASH_TIMEOUT = 500;

@interface NVFlashSettings()
@property uint8_t warm;
@property uint8_t cool;
@property uint16_t timeout;
@end

@implementation NVFlashSettings

- (id) initWithWarm:(uint8_t)warm cool:(uint8_t)cool timeout:(uint16_t)timeout;
{
    self = [super init];
    if (self) {
        self.warm = warm;
        self.cool = cool;
        self.timeout = timeout;
    }
    return self;
}

+ (NVFlashSettings *)off
{
    return [NVFlashSettings customWarm:0 cool:0 timeout: 0];
}

+ (NVFlashSettings *)gentle
{
    return [NVFlashSettings customWarm:127 cool:0];
}

+ (NVFlashSettings *)warm
{
    return [NVFlashSettings customWarm:255 cool:20];
}

+ (NVFlashSettings *)bright
{
    return [NVFlashSettings customWarm:255 cool:255];
}

+ (NVFlashSettings *)customWarm:(uint8_t)warm cool:(uint8_t)cool
{
    return [NVFlashSettings customWarm:warm cool:cool timeout:NV_DEFAULT_FLASH_TIMEOUT];
}

+ (NVFlashSettings *)customWarm:(uint8_t)warm cool:(uint8_t)cool timeout:(uint16_t)timeout
{
    return [[NVFlashSettings alloc] initWithWarm:warm cool:cool timeout:timeout];
}

@end