//
//  VideoSessionVCViewController.swift
//  Zombiefy2016
//
//  Created by Ben Smith on 20/11/16.
//  Copyright © 2016 Ben Smith. All rights reserved.
//

import UIKit

protocol CameraControlsProtocolSwift {
    func record()
    func switchCamera()
}

class VideoSessionVCViewController: UIViewController,
    AVCaptureVideoDataOutputSampleBufferDelegate,
    CameraControlsProtocolSwift{

    @IBOutlet weak var previewView: UIView?
    @IBOutlet weak var cameraControls: CameraControls?
    
    var videoFilter: VideoFilter!
    var captureSession : AVCaptureSession!
    var captureDevice:AVCaptureDevice!
    var deviceInput : AVCaptureDeviceInput!
    var videoDataOutput : AVCaptureVideoDataOutput!
    var previewLayer : AVCaptureVideoPreviewLayer!
    var devicePosition : AVCaptureDevicePosition!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        devicePosition = AVCaptureDevicePosition.front
        setupCapture()
    }

    func setupCapture() {
        
        videoFilter = VideoFilter.init()
        self.cameraControls?.delegate = self
        
        captureSession = AVCaptureSession()
        
        let videoDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        
        for device in videoDevices!{
            let device = device as! AVCaptureDevice
            if device.position == devicePosition {
                captureDevice = device
                break
            }
        }
        
        if self.captureDevice == nil{
            captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        }
        
        do {
            let input = try? AVCaptureDeviceInput(device: captureDevice)
            
            if (captureSession?.canAddInput(input) != nil){
                
                captureSession?.addInput(input)
                
                // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
                var rgbOutputSettings = [ (kCVPixelBufferPixelFormatTypeKey as String) : Int(kCMPixelFormat_32BGRA) ]

                videoDataOutput = AVCaptureVideoDataOutput()
                videoDataOutput.videoSettings = rgbOutputSettings
                videoDataOutput.alwaysDiscardsLateVideoFrames = true
                var videoDataOutputQueue = DispatchQueue(label:"VideoDataOutputQueue")
                videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)

                if (captureSession?.canAddOutput(videoDataOutput) != nil){
                    captureSession?.addOutput(videoDataOutput)
                    videoDataOutput.connection(withMediaType: AVMediaTypeVideo).isEnabled = true
                    
                    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                    
                    previewLayer?.videoGravity = AVLayerVideoGravityResizeAspect
                    previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                    
                    let rootLayer : CALayer = previewView!.layer
                    rootLayer.masksToBounds = true
                    previewLayer.frame = rootLayer.bounds
                    rootLayer.addSublayer(previewLayer)
                    
                    captureSession?.startRunning()
                    
                }
                
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func record() {
        videoFilter.record()
    }
    
    func switchCamera(){
        captureSession?.stopRunning()
        previewLayer?.removeFromSuperlayer()
        if devicePosition == AVCaptureDevicePosition.back {
            devicePosition = AVCaptureDevicePosition.front
        } else {
            devicePosition = AVCaptureDevicePosition.back
        }
        setupCapture()
    }
    
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {

        // get the image
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer!, options: (attachments as? [String : AnyObject]))
        if attachments != nil {
            
        }

        videoFilter.processCIImage(ciImage, didOutputSampleBuffer: sampleBuffer, previewLayer: self.previewLayer, previewView: self.previewView, videoDataOutput: self.videoDataOutput)
    }

}
