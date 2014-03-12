//
//  SSViewController.h
//  NovaSDKTestApp
//
//  Created by Joe Walnes on 2/8/14.
//  Copyright (c) 2014 Sneaky Squid. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../../NovaSDK/NVFlashService.h"

@interface SSViewController : UIViewController
{
    IBOutlet UISegmentedControl *pairMode;
    IBOutlet UIButton *refresh;

    IBOutlet UIButton *enable;
    IBOutlet UIButton *disable;
    IBOutlet UILabel *status;

    IBOutlet UISegmentedControl *flashPresets;
    IBOutlet UILabel *warmValue;
    IBOutlet UILabel *coolValue;
    IBOutlet UISlider *warmSlider;
    IBOutlet UISlider *coolSlider;
    
    IBOutlet UIButton *flash;

    IBOutlet UITextView *log;
    
    NVFlashService *flashService;
    NVFlashSettings *flashSettings;
}

- (void)appSleep;
- (void)appWake;
@end
