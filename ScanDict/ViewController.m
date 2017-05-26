//
//  ViewController.m
//  ScanDict
//
//  Created by xiangwei wang on 2017/05/25.
//  Copyright © 2017 xiangwei wang. All rights reserved.
//

#import "ViewController.h"
#import "SDPreviewView.h"

@import AVFoundation;

//https://github.com/tesseract-ocr/tessdata/tree/bf82613055ebc6e63d9e3b438a5c234bfd638c93
@interface ViewController ()

@property(nonatomic, weak) IBOutlet SDPreviewView *previewView;
@property(nonatomic) AVCaptureSession *session;
@property (nonatomic) dispatch_queue_t sessionQueue;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng+jpn"];
    tesseract.delegate = self;
    
    //tesseract.charWhitelist
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        tesseract.image = [UIImage imageNamed:@"sample-en.png"];
        
        //limit the area of the image Tesseract should recognize
        //tesseract.rect =
        //limit recognition time with a few seconds
        //tesseract.maximumRecognitionTime =
        //start recognition
        NSLog(@"%f", [NSDate timeIntervalSinceReferenceDate]);
        [tesseract recognize];
        NSLog(@"%f", [NSDate timeIntervalSinceReferenceDate]);
        //retrieve text
        NSLog(@"%@", [tesseract recognizedText]);
    });
    
    // Create the AVCaptureSession
    self.session = [[AVCaptureSession alloc] init];
    // Set up the preview view
    self.previewView.session = self.session;
    // Communicate with the session and other session objects on this queue
    self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    
    // Check video authorization status. Video access is required and audio access is optional.
    // If audio access is denied, audio is not recorded during movie recording.
    switch([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized:
            // The user has previously granted access to the camera
            break;
        case AVAuthorizationStatusNotDetermined: {
            // The user has not yet been presented with the option to grant video access.
            // We suspend the session queue to delay session running until the access request has completed.
            // Note that audio access will be implicitly requested when we create an AVCaptureDeviceInput for audio during session setup.
            dispatch_suspend(self.sessionQueue);
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if(!granted) {
                    
                }
                dispatch_resume(self.sessionQueue);
            }];
        }
            break;
        default:
            break;
    }
    
    // Setup the capture session.
    // Setup the capture session.
    // In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
    // Why not do all of this on the main queue?
    // Because -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue
    // so that the main queue isn't blocked, which keeps the UI responsive.
    dispatch_async(self.sessionQueue, ^{
        [self configureSession];
    } );
}

// Should be called on the session queue
- (void)configureSession{
    NSError *error = nil;
    
    [self.session beginConfiguration];
    self.session.sessionPreset = AVCaptureSessionPresetHigh;
    // Add video input
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if(!videoDeviceInput) {
        return;
    }
    
    if([self.session canAddInput:videoDeviceInput]) {
        [self.session addInput:videoDeviceInput];
    }
    
    [self.session commitConfiguration];
    [self.session startRunning];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - G8TesseractDelegate
/**
 *  An optional method to be called periodically during recognition so
 *  the recognition's progress can be observed.
 *
 *  @param tesseract The `G8Tesseract` object performing the recognition.
 */
- (void)progressImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    
}

/**
 *  An optional method to be called periodically during recognition so
 *  the user can choose whether or not to cancel recognition.
 *
 *  @param tesseract The `G8Tesseract` object performing the recognition.
 *
 *  @return Whether or not to cancel the recognition in progress.
 */
- (BOOL)shouldCancelImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    return NO;
}

/**
 *  An optional method to provide image preprocessing. To perform default
 *  Tesseract preprocessing return `nil` in this method.
 *
 *  @param tesseract   The `G8Tesseract` object performing the recognition.
 *  @param sourceImage The source `UIImage` to perform preprocessing.
 *
 *  @return Preprocessed `UIImage` or nil to perform default preprocessing.
 */
- (UIImage *)preprocessedImageForTesseract:(G8Tesseract *)tesseract
                               sourceImage:(UIImage *)sourceImage {
    return nil;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection {
    
}
@end
