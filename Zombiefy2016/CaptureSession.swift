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

    let captureSession = AVCaptureSession()
    let videoOutput = AVCaptureVideoDataOutput()
    let audioOutput = AVCaptureAudioDataOutput()
    
    var adapter:AVAssetWriterInputPixelBufferAdaptor!
    var isRecording = false
    var videoWriter:AVAssetWriter!
    var writerInput:AVAssetWriterInput!
    var audioWriterInput:AVAssetWriterInput!
    var lastPath = ""
    var starTime = kCMTimeZero
    var devicePosition : AVCaptureDevicePosition!

//    var outputSize = CGSizeMake(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        videoFilter = VideoFilter.init()
        self.cameraControls?.delegate = self
        video()
    }
    
    func video() {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryRecord)
            try AVAudioSession.sharedInstance().setActive(true)
        }catch {
            print("error in audio")
        }
        
        captureSession.beginConfiguration()
        
        captureSession.sessionPreset = AVCaptureSessionPresetMedium
        
        let videoLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        //videoLayer.frame = myImage.bounds
        //myImage.layer.addSublayer(videoLayer)
        
        view.layer.addSublayer(videoLayer!)
        
        let backCamera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        let audio = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        do
        {
            let input = try AVCaptureDeviceInput(device: backCamera)
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
        
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        audioOutput.setSampleBufferDelegate(self, queue: queue)
        
        captureSession.addOutput(videoOutput)
        captureSession.addOutput(audioOutput)
        captureSession.commitConfiguration()
        
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
//            myButton.setTitle("record", forState: .Normal)
            isRecording = false
            self.writerInput.markAsFinished()
            audioWriterInput.markAsFinished()
            self.videoWriter.finishWriting { () -> Void in
                print("FINISHED!!!!!")
                UISaveVideoAtPathToSavedPhotosAlbum(self.lastPath, self, "video:didFinishSavingWithError:contextInfo:", nil)
            }
            
            
        }else{
            
            let fileUrl = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(getCurrentDate())-capturedvideo.MP4")
            
            lastPath = fileUrl!.path
            videoWriter = try? AVAssetWriter(outputURL: fileUrl!, fileType: AVFileTypeMPEG4)
            
            let outputSettings = [AVVideoCodecKey : AVVideoCodecH264, AVVideoWidthKey : NSNumber(value: Float((previewView?.frame.size.width)!)), AVVideoHeightKey : NSNumber(value: Float((previewView?.frame.size.height)!))] as [String : Any]
            
            writerInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings)
            writerInput.expectsMediaDataInRealTime = true
            audioWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: videoFilter.getAudioDictionary() as? [String:AnyObject])
            
            videoWriter.add(writerInput)
            videoWriter.add(audioWriterInput)
            
            adapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: videoFilter.getAdapterDictionary() as? [String:AnyObject])
            
            
            videoWriter.startWriting()
            videoWriter.startSession(atSourceTime: starTime)
            
            isRecording = true
//            myButton.setTitle("stop", forState: .Normal)
            
        }
        
        
    }
    
    func getCurrentDate()->String{
        let format = DateFormatter()
        format.dateFormat = "dd-MM-yyyy hh:mm:ss"
        format.locale = NSLocale(localeIdentifier: "en") as Locale!
        let date = format.string(from: NSDate() as Date)
        return date
    }
    
    
    
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        starTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        if captureOutput == videoOutput {
            connection.videoOrientation = AVCaptureVideoOrientation.portrait
            
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            let cameraImage = CIImage(cvPixelBuffer: pixelBuffer!)
            
            let comicEffect = CIFilter(name: "CIHexagonalPixellate")
            
            comicEffect!.setValue(cameraImage, forKey: kCIInputImageKey)
            
            let filteredImage = UIImage(ciImage: comicEffect!.value(forKey: kCIOutputImageKey) as! CIImage!)
            //let filteredImage = UIImage(CIImage: cameraImage)
            if self.isRecording == true{
                
                DispatchQueue(label: "sample buffer append").sync(execute: {
                    if self.isRecording == true{
                        if self.writerInput.isReadyForMoreMediaData {
                            let b = self.adapter.append(videoFilter.pixelBuffer(from: self.convertCIImageToCGImage(comicEffect!.valueForKey(kCIOutputImageKey) as! CIImage!)).takeRetainedValue() as CVPixelBuffer, size: 1), withPresentationTime: self.starTime);
//                            let bo = self.adapter.appendPixelBuffer(videoFilter.pixelBufferFromCGImage(self.convertCIImageToCGImage(comicEffect!.valueForKey(kCIOutputImageKey) as! CIImage!)).takeRetainedValue() as CVPixelBuffer, withPresentationTime: self.starTime)
//                            
                            print("video is \(bo)")
                        }
                    }
                })
            }
            dispatch_async(dispatch_get_main_queue())
            {
//                self.myImage.image = filteredImage
                
            }
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
