//
//  ViewController.h
//  FaceDetectionPOC
//
//  Created by Jeroen Trappers on 30/04/12.
//  Copyright (c) 2012 iCapps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "Zombiefy2016-Swift.h"

@protocol CameraControlsProtocol
- (void)record;
- (void)switchCamera;
@end

@interface ViewController : UIViewController
    <UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, weak) IBOutlet UIView *previewView;
@property (nonatomic, weak) IBOutlet CameraControls *cameraControls;

@end
