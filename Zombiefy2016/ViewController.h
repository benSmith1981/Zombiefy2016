#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

//To make objective classes access swift classes you need to include forward declaration here
@class CameraControls;

@protocol CameraControlsProtocol
- (void)record;
- (void)switchCamera;
@end

@interface ViewController : UIViewController
    <UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, weak) IBOutlet UIView *previewView;
@property (nonatomic, weak) IBOutlet CameraControls *cameraControls;
@property (nonatomic) AVCaptureDevicePosition *desiredPosition;

@end
