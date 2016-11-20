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
    
    var captureSession : AVCaptureSession!
    var captureDevice:AVCaptureDevice!
    var deviceInput : AVCaptureDeviceInput!
    var stillImageOutput : AVCaptureStillImageOutput!
    var previewLayer : AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCapture()
    }

    func setupCapture() {
        
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
                
                stillImageOutput = AVCaptureStillImageOutput()
                stillImageOutput?.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
                
                if (captureSession?.canAddOutput(stillImageOutput) != nil){
                    captureSession?.addOutput(stillImageOutput)
                    
                    var movieFileOutput = AVCaptureMovieFileOutput();
                    captureSession.addOutput(movieFileOutput)
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
        let pixelBuffer : CVPixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let attachments : CFDictionaryRef = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, pixelBuffer, CMAttachmentMode( kCMAttachmentMode_ShouldPropagate))!
        let ciImage : CIImage = CIImage(CVPixelBuffer: pixelBuffer, options: attachments as? [String : AnyObject])
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        
    }

}
