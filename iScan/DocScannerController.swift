//
//  DocScannerController.swift
//  iScan
//
//  Created by William Thompson on 1/28/17.
//  Copyright © 2017 William Thompson. All rights reserved.
//

import UIKit
import QuartzCore

class DocScannerController: UIViewController {
    var imagesDirectoryPath:String!
    var images: UIImage!
    var titles:[String]!
    var captureDevice: AVCaptureDevice?
    
    
    
    @IBOutlet weak var cameraViewController: DocScannerViewController!
    @IBOutlet weak var focusIndicator: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var torchToggle: UIButton!
    
    @IBOutlet weak var stackView: UIStackView!
    
   
    @IBOutlet weak var captureButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.cameraViewController.setupCameraView()
        self.cameraViewController.isBorderDetectionEnabled = true
        self.updateTitleLabel()
        view.bringSubview(toFront: cameraViewController)
        self.focusIndicator.isHidden = true
        
        // Do any additional setup after loading the view.
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    override func viewDidAppear(_ animated: Bool) {
        self.cameraViewController?.start()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func focusGesture(_ sender: UITapGestureRecognizer) {
        
            let location = sender.location(in: self.cameraViewController)
            self.focusIndicatorAnimateToPoint(targetPoint: location)
            self.cameraViewController.focus(at: location, completionHandler: {() -> Void in
                self.focusIndicatorAnimateToPoint(targetPoint: location)
            })
        
    
    
    }
    func focusIndicatorAnimateToPoint(targetPoint: CGPoint) {
        (self.focusIndicator).center = targetPoint
        self.focusIndicator.alpha = 0.0
        self.focusIndicator.isHidden = false
        UIView.animate(withDuration: 0.4, animations: {() -> Void in
            self.focusIndicator.alpha = 1.0
        }, completion: {(finished: Bool) -> Void in
            UIView.animate(withDuration: 0.4, animations: {() -> Void in
                self.focusIndicator.alpha = 0.0
            })
        })
    }
    
    
    
    
    
    
    func changeButton(button: UIButton, targetTitle title: String, toStateEnabled enabled: Bool) {
        button.setTitle(title, for: .normal)
        button.setTitleColor((enabled) ? UIColor(red: 1, green: 0.81, blue: 0, alpha: 1) : UIColor.white, for: .normal)
    }
    @IBAction func captureButton(_ sender: Any) {
        weak var weakSelf = self
        self.cameraViewController.captureImage(completionHander: {(fullPath) -> Void in
            let captureImageView: UIImageView = UIImageView(image: UIImage(contentsOfFile:(fullPath)!))
            
            captureImageView.backgroundColor = UIColor(white: 0.0, alpha: 0.7);
            captureImageView.frame = (weakSelf?.view.bounds.offsetBy(dx: 0, dy: -(weakSelf?.view.bounds.size.height)!))!;
            captureImageView.alpha = 1.0;
            captureImageView.contentMode = .scaleAspectFit;
            captureImageView.isUserInteractionEnabled = true;
            weakSelf?.view!.addSubview(captureImageView)
            let dismissTap: UITapGestureRecognizer = UITapGestureRecognizer(target: weakSelf, action: #selector(self.dismissPreview))
            captureImageView.addGestureRecognizer(dismissTap)
            UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.7, options: .allowUserInteraction, animations: {() -> Void in
                captureImageView.frame = (weakSelf?.view.bounds)!
            }, completion: { _ in })
        })
    }
    func dismissPreview(_ dismissTap: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: .allowUserInteraction, animations: {() -> Void in
            dismissTap.view?.frame = self.view.bounds.offsetBy(dx: CGFloat(0), dy: CGFloat(self.view.bounds.size.height))
        }, completion: {(_ finished: Bool) -> Void in
            dismissTap.view?.removeFromSuperview()
        })
    }
    func updateTitleLabel() {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        animation.type = kCATransitionPush
        animation.subtype = kCATransitionFromBottom
        animation.duration = 0.35
        self.titleLabel!.layer.add(animation, forKey: "kCATransitionFade")
        let filterMode = (self.cameraViewController.cameraViewType == .blackAndWhite) ? "TEXT FILTER" : "COLOR FILTER"
        self.titleLabel!.text! = filterMode.appendingFormat(" | %@", (self.cameraViewController.isBorderDetectionEnabled) ? "AUTOCROP On" : "AUTOCROP Off")
    }
    @IBAction func torchToggle(_ sender: Any) {
        let enabled: Bool = !self.cameraViewController.isTorchEnabled
    self.cameraViewController.isTorchEnabled = enabled
        self.changeButton(button: sender as! UIButton, targetTitle: (enabled) ? "FLASH On" : "FLASH Off", toStateEnabled: enabled)
    }
    
    @IBAction func filterToggle(_ sender: Any) {
    (self.cameraViewController).cameraViewType = (self.cameraViewController.cameraViewType == DocScannerCameraViewType.blackAndWhite) ? DocScannerCameraViewType.normal : DocScannerCameraViewType.blackAndWhite
        self.updateTitleLabel()
        
    }
    @IBAction func borderDetectToggle(_ sender: Any) {
    let enable: Bool = !self.cameraViewController.isBorderDetectionEnabled
    self.cameraViewController.isBorderDetectionEnabled = enable
    self.updateTitleLabel()
        self.changeButton(button: sender as! UIButton, targetTitle: (enable) ? "CROP On" : "CROP Off", toStateEnabled: enable)
    }
    
    @IBAction func doneAction(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
