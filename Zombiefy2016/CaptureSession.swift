//
//  CaptureSession.swift
//  Zombiefy2016
//
//  Created by Ben Smith on 21/11/16.
//  Copyright © 2016 Ben Smith. All rights reserved.
//

import UIKit

class CaptureSession: UIViewController, CameraControlsProtocolSwift,AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {

    @IBOutlet weak var cameraControls: CameraControls?
    @IBOutlet weak var previewView: UIView?

    var videoFilter: VideoFilter!

    var captureSession = AVCaptureSession()
    var videoOutput = AVCaptureVideoDataOutput()
    var audioOutput = AVCaptureAudioDataOutput()
    var videoLayer = AVCaptureVideoPreviewLayer()

    var adapter:AVAssetWriterInputPixelBufferAdaptor!
    var isRecording = false
    var videoWriter:AVAssetWriter!
    var writerInput:AVAssetWriterInput!
    var audioWriterInput:AVAssetWriterInput!
    var lastPath = ""
    var starTime = kCMTimeZero
    var devicePosition : AVCaptureDevicePosition!
    var captureDevice:AVCaptureDevice!

//    var outputSize = CGSizeMake(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        devicePosition = AVCaptureDevicePosition.front
        videoFilter = VideoFilter.init()
        self.cameraControls?.delegate = self
        self.cameraControls?.recordButton?.setTitle("record", for: .normal)
        video()
    }
    
    func video() {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryRecord)
            try AVAudioSession.sharedInstance().setActive(true)
        }catch {
            print("error in audio")
        }
        
        captureSession = AVCaptureSession()

//        captureSession.beginConfiguration()
//        captureSession.sessionPreset = AVCaptureSessionPresetMedium
        
        //create AVCaptureVideoPreviewLayer
        self.videoLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        if self.captureDevice == nil{
            captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        }
        
        let videoDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        
        for device in videoDevices!{
            let device = device as! AVCaptureDevice
            if device.position == devicePosition {
                captureDevice = device
                break
            }
        }
        
        let audio = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        do
        {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            let audioInput = try AVCaptureDeviceInput(device: audio)
            
            captureSession.addInput(input)
            captureSession.addInput(audioInput)
            
        }
        catch
        {
            print("can't access camera")
            return
        }
        let queue = DispatchQueue(label: "sample buffer delegate")

        //video output
        //set rgb settins for video
        let rgbOutputSettings = [ (kCVPixelBufferPixelFormatTypeKey as String) : Int(kCMPixelFormat_32BGRA) ]
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = rgbOutputSettings
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        captureSession.addOutput(videoOutput)
        videoOutput.connection(withMediaType: AVMediaTypeVideo).isEnabled = true
//        videoOutput.connection(withMediaType: AVMediaTypeVideo).videoOrientation = AVCaptureVideoOrientation.portrait

        //add audio to session
        audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: queue)
        captureSession.addOutput(audioOutput)
        captureSession.commitConfiguration()
        
        //set video layer
        videoLayer.videoGravity = AVLayerVideoGravityResizeAspect
        videoLayer.connection.videoOrientation = AVCaptureVideoOrientation.portrait

        //add our videolayer or AVCaptureVideoPreviewLayer to our rootlayer
        let rootLayer : CALayer = previewView!.layer
        rootLayer.masksToBounds = true
        self.videoLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(self.videoLayer)
        
        captureSession.startRunning()
        
    }
    
    func switchCamera(){
        self.captureSession.stopRunning()
        //        previewLayer?.removeFromSuperlayer()
        if devicePosition == AVCaptureDevicePosition.back {
            devicePosition = AVCaptureDevicePosition.front
        } else {
            devicePosition = AVCaptureDevicePosition.back
        }
        video()
    }
    
    
    func record() {
        
        if isRecording {
            self.cameraControls?.recordButton?.setTitle("record", for: .normal)
            isRecording = false
            self.writerInput.markAsFinished()
            audioWriterInput.markAsFinished()
            self.videoWriter.finishWriting { () -> Void in
                print("FINISHED!!!!!")
                UISaveVideoAtPathToSavedPhotosAlbum(self.lastPath, self, #selector(self.video(videoPath:didFinishSavingWithError:contextInfo:)), nil)

            }
            
            
        } else{
            
            let fileUrl = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(getCurrentDate())-capturedvideo.MP4")
            
            lastPath = fileUrl!.path
            videoWriter = try? AVAssetWriter(outputURL: fileUrl!, fileType: AVFileTypeMPEG4)
            
            let outputSettings = [AVVideoCodecKey : AVVideoCodecH264, AVVideoWidthKey : NSNumber(value: Float(previewView!.layer.bounds.size.width)), AVVideoHeightKey : NSNumber(value: Float(previewView!.layer.bounds.size.height))] as [String : Any]
            
            writerInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings)
            writerInput.expectsMediaDataInRealTime = true
            audioWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: videoFilter.getAudioDictionary() as? [String:AnyObject])
            
            videoWriter.add(writerInput)
            videoWriter.add(audioWriterInput)
            
            adapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: videoFilter.getAdapterDictionary() as? [String:AnyObject])
            
            
            videoWriter.startWriting()
            videoWriter.startSession(atSourceTime: starTime)
            
            isRecording = true
            self.cameraControls?.recordButton?.setTitle("stop", for: .normal)
            
        }
        
        
    }
    
    func getCurrentDate()->String{
        let format = DateFormatter()
        format.dateFormat = "dd-MM-yyyy hh:mm:ss"
        format.locale = NSLocale(localeIdentifier: "en") as Locale!
        let date = format.string(from: NSDate() as Date)
        return date
    }
    
    
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        starTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        if captureOutput == videoOutput {
//            connection.videoOrientation = AVCaptureVideoOrientation.portrait
        
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            let cameraImage = CIImage(cvPixelBuffer: pixelBuffer!)
            
            //filter
            let comicEffect = CIFilter(name: "CIHexagonalPixellate")
            comicEffect!.setValue(cameraImage, forKey: kCIInputImageKey)
            
            videoFilter.processCIImage(cameraImage, didOutputSampleBuffer: sampleBuffer, previewLayer: self.videoLayer, previewView: self.previewView, videoDataOutput: self.videoOutput, { (image) in
                if self.isRecording == true{
                    
                    DispatchQueue(label: "sample buffer append").sync(execute: {
                        if self.isRecording == true{
                            if self.writerInput.isReadyForMoreMediaData {
                                if let ciImage = CIImage(image: image!) {
                                    let cgiImage = self.convertCIImageToCGImage(inputImage: ciImage)
                                    let pixelBuffer = self.videoFilter.pixelBuffer(fromCGImageRef: cgiImage, size: (self.previewView?.frame.size)!).takeRetainedValue() as CVPixelBuffer
                                    self.adapter.append(pixelBuffer, withPresentationTime: self.starTime)
                                    
                               
//                                    let cgiImage = self.convertCIImageToCGImage(inputImage: cameraImage)
//                                    let pixelBuffer = self.videoFilter.pixelBuffer(fromCGImageRef: cgiImage, size: (CGSize.init(width: 1024, height: 968))).takeRetainedValue() as CVPixelBuffer
//                                    self.adapter.append(pixelBuffer, withPresentationTime: self.starTime)

//                                    let b2 = self.writerInput.append(sampleBuffer)

                                }

                            }
                        }
                    })
                }
            })

        }else if captureOutput == audioOutput{
            
            if self.isRecording == true{
                
                let bo = audioWriterInput.append(sampleBuffer)
                print("audio is \(bo)")
            }
        }
        
        
        
    }
    
    
    func convertCIImageToCGImage(inputImage: CIImage) -> CGImage! {
        let context:CIContext? = CIContext(options: nil)
        if context != nil {
            return context!.createCGImage(inputImage, from: inputImage.extent)
        }
        return nil
    }
    
    func video(videoPath: NSString, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject) {
        var title = "Success"
        var message = "Video was saved"
        
        if let saveError = error {
            title = "Error"
            message = "Video failed to save"
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
