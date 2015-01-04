//
//  NVFlash.m
//  NovaSDK
//
//  Created by Joe Walnes on 1/1/15.
//  Copyright (c) 2015 Sneaky Squid. All rights reserved.
//

#import "NVFlash.h"

NSString *NVFlashStatusString(NVFlashStatus status)
{
    switch (status) {
        case NVFlashUnavailable:
            return @"Unavailable";
        case NVFlashAvailable:
            return @"Available";
        case NVFlashConnecting:
            return @"Connecting";
        case NVFlashReady:
            return @"Ready";
        case NVFlashBusy:
            return @"Busy";
    }
}
