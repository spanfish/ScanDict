//
//  ViewController.m
//  ScanDict
//
//  Created by xiangwei wang on 2017/05/25.
//  Copyright © 2017 xiangwei wang. All rights reserved.
//

#import "ViewController.h"
#import "SDPreviewView.h"

//https://github.com/tesseract-ocr/tessdata/tree/bf82613055ebc6e63d9e3b438a5c234bfd638c93
@interface ViewController ()

@property(nonatomic, weak) IBOutlet SDPreviewView *previewView;
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
@end
