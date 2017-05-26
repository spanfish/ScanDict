//
//  ViewController.h
//  ScanDict
//
//  Created by xiangwei wang on 2017/05/26.
//  Copyright © 2017 xiangwei wang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TesseractOCR/TesseractOCR.h>
#import <QuartzCore/QuartzCore.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController<G8TesseractDelegate, AVCaptureMetadataOutputObjectsDelegate>


@end

