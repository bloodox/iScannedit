//
//  DocScannerViewController.swift
//  iScan
//
//  Created by William Thompson on 1/28/17.
//  Copyright © 2017 William Thompson. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia
import CoreVideo
import QuartzCore
import CoreImage
import ImageIO
import MobileCoreServices
import GLKit

var isForceStop: Bool = false




class DocScannerRectangleFeature: NSObject {
    var topLeft = CGPoint.zero
    var topRight = CGPoint.zero
    var bottomRight = CGPoint.zero
    var bottomLeft = CGPoint.zero
}

enum CGImageAlphaInfo: UInt32 {
    case noneSkipLast
}




enum DocScannerCameraViewType : Int {
    case blackAndWhite
    case normal
}
enum glkit : Int {
    case format24 = 2
}
class DocScannerViewController: UIView, AVCaptureVideoDataOutputSampleBufferDelegate  {
    var coreImageContext: CIContext?
    var renderBuffer = GLuint()
    var glkView: GLKView?
    var isStopped: Bool = false
    var imageDedectionConfidence: CGFloat = 0.0
    var borderDetectTimeKeeper: Timer?
    var borderDetectFrames: Bool = false
    var borderDetectLastRectangleFeature: CIRectangleFeature?
    var isCapturing: Bool = false
    var captureQueue: DispatchQueue?
    var isForceStop: Bool = false
    var captureSession: AVCaptureSession!
    var captureDevice: AVCaptureDevice!
    var context: EAGLContext?
    var stillImageOutput: AVCaptureStillImageOutput!
    var intrinsicContentSizes = CGSize.zero
    var isEnableBorderDetection: Bool = false
    var isEnableTorch: Bool = false
    var cameraViewType = DocScannerCameraViewType(rawValue: 0)
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var frameView: UIView?
    func setupCameraView() {
        self.createGLKView()
        let possibleDevices: [Any] = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        let device: AVCaptureDevice? = possibleDevices.first as! AVCaptureDevice?
        if device == nil {
            return
        }
        self.imageDedectionConfidence = 0.0
        let session = AVCaptureSession()
        self.captureSession = session
        session.beginConfiguration()
        self.captureDevice = device
        let input = try? AVCaptureDeviceInput(device: device)
        session.sessionPreset = AVCaptureSessionPresetPhoto
        session.addInput(input)
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.alwaysDiscardsLateVideoFrames = true
        dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey) as AnyHashable: (kCVPixelFormatType_32BGRA)]
        dataOutput.setSampleBufferDelegate(self, queue: self.captureQueue)
        session.addOutput(dataOutput)
        self.stillImageOutput = AVCaptureStillImageOutput()
        session.addOutput(self.stillImageOutput)
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoPreviewLayer?.frame = layer.bounds
        layer.addSublayer(videoPreviewLayer!)
        
        
        
        
        let connection: AVCaptureConnection? = (dataOutput.connections).first as! AVCaptureConnection?
        connection?.videoOrientation = .portrait
        if (device?.isFlashAvailable)! {
            do {
                try device?.lockForConfiguration()
                device?.flashMode = .off
                device?.unlockForConfiguration()
            } catch {
                print("error")
            }
            
            if (device?.isFocusModeSupported(.continuousAutoFocus))! {
                do {
                    try device?.lockForConfiguration()
                    device?.focusMode = .continuousAutoFocus
                    device?.unlockForConfiguration()
                } catch {
                    print("error")
                }
            }
        }
        session.commitConfiguration()
        glkView?.display()
        
    }
    func setCameraViewType(_ cameraViewType: DocScannerCameraViewType) {
        let effect = UIBlurEffect(style: .dark)
        let viewWithBlurredBackground = UIVisualEffectView(effect: effect)
        viewWithBlurredBackground.frame = self.bounds
        self.insertSubview(viewWithBlurredBackground, aboveSubview: self.glkView!)
        self.cameraViewType = cameraViewType
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {() -> Void in
            viewWithBlurredBackground.removeFromSuperview()
        })
    }
    func start() {
        self.isStopped = false
        captureSession.startRunning()
        self.borderDetectTimeKeeper = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(getter: self.borderDetectFrames), userInfo: nil, repeats: true)
        glkView?.isHidden = false
    }
    func stop() {
    }
    
    
    func focus(at point: CGPoint, completionHandler: @escaping () -> Void) {
        let device: AVCaptureDevice? = self.captureDevice
        var pointOfInterest = CGPoint.zero
        let frameSize: CGSize = self.bounds.size
        pointOfInterest = CGPoint(x: CGFloat(point.y / frameSize.height), y: CGFloat(1.0 - (point.x / frameSize.width)))
        if (device?.isFocusPointOfInterestSupported)! && (device?.isFocusModeSupported(.autoFocus))! {
            
            do {
                try! device?.lockForConfiguration()
                if (device?.isFocusModeSupported(.continuousAutoFocus))! {
                    device?.focusMode = .continuousAutoFocus
                    device?.focusPointOfInterest = pointOfInterest
                }
            } catch {
                print(error)
            }
            
            if (device?.isExposurePointOfInterestSupported)! && (device?.isExposureModeSupported(.continuousAutoExposure))! {
                device?.exposurePointOfInterest = pointOfInterest
                device?.exposureMode = .continuousAutoExposure
                completionHandler()
            }
            device?.unlockForConfiguration()
            
        }
        else {
            completionHandler()
        }
    }
    func captureImage(withCompletionHander completionHandler: @escaping (_ imageFilePath: String) -> Void) {
        self.captureQueue?.suspend()
        var port = AVCaptureInputPort()
        var connection = AVCaptureConnection()
        var videoConnection = AVCaptureConnection()
        for connection in self.stillImageOutput.connections{
            for port in (connection as AnyObject).inputPorts {
                if (port as AnyObject).mediaType.isEqual(AVMediaTypeVideo) {
                    videoConnection = connection as! AVCaptureConnection
                    break
                }
            }
            if videoConnection != nil {
                break
            }
        }
        weak var weakSelf = self
        self.stillImageOutput.captureStillImageAsynchronously(from: videoConnection) { sampleBuffer, error in
            //do stuff with your sample buffer, don't forget to handle errors
            if error != nil {
                self.captureQueue?.resume()
                return
            }
            let filePath: String = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ipdf_img_\(Int(Date().timeIntervalSince1970)).jpeg").absoluteString
            var imageData: Data? = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
            var enhancedImage = CIImage(data: imageData!, options: [kCIImageColorSpace: NSNull()])
            imageData = nil
            if weakSelf?.cameraViewType == DocScannerCameraViewType.blackAndWhite {
                enhancedImage = self.filteredImageUsingEnhanceFilter(on: enhancedImage!)
            }
            else {
                enhancedImage = self.filteredImageUsingContrastFilter(on: enhancedImage!)
            }
            if (weakSelf?.isEnableBorderDetection)! && self.rectangleDetectionConfidenceHighEnough(confidence: self.imageDedectionConfidence) {
                let rectangleFeature: CIRectangleFeature? = self.biggestRectangle(inRectangles: self.highAccuracyRectangleDetector().features(in: enhancedImage!))
                if rectangleFeature != nil {
                    enhancedImage = self.correctPerspective(for: enhancedImage!, withFeatures: rectangleFeature!)
                }
            }
            let transform = CIFilter(name: "CIAffineTransform")
            transform?.setValue(enhancedImage, forKey: kCIInputImageKey)
            let rotation = NSValue(cgAffineTransform: CGAffineTransform(rotationAngle: -90 * (.pi / 180)))
            transform?.setValue(rotation, forKey: "inputTransform")
            enhancedImage = transform?.outputImage
            if !(enhancedImage != nil) || (enhancedImage?.extent.isEmpty)! {
                return
            }
            var ctx: CIContext? = nil
            if ctx == nil {
                ctx = CIContext(options:[kCIContextWorkingColorSpace: NSNull()])
            }
            var bounds: CGSize = (enhancedImage?.extent.size)!
            bounds = CGSize(width: CGFloat((floorf(Float(bounds.width)) / 4) * 4), height: CGFloat((floorf(Float(bounds.height)) / 4) * 4))
            let extent = CGRect(x: CGFloat((enhancedImage?.extent.origin.x)!), y: CGFloat((enhancedImage?.extent.origin.y)!), width: CGFloat(bounds.width), height: CGFloat(bounds.height))
            let bytesPerPixel: CGFloat = 8
            let rowBytes = bytesPerPixel * bounds.width
            let totalBytes = rowBytes * bounds.height
            let byteBuffer = malloc(Int(totalBytes))
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            ctx!.render(enhancedImage!, toBitmap: byteBuffer!, rowBytes: Int(rowBytes), bounds: extent, format: kCIFormatRGBA8, colorSpace: colorSpace)
            let bitmapContext = CGContext(data: byteBuffer, width: Int(bounds.width), height: Int(bounds.height), bitsPerComponent: Int(bytesPerPixel), bytesPerRow: Int(rowBytes), space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
            let imgRef = bitmapContext?.makeImage()
            (colorSpace)
            (bitmapContext)
            free(byteBuffer)
            if imgRef == nil {
                (imgRef)
                return
            }
            self.saveCGImageAsJPEGToFilePath(imgRef: imgRef!, filePath: filePath)
            (imgRef)
            DispatchQueue.main.async(execute: {() -> Void in
                completionHandler(filePath)
                self.captureQueue?.resume()
            })
            self.imageDedectionConfidence = 0.0
        }
    }
    func hideGLKView(_ hidden: Bool, completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.1, animations: {() -> Void in
            self.glkView?.alpha = (hidden) ? 0.0 : 1.0
        }, completion: {(_ finished: Bool) -> Void in
            if completion != nil {
                return
            }
            completion()
        })
    }
    
    func saveCGImageAsJPEGToFilePath(imgRef: CGImage, filePath: String){
        do {
            let url: CFURL? = (URL(fileURLWithPath: filePath) as? CFURL)
            let destination: CGImageDestination = CGImageDestinationCreateWithURL(url!, kUTTypeJPEG, 1, nil)!
            CGImageDestinationAddImage(destination, imgRef, nil)
            CGImageDestinationFinalize(destination)
            
        }
    }
    func correctPerspective(for image: CIImage, withFeatures rectangleFeature: CIRectangleFeature) -> CIImage {
        var rectangleCoordinates = [AnyHashable: Any]()
        rectangleCoordinates["inputTopLeft"] = CIVector(cgPoint: rectangleFeature.topLeft)
        rectangleCoordinates["inputTopRight"] = CIVector(cgPoint: rectangleFeature.topRight)
        rectangleCoordinates["inputBottomLeft"] = CIVector(cgPoint: rectangleFeature.bottomLeft)
        rectangleCoordinates["inputBottomRight"] = CIVector(cgPoint: rectangleFeature.bottomRight)
        return image.applyingFilter("CIPerspectiveCorrection", withInputParameters: ["inputTopLeft": CIVector(cgPoint: rectangleFeature.topLeft), "inputTopRight": CIVector(cgPoint: rectangleFeature.topRight), "inputBottomLeft": CIVector(cgPoint: rectangleFeature.bottomLeft), "inputBottomRight": CIVector(cgPoint: rectangleFeature.bottomRight)])
    }
    func rectangleDetectionConfidenceHighEnough(confidence: CGFloat) -> Bool {
        let confidence: Float = 0.0
        do {
            return (confidence > 1.0)
        }
    }
    func backgroundMode() {
        self.isForceStop = true
    }
    func _foregroundMode() {
        self.isForceStop = false
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(self, selector: #selector(self.backgroundMode), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self._foregroundMode), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        self.captureQueue = DispatchQueue(label: "com.instapdf.AVCameraCaptureQueue")
    }
    func createGLKView() {
        if self.context != context {
        let view = GLKView(frame: frame, context: EAGLContext(api: .openGLES2))
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        view.context = self.context!
        view.contentScaleFactor = 1.0
        view.drawableDepthFormat = GLKViewDrawableDepthFormat(rawValue: GLint(0.24))!
        self.insertSubview(view, at: 0)
        self.glkView = view
        self.coreImageContext = CIContext(eaglContext: self.context!, options: [kCIContextWorkingColorSpace: NSNull(), kCIContextUseSoftwareRenderer: (false)])
    }
    }
    func cropRect(forPreviewImage image: CIImage) -> CGRect {
        var cropWidth: CGFloat = image.extent.size.width
        var cropHeight: CGFloat = image.extent.size.height
        if image.extent.size.width > image.extent.size.height {
            cropWidth = image.extent.size.width
            cropHeight = cropWidth * self.bounds.size.height / self.bounds.size.width
        }
        else if image.extent.size.width < image.extent.size.height {
            cropHeight = image.extent.size.height
            cropWidth = cropHeight * self.bounds.size.width / self.bounds.size.height
        }
        
        return image.extent.insetBy(dx: CGFloat((image.extent.size.width - cropWidth) / 2), dy: CGFloat((image.extent.size.height - cropHeight) / 2))
    }
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutputSampleBuffer sampleBuffer: CMSampleBuffer?, from connection: AVCaptureConnection) {
        if self.isForceStop {
            return
        }
        if self.isStopped || self.isCapturing || !CMSampleBufferIsValid(sampleBuffer!) {
            return
        }
        let pixelBuffer: CVPixelBuffer? = (CMSampleBufferGetImageBuffer(sampleBuffer!)! )
        var image = CIImage(cvPixelBuffer: pixelBuffer!)
        if self.cameraViewType != DocScannerCameraViewType.normal {
            image = self.filteredImageUsingEnhanceFilter(on: image)
        }
        else {
            image = self.filteredImageUsingContrastFilter(on: image)
        }
        if borderDetectFrames != nil {
            if self.borderDetectFrames {
                self.borderDetectLastRectangleFeature = self.biggestRectangle(inRectangles: self.highAccuracyRectangleDetector().features(in: image))
                self.borderDetectFrames = false
            }
            if (self.borderDetectLastRectangleFeature != nil) {
                self.imageDedectionConfidence += 0.5
                image = self.drawHighlightOverlay(forPoints: image, topLeft: (self.borderDetectLastRectangleFeature?.topLeft)!, topRight: (self.borderDetectLastRectangleFeature?.topRight)!, bottomLeft: (self.borderDetectLastRectangleFeature?.bottomLeft)!, bottomRight: (self.borderDetectLastRectangleFeature?.bottomRight)!)
            }
            else {
                self.imageDedectionConfidence = 0.0
            }
        }
        if (self.context != nil) && (self.coreImageContext != nil) {
            if self.context != EAGLContext.current() {
                EAGLContext.setCurrent(self.context)
            }
            self.glkView?.bindDrawable()
            
            self.glkView?.display()
            if self.intrinsicContentSize.width != image.extent.size.width {
                
                DispatchQueue.main.async(execute: {() -> Void in
                    self.invalidateIntrinsicContentSize()
                })
            }
            
        }
    }
    func _intrinsicContentSize() -> CGSize {
        if self._intrinsicContentSize().width == 0 || self._intrinsicContentSize().height == 0 {
            return CGSize(width: CGFloat(1), height: CGFloat(1))
            //just enough so rendering doesn't crash
        }
        return self._intrinsicContentSize()
    }
    func drawHighlightOverlay(forPoints image: CIImage, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) -> CIImage {
        var overlay = CIImage(color: CIColor(red: 0.0, green: 1.0, blue: 0, alpha: 0.5))
        overlay = overlay.cropping(to: image.extent)
        overlay = overlay.applyingFilter("CIPerspectiveTransformWithExtent",
                                         withInputParameters: [
                                            "inputExtent": CIVector(cgRect: image.extent),
                                            "inputTopLeft": CIVector(cgPoint: topLeft),
                                            "inputTopRight": CIVector(cgPoint: topRight),
                                            "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                                            "inputBottomRight": CIVector(cgPoint: bottomRight)
            ])
        return overlay.compositingOverImage(image)
    }
    func setEnableTorch(flashMode: AVCaptureFlashMode, device: AVCaptureDevice) {
        
        let device: AVCaptureDevice? = self.captureDevice
        if (device?.hasFlash)! && (device?.isFlashModeSupported(flashMode))! {
            var error: NSError? = nil
            do {
                try device?.lockForConfiguration()
                device?.flashMode = flashMode
                device?.unlockForConfiguration()
            } catch let error1 as NSError {
                error = error1
                print(error!)
            }
        }
    }
    func filteredImageUsingEnhanceFilter(on image: CIImage) -> CIImage {
        return CIFilter(name: "CIColorControls", withInputParameters: ["inputContrast": (1.1), kCIInputImageKey: image])!.outputImage!
    }
    func filteredImageUsingContrastFilter(on image: CIImage) -> CIImage {
        return CIFilter(name: "CIColorControls", withInputParameters: ["inputContrast": (1.1), kCIInputImageKey: image])!.outputImage!
    }
    func enableBorderDetectFrame() {
        self.borderDetectFrames = true
    }
    func biggestRectangle(inRectangles rectangles: [Any]) -> CIRectangleFeature {
        if (rectangles.count) != nil {
            var halfPerimiterValue: Float = 0
            var biggestRectangle: CIRectangleFeature? = rectangles.first as! CIRectangleFeature?
            for rect: CIRectangleFeature in rectangles as! [CIRectangleFeature]{
                let p1: CGPoint = rect.topLeft
                let p2: CGPoint = rect.topRight
                let width: CGFloat = CGFloat(hypotf(Float(p1.x) - Float(p2.x), Float(p1.y) - Float(p2.y)))
                let p3: CGPoint = rect.topLeft
                let p4: CGPoint = rect.bottomLeft
                let height: CGFloat = CGFloat(hypotf(Float(p3.x) - Float(p4.x), Float(p3.y) - Float(p4.y)))
                let currentHalfPerimiterValue: CGFloat = height + width
                if halfPerimiterValue < Float(currentHalfPerimiterValue) {
                    halfPerimiterValue = Float(currentHalfPerimiterValue)
                    biggestRectangle = rect
                }
            }
            
        }
        return biggestRectangle as Any as! CIRectangleFeature
    }
    func rectangleDetetor() -> CIDetector {
        var detector: CIDetector? = nil
        /* TODO: move below code to the static variable initializer (dispatch_once is deprecated) */
        ({() -> Void in
            detector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyLow, CIDetectorTracking: (true)])
        })()
        return detector!
    }
    
    func highAccuracyRectangleDetector() -> CIDetector {
        var detector: CIDetector? = nil
        /* TODO: move below code to the static variable initializer (dispatch_once is deprecated) */
        ({() -> Void in
            detector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        })()
        return detector!
    }
    
}
