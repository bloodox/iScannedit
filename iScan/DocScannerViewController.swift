
//
//  DocScannerViewController.swift
//  iScan
//
//  Created by William Thompson on 2/26/17.
//  Copyright © 2017 J.W.Enterprises LLC. All rights reserved.
//  Inspired by Maximilian Mackh's IPDFCamerViewController

import UIKit
import AVFoundation
import CoreMedia
import CoreVideo
import QuartzCore
import CoreImage
import ImageIO
import MobileCoreServices
import GLKit

class DocScannerRectangleFeature: CIRectangleFeature {
    var topL = CGPoint.zero
    var topR = CGPoint.zero
    var bottomR = CGPoint.zero
    var bottomL = CGPoint.zero
}
enum CGImageAlphaInfo: UInt32 {
    case noneSkipLast = 5
}
enum DocScannerCameraViewType : Int {
    case blackAndWhite
    case normal
    case sepiaTone
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
    var context: EAGLContext!
    var stillImageOutput: AVCaptureStillImageOutput!
    var intrinsicContentSizes = CGSize.zero
    var enableBorderDetection: Bool = false
    var enableTorch: Bool = false
    var cameraViewType = DocScannerCameraViewType(rawValue: 0)
    var detector: CIDetector?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(self, selector: #selector(self.backgroundMode), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.foregroundMode), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        self.captureQueue = DispatchQueue(label: "com.AVCameraCaptureQueue")
    }
    func backgroundMode() {
        self.isForceStop = true
    }
    func foregroundMode() {
        self.isForceStop = false
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    func createGLKView() {
        if ((self.context) != nil) {
            return
        }
        self.context = EAGLContext(api: .openGLES2)
        let view = GLKView(frame: self.bounds)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        view.context = self.context
        view.contentScaleFactor = 1.0
        view.drawableDepthFormat = GLKViewDrawableDepthFormat(rawValue: GLint(0.24))!
        self.insertSubview(view, at: 0)
        self.glkView = view
        self.coreImageContext = CIContext(eaglContext: self.context, options: [kCIContextWorkingColorSpace: NSNull(), kCIContextUseSoftwareRenderer: (false)])
    }
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
        dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as AnyHashable): (kCVPixelFormatType_32BGRA)]
        dataOutput.setSampleBufferDelegate(self, queue: self.captureQueue)
        session.addOutput(dataOutput)
        self.stillImageOutput = AVCaptureStillImageOutput()
        session.addOutput(self.stillImageOutput)
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
        self.hideGLKView(false, completion: { _ in })
    }
    func stop() {
        self.isStopped = true
        self.captureSession.stopRunning()
        self.borderDetectTimeKeeper?.invalidate()
        self.hideGLKView(true, completion: { _ in })
    }
    func focusAtPoint(point: CGPoint, completionHandler: @escaping () -> Void) {
        let device: AVCaptureDevice? = self.captureDevice
        var pointOfInterest = CGPoint.zero
        let frameSize: CGSize = (self.bounds.size)
        pointOfInterest = CGPoint(x: CGFloat(point.y / frameSize.height), y: CGFloat(1.0 - (point.x / frameSize.width)))
        if (device?.isFocusPointOfInterestSupported)! && (device?.isFocusModeSupported(.autoFocus))! {
            do {
                try device?.lockForConfiguration()
                if (device?.isFocusModeSupported(.continuousAutoFocus))! {
                    device?.focusMode = .continuousAutoFocus
                    device?.focusPointOfInterest = pointOfInterest
                }
                if (device?.isExposurePointOfInterestSupported)! && (device?.isExposureModeSupported(.continuousAutoExposure))! {
                    device?.exposurePointOfInterest = pointOfInterest
                    device?.exposureMode = .continuousAutoExposure
                    completionHandler()
                }
                device?.unlockForConfiguration()
            } catch {
                print("error")
            }
        }
        else {
            completionHandler()
        }
    }
    func captureImage(completionHandler: @escaping (_ imageFilePath: String) -> Void) {
        self.captureQueue?.suspend()
        var videoConnection: AVCaptureConnection!
        for connection in self.stillImageOutput.connections{
            for port in (connection as! AVCaptureConnection).inputPorts {
                if (port as! AVCaptureInputPort).mediaType.isEqual(AVMediaTypeVideo) {
                    videoConnection = connection as! AVCaptureConnection
                    break
                }
            }
            if videoConnection != nil {
                break
            }
        }
        weak var weakSelf = self
        self.stillImageOutput.captureStillImageAsynchronously(from: videoConnection) { (sampleBuffer: CMSampleBuffer?, error) -> Void in
            if error != nil {
                self.captureQueue?.resume()
                return
            }
            let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let documentsDirectory: String = filePath[0]
            let fullPath: String = documentsDirectory.appending("/iScan_\(Int(Date().timeIntervalSince1970)).pdf")
            autoreleasepool {
                let imageData = Data(AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer))
                var enhancedImage = CIImage(data: imageData, options: [kCIImageColorSpace: NSNull()])
                if weakSelf?.cameraViewType == DocScannerCameraViewType.blackAndWhite {
                    enhancedImage = self.blackAndWhiteFilter(on: enhancedImage!)
                }
                if weakSelf?.cameraViewType == DocScannerCameraViewType.normal {
                    enhancedImage = self.colorFilter(on: enhancedImage!)
                }
                if weakSelf?.cameraViewType == DocScannerCameraViewType.sepiaTone {
                    enhancedImage = self.sepiaTone(on: enhancedImage!)
                }
                if (weakSelf?.enableBorderDetection == true) && self.rectangleDetectionConfidenceHighEnough(confidence: self.imageDedectionConfidence) {
                    let features = self.highAccuracyRectangleDetector().features(in: enhancedImage!)
                    for feature: CIRectangleFeature in features as! [CIRectangleFeature] {
                        let rectangleFeature: CIRectangleFeature? = self.biggestRectangle(rectangles: features)
                        if rectangleFeature != nil {
                            enhancedImage = self.correctPerspective(for: enhancedImage!, withFeatures: feature)
                        }}
                }
                let transform = CIFilter(name: "CIAffineTransform")
                transform?.setValue(enhancedImage, forKey: kCIInputImageKey)
                let rotation = NSValue(cgAffineTransform: CGAffineTransform(rotationAngle: -90 * (.pi / 180)))
                transform?.setValue(rotation, forKey: "inputTransform")
                enhancedImage = (transform?.outputImage)!
                if (enhancedImage == nil) || (enhancedImage?.extent.isEmpty)! {
                    return
                }
                var ctx: CIContext?
                if (ctx == nil) {
                    ctx = CIContext(options: [kCIContextWorkingColorSpace: NSNull()])
                }
                var bounds: CGSize = (enhancedImage!.extent.size)
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
                free(byteBuffer)
                if imgRef == nil {
                    return
                }
                self.saveCGImageAsJPEGToFilePath(imgRef: imgRef!, filePath: fullPath)
                DispatchQueue.main.async(execute: {() -> Void in
                    completionHandler(fullPath)
                    self.captureQueue?.resume()
                })
                self.imageDedectionConfidence = 0.0
            }
        }
    }
    func saveCGImageAsJPEGToFilePath(imgRef: CGImage, filePath: String){
        autoreleasepool {
            let url: CFURL? = (URL(fileURLWithPath: filePath) as CFURL?)
            let destination: CGImageDestination = CGImageDestinationCreateWithURL(url!, kUTTypeJPEG, 1, nil)!
            CGImageDestinationAddImage(destination, imgRef, nil)
            CGImageDestinationFinalize(destination)
        }
    }
    func hideGLKView(_ hidden: Bool, completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.1, animations: {() -> Void in
            self.glkView?.alpha = (hidden) ? 0.0 : 1.0
        }, completion: {(_ finished: Bool) -> Void in
            
            completion()
        })
    }
    // Mark Camera filters
    // Todo add more filters
    func sepiaTone(on image: CIImage) -> CIImage {
        return CIFilter(name: "CIColorPosterize", withInputParameters: [kCIInputImageKey: image])!.outputImage!
    }
    func blackAndWhiteFilter(on image: CIImage) -> CIImage {
        return CIFilter(name: "CIColorControls", withInputParameters: ["inputContrast": (1.0), "inputBrightness" : (0.0), "inputSaturation": (0.0), kCIInputImageKey: image])!.outputImage!
    }
    func colorFilter(on image: CIImage) -> CIImage {
        return CIFilter(name: "CIColorControls", withInputParameters: ["inputContrast": (1.0), kCIInputImageKey: image])!.outputImage!
    }
    func correctPerspective(for image: CIImage, withFeatures rectangleFeature: CIRectangleFeature) -> CIImage {
        var rectangleCoordinates = [AnyHashable: Any]()
        rectangleCoordinates["inputTopLeft"] = CIVector(cgPoint: rectangleFeature.topLeft)
        rectangleCoordinates["inputTopRight"] = CIVector(cgPoint: rectangleFeature.topRight)
        rectangleCoordinates["inputBottomLeft"] = CIVector(cgPoint: rectangleFeature.bottomLeft)
        rectangleCoordinates["inputBottomRight"] = CIVector(cgPoint: rectangleFeature.bottomRight)
        return image.applyingFilter("CIPerspectiveCorrection", withInputParameters: ["inputTopLeft": CIVector(cgPoint: rectangleFeature.topLeft), "inputTopRight": CIVector(cgPoint: rectangleFeature.topRight), "inputBottomLeft": CIVector(cgPoint: rectangleFeature.bottomLeft), "inputBottomRight": CIVector(cgPoint: rectangleFeature.bottomRight)])
    }
    /*
     // This function isn't used
     func rectangleDetector() -> CIDetector {
     let options: [String: Any] = [CIDetectorAccuracy: CIDetectorAccuracyLow, CIDetectorAspectRatio: 2.0]
     return CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: options)!
     }
     */
    func highAccuracyRectangleDetector() -> CIDetector {
        let options: [String: Any] = [CIDetectorAccuracy:  CIDetectorAccuracyHigh, CIDetectorAspectRatio: 2.0, CIDetectorTracking: 1.0]
        return CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: options)!
    }
    func bigRectangle(rectangles: [Any]) -> CIRectangleFeature {
        var halfPerimiterValue: Float = 0
        var biggestRectangles: CIRectangleFeature? = rectangles.first as! CIRectangleFeature?
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
                biggestRectangles = rect
            }
        }
        return biggestRectangles!
    }
    /*
     // This function isn't used
     func performRectangleDetection(_ image: CIImage) -> CIImage? {
        var resultImage: CIImage?
        if let detector = detector {
            // Get the detections
            let features = detector.features(in: image)
            for feature in features as! [CIRectangleFeature] {
            if self.isEnableBorderDetection == true {
                resultImage = self.drawHighlightOverlay(forPoints: image, topLeft: feature.topLeft, topRight: feature.topRight, bottomLeft: feature.bottomLeft, bottomRight: feature.bottomRight)
                    }
                }
            }
        return resultImage
     }
     */
    func biggestRectangle(rectangles: [Any]) -> CIRectangleFeature {
        if (rectangles.count > 0) {
            let rectangleFeature: CIRectangleFeature? = self.bigRectangle(rectangles: rectangles )
            let points = [
                rectangleFeature?.topLeft,
                rectangleFeature?.topRight,
                rectangleFeature?.bottomLeft,
                rectangleFeature?.bottomRight
            ]
            
            var minimum = points[0]
            var maximum = points[0]
            for point in points {
                minimum?.x = min((minimum?.x)!, (point?.x)!)
                minimum?.y = min((minimum?.y)!, (point?.y)!)
                maximum?.x = max((maximum?.x)!, (point?.x)!)
                maximum?.y = max((maximum?.y)!, (point?.y)!)
            }
            let center = CGPoint(x: ((minimum?.x)! + (maximum?.x)!) / 2, y: ((minimum?.y)! + (maximum?.y)!) / 2)
            let angle = { (point: CGPoint!) -> CGFloat in
                let theta = atan2(point.y - center.y, point.x - center.x)
                return fmod(.pi * 3.0 / 4.0 + theta, 2 * .pi)
            }
            let sortedPoints = points.sorted { angle($0) < angle($1)}
            
            let rectangleFeatureMutable = DocScannerRectangleFeature()
            rectangleFeatureMutable.topL = sortedPoints[3]!
            rectangleFeatureMutable.topR = sortedPoints[2]!
            rectangleFeatureMutable.bottomR = sortedPoints[1]!
            rectangleFeatureMutable.bottomL = sortedPoints[0]!
            return rectangleFeatureMutable
        }
        else {
            return CIRectangleFeature()
        }
    }
    func rectangleDetectionConfidenceHighEnough(confidence: CGFloat) -> Bool {
        return (confidence > 1.0)
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
        if self.isForceStop == true{
            return
        }
        if (self.isStopped == true || self.isCapturing == true || !CMSampleBufferIsValid(sampleBuffer!)) {
            return
        }
        let pixelBuffer: CVPixelBuffer? = (CMSampleBufferGetImageBuffer(sampleBuffer!)! )
        var image = CIImage(cvPixelBuffer: pixelBuffer!)
        if self.cameraViewType == DocScannerCameraViewType.blackAndWhite {
            image = self.blackAndWhiteFilter(on: image)
        }
        if self.cameraViewType == DocScannerCameraViewType.normal {
            image = self.colorFilter(on: image)
        }
        if self.cameraViewType == DocScannerCameraViewType.sepiaTone{
            image = self.sepiaTone(on: image)
        }
        if self.enableBorderDetection == true{
            if self.borderDetectFrames == true {
                let features = self.highAccuracyRectangleDetector().features(in: image)
                self.borderDetectLastRectangleFeature = self.biggestRectangle(rectangles: features)
                if ((self.borderDetectLastRectangleFeature) != nil) {
                    self.imageDedectionConfidence += 0.5
                    for feature in features as! [CIRectangleFeature] {
                        image = self.drawHighlightOverlay(forPoints: image, topLeft: (feature.topLeft), topRight: (feature.topRight), bottomLeft: (feature.bottomLeft), bottomRight: (feature.bottomRight))
                    }
                }
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
            self.coreImageContext?.draw(image, in: self.bounds, from: self.cropRect(forPreviewImage: image))
            self.glkView?.display()
            if self.intrinsicContentSizes.width != image.extent.size.width {
                self.intrinsicContentSizes = image.extent.size
                DispatchQueue.main.async(execute: {() -> Void in
                    self.invalidateIntrinsicContentSize()
                })
            }
            
        }
    }
    /*
     // This function isn't used
     func _intrinsicContentSize() -> CGSize {
     if self.intrinsicContentSizes.width == 0 || self.intrinsicContentSizes.height == 0 {
     return CGSize(width: CGFloat(1), height: CGFloat(1))
     //just enough so rendering doesn't crash
     }
     return self.intrinsicContentSizes
     }
     */
    func drawHighlightOverlay(forPoints image: CIImage, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) -> CIImage {
        var overlay = CIImage(color: CIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.4))
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
    func enableBorderDetectFrame() {
        self.borderDetectFrames = true
    }
}
