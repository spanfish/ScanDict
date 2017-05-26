//
//  SDPreviewView.m
//  ScanDict
//
//  Created by xiangwei wang on 2017/05/26.
//  Copyright © 2017 xiangwei wang. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <ReactiveObjC/ReactiveObjC.h>

#import "SDPreviewView.h"

typedef NS_ENUM(NSUInteger, ControlCorner) {
    ControlCornerNone = 0,
    ControlCornerTopLeft,
    ControlCornerTopRight,
    ControlCornerBottomLeft,
    ControlCornerBottomRight
};

typedef struct ControlCornerPoint {
    ControlCorner corner;
    CGPoint point;
} ControlCornerPoint;

@interface SDPreviewView() {
    CAShapeLayer *maskLayer;
    CAShapeLayer *regionOfInterestOutline;
    CAShapeLayer *topLeftControl;
    CAShapeLayer *topRightControl;
    CAShapeLayer *bottomLeftControl;
    CAShapeLayer *bottomRightControl;
    
    /**
     This property is set only in `setRegionOfInterestWithProposedRegionOfInterest()`.
     When a user is resizing the region of interest in `resizeRegionOfInterestWithGestureRecognizer()`,
     the KVO notification will be triggered when the resizing is finished.
     */
    CGRect regionOfInterest;
    
    CGFloat regionOfInterestControlDiameter;
    
    CGFloat regionOfInterestControlRadius;
    
    ControlCorner currentControlCorner;
    
    UIPanGestureRecognizer *resizeRegionOfInterestGestureRecognizer;
    
    AVCaptureVideoPreviewLayer *videoPreviewLayer;
    
    AVCaptureSession *session;
}
@end

@implementation SDPreviewView

-(instancetype) init {
    self = [super init];
    if(self) {
        [self commonInit];
    }
    return self;
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if(self) {
        [self commonInit];
    }
    return self;
}

-(instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame: frame];
    if(self) {
        [self commonInit];
    }
    return self;
}

+(Class) layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

-(void) commonInit {
#if DEBUG
    regionOfInterest = CGRectMake((self.bounds.size.width - 150)/2, (self.bounds.size.height - 150)/2, 150, 50);
#endif
    currentControlCorner = ControlCornerNone;
    regionOfInterestControlDiameter = 12;
    regionOfInterestControlRadius = regionOfInterestControlDiameter / 2;
    
    maskLayer = [CAShapeLayer layer];
    topLeftControl = [CAShapeLayer layer];
    topRightControl = [CAShapeLayer layer];
    bottomLeftControl = [CAShapeLayer layer];
    bottomRightControl = [CAShapeLayer layer];
    regionOfInterestOutline = [CAShapeLayer layer];
    
    maskLayer.fillRule = kCAFillRuleEvenOdd;
    maskLayer.fillColor = [UIColor blackColor].CGColor;
    maskLayer.opacity = 0.6;
    
    [self.layer addSublayer:maskLayer];
    
    topLeftControl.path = [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, regionOfInterestControlDiameter, regionOfInterestControlDiameter)] CGPath];
    topLeftControl.fillColor = [[UIColor whiteColor] CGColor];
    [self.layer addSublayer:topLeftControl];
    
    topRightControl.path = [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, regionOfInterestControlDiameter, regionOfInterestControlDiameter)] CGPath];
    topRightControl.fillColor = [[UIColor whiteColor] CGColor];
    [self.layer addSublayer:topRightControl];
    
    bottomLeftControl.path = [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, regionOfInterestControlDiameter, regionOfInterestControlDiameter)] CGPath];
    bottomLeftControl.fillColor = [[UIColor whiteColor] CGColor];
    [self.layer addSublayer:bottomLeftControl];
    
    bottomRightControl.path = [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, regionOfInterestControlDiameter, regionOfInterestControlDiameter)] CGPath];
    bottomRightControl.fillColor = [[UIColor whiteColor] CGColor];
    [self.layer addSublayer:bottomRightControl];
    
    regionOfInterestOutline.path = [[UIBezierPath bezierPathWithRect:regionOfInterest] CGPath];
    regionOfInterestOutline.fillColor = [[UIColor clearColor] CGColor];
    regionOfInterestOutline.strokeColor = [[UIColor yellowColor] CGColor];
    [self.layer addSublayer:regionOfInterestOutline];

    resizeRegionOfInterestGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(resizeRegionOfInterestWithGestureRecognizer:)];
    [self addGestureRecognizer:resizeRegionOfInterestGestureRecognizer];
}

-(void) layoutSubviews {
    [super layoutSubviews];
    
    // Disable CoreAnimation actions so that the positions of the sublayers immediately move to their new position.
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    // Create the path for the mask layer. We use the even odd fill rule so that the region of interest does not have a fill color.
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    [path appendPath:[UIBezierPath bezierPathWithRect:regionOfInterest]];
    path.usesEvenOddFillRule = TRUE;
    maskLayer.path = [path CGPath];
    
    regionOfInterestOutline.path = [[UIBezierPath bezierPathWithRect:regionOfInterest] CGPath];
    
    topLeftControl.position = CGPointMake(regionOfInterest.origin.x - regionOfInterestControlRadius, regionOfInterest.origin.y - regionOfInterestControlRadius);
    
    topRightControl.position = CGPointMake(regionOfInterest.origin.x + regionOfInterest.size.width - regionOfInterestControlRadius, regionOfInterest.origin.y - regionOfInterestControlRadius);
    
    bottomLeftControl.position = CGPointMake(regionOfInterest.origin.x - regionOfInterestControlRadius, regionOfInterest.origin.y + regionOfInterest.size.height - regionOfInterestControlRadius);
    
    bottomRightControl.position = CGPointMake(regionOfInterest.origin.x + regionOfInterest.size.width - regionOfInterestControlRadius, regionOfInterest.origin.y + regionOfInterest.size.height - regionOfInterestControlRadius);

    [CATransaction commit];
}

-(void) resizeRegionOfInterestWithGestureRecognizer:(UIPanGestureRecognizer *) recognizer {
    CGPoint touchLocation = [recognizer locationInView:recognizer.view];
    
    CGRect oldRegionOfInterest = regionOfInterest;
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            /*
             When the gesture begins, save the corner that is closes to
             the resize region of interest gesture recognizer's touch location.
             */
            currentControlCorner = [self cornerOfRect:oldRegionOfInterest closestToPointWithinTouchThreshold: touchLocation];
            break;
        case UIGestureRecognizerStateChanged: {
            CGRect newRegionOfInterest = oldRegionOfInterest;
            switch (currentControlCorner) {
                case ControlCornerNone:
                    break;
                case ControlCornerTopLeft:
                    newRegionOfInterest = CGRectMake(touchLocation.x, touchLocation.y, oldRegionOfInterest.size.width + oldRegionOfInterest.origin.x - touchLocation.x, oldRegionOfInterest.size.height + oldRegionOfInterest.origin.y - touchLocation.y);
                    break;
                case ControlCornerTopRight:
                    newRegionOfInterest = CGRectMake(newRegionOfInterest.origin.x, touchLocation.y, touchLocation.x - newRegionOfInterest.origin.x, oldRegionOfInterest.size.height + newRegionOfInterest.origin.y - touchLocation.y);
                    break;
                case ControlCornerBottomLeft:
                    newRegionOfInterest = CGRectMake(touchLocation.x, oldRegionOfInterest.origin.y, oldRegionOfInterest.size.width + oldRegionOfInterest.origin.x - touchLocation.x, touchLocation.y - oldRegionOfInterest.origin.y);
                    break;
                case ControlCornerBottomRight:
                    newRegionOfInterest = CGRectMake(oldRegionOfInterest.origin.x, oldRegionOfInterest.origin.y, touchLocation.x - oldRegionOfInterest.origin.x, touchLocation.y - oldRegionOfInterest.origin.y);
                    break;
                default:
                    break;
            }
            [self setRegionOfInterestWithProposedRegionOfInterest: newRegionOfInterest];
        }
            break;
        case UIGestureRecognizerStateEnded:
            currentControlCorner = ControlCornerNone;
            break;
        default:
            break;
    }
}

-(void) setRegionOfInterestWithProposedRegionOfInterest:(CGRect) proposedRegionOfInterest {
    regionOfInterest = proposedRegionOfInterest;
    [self setNeedsLayout];
}

-(ControlCorner) cornerOfRect:(CGRect) rect closestToPointWithinTouchThreshold:(CGPoint) point {
    CGFloat closestDistance = FLT_MAX;
    ControlCorner closestCorner = ControlCornerNone;
    ControlCornerPoint corners[] = {
        {ControlCornerTopLeft, rect.origin},
        {ControlCornerTopRight, CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect))},
        {ControlCornerBottomLeft, CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect))},
        {ControlCornerBottomRight, CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect))}
    };
    
    ControlCornerPoint *corner = corners;
    for(int i = 0; i < 4; i++,corner++) {
        CGFloat dx = point.x - corner->point.x;
        CGFloat dy = point.y - corner->point.y;
        CGFloat distance = sqrt(dx * dx + dy * dy);
        if(distance < closestDistance) {
            closestDistance = distance;
            closestCorner = corner->corner;
        }
        
    }
    return closestCorner;
}
@end
