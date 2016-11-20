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
    AVCaptureFileOutputRecordingDelegate,
    AVCaptureVideoDataOutputSampleBufferDelegate,
    CameraControlsProtocolSwift{

    @IBOutlet weak var previewView: UIView?
    @IBOutlet weak var cameraControls: CameraControls?
    
    var videoFilter: ViewController!
    var captureSession : AVCaptureSession!
    var captureDevice:AVCaptureDevice!
    var deviceInput : AVCaptureDeviceInput!
    var videoDataOutput : AVCaptureVideoDataOutput!
    var previewLayer : AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCapture()
    }

    func setupCapture() {
        
        videoFilter = ViewController.init()
        self.cameraControls?.delegate = self
        
        captureSession = AVCaptureSession()
        
        let videoDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        
        for device in videoDevices!{
            let device = device as! AVCaptureDevice
            if device.position == AVCaptureDevicePosition.front {
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
                
                //  Converted with Swiftify v1.0.6166 - https://objectivec2swift.com/
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

//                    var movieFileOutput = AVCaptureMovieFileOutput();
//                    captureSession.addOutput(movieFileOutput)
                    
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
        
    }
    
    func switchCamera(){
        captureDevice = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
            .map { $0 as! AVCaptureDevice }
            .filter { $0.position == .back}
            .first!
    }
    
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
//        let pixelBuffer : CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
//        let attachments : CFDictionary = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, pixelBuffer, CMAttachmentMode( kCMAttachmentMode_ShouldPropagate))!
//        let ciImage : CIImage = CIImage(cvPixelBuffer: pixelBuffer, options: attachments as? [String : AnyObject])
        //  Converted with Swiftify v1.0.6166 - https://objectivec2swift.com/
        // get the image
        var pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        var attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer!, options: (attachments as? [String : AnyObject]))
        if attachments != nil {
            
        }

        videoFilter.processCIImage(ciImage, didOutputSampleBuffer: sampleBuffer, previewLayer: self.previewLayer, previewView: self.previewView)
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        
    }

}
