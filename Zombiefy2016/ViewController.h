#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

//To make objective classes access swift classes you need to include forward declaration here
@class CameraControls;

@protocol CameraControlsProtocol
- (void)record;
- (void)switchCamera;
@end

@interface ViewController : UIViewController
<UIGestureRecognizerDelegate, AVCaptureFileOutputRecordingDelegate>{
    BOOL WeAreRecording;
    NSURL *outputURL;
    CMTime lastSampleTime;
    AVAssetWriter *assetWriter;
    AVAssetWriterInput *assetWriterInput;
    AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;
}

- (void)overrideCapture:(AVCaptureOutput *)captureOutput
  didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
         fromConnection:(AVCaptureConnection *)connection
           previewLayer:(AVCaptureVideoPreviewLayer *) previewLayer
            previewView:(UIView *) previewView;

@property (nonatomic, strong) UIView *previewView;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@end
