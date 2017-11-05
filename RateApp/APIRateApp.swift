//
//  APIRateApp.swift
//  RateApp
//
//  Created by  William Thompson on 11/4/17.
//  Copyright © 2017 William Thompson. All rights reserved.
//

import UIKit
import StoreKit

let appLaunches = "co.jwenterprises.carpentryplus25.applaunches"
let appLaunchesChanged = "co.jwenterprises.carpentryplus25.applaunches.changed"
let appInstallDate = "co.jwenterprises.carpentryplus25.install_date"
let appRatingShown = "co.jwenterprises.carpentryplus25.app_rating_shown"

@objc public class APIRateApp: NSObject, UIAlertViewDelegate{
    var application: UIApplication!
    var userDefaults = UserDefaults()
    let requiredNumberOfLaunchesBeforeRating = 2
    public var appID: String!
    
    @objc public static var sharedInstance = APIRateApp()
    
    //Mark: Initialization
    override init() {
        super.init()
        setup()
    }
    
    func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(appFinishedLaunching(_:)), name: NSNotification.Name.UIApplicationDidFinishLaunching, object: nil)
    }
    
    //Mark: Notification Observers
    @objc func appFinishedLaunching(_ notification: NSNotification){
        if let _application = notification.object as? UIApplication {
            self.application = _application
            displayRatingsPromptIfRequired()
        }
    }
    
    //Mark: App launch count
    func getAppLaunchCount() -> Int {
        let launches = userDefaults.integer(forKey: appLaunches)
        return launches
    }
    
    func incrementAppLaunchCount() {
        var launches = userDefaults.integer(forKey: appLaunches)
        launches += 1
        userDefaults.set(launches, forKey: appLaunches)
        userDefaults.synchronize()
    }
    
    func resetAppLaunchCount() {
        userDefaults.set(0, forKey: appLaunches)
        userDefaults.synchronize()
    }
    
    func setFirstLaunchDate(){
        userDefaults.set(true, forKey: appInstallDate)
        userDefaults.synchronize()
    }
    
    func getFirstLaunchDate() -> NSDate {
        if let date = userDefaults.value(forKey: appInstallDate) as? NSDate {
            return date
        }
        return NSDate()
    }
    
    //Mark: App rating shown
    func setAppRatingShown(){
        userDefaults.set(true, forKey: appRatingShown)
        userDefaults.synchronize()
    }
    
    func hasShownAppRateing() -> Bool {
        let shown = userDefaults.bool(forKey: appRatingShown)
        return shown
        
    }
    
    // Mark: App Rating
    private func displayRatingsPromptIfRequired() {
        let appLaunchCount = getAppLaunchCount()
        if appLaunchCount >= self.requiredNumberOfLaunchesBeforeRating {
            if #available(iOS 10.3, *) {
                rateApp()
            }
            else {
                rateTheApp()
            }
        }
        incrementAppLaunchCount()
    }
    
    @available(iOS 10.3, *)
    private func rateApp() {
        SKStoreReviewController.requestReview()
        setAppRatingShown()
    }
    
    @available(iOS 8.0, *)
    private func rateTheApp() {
        let appName = Bundle(for: type(of: application.delegate!)).infoDictionary!["CFBundleName"] as? String
        let message = "Enjoying \(appName!) app? Please rate \(appName!)!"
        let rateAlert = UIAlertController(title: "Rate \(appName!)", message: message, preferredStyle: .alert)
        let goToAppStore = UIAlertAction(title: "Rate", style: .default, handler: { (action) -> Void in
            let url = NSURL(string: "itms-apps://itunes.apple.com/app/id\(self.appID)")
            UIApplication.shared.openURL(url! as URL)
            
            self.setAppRatingShown()
        })
        let cancelAction = UIAlertAction(title: "Not now", style: .cancel, handler: { (action) -> Void in
            self.resetAppLaunchCount()
        })
        
        rateAlert.addAction(goToAppStore)
        rateAlert.addAction(cancelAction)
        
        DispatchQueue.main.async(execute: { () -> Void in
            let window = self.application.windows[0]
            window.rootViewController?.present(rateAlert, animated: true, completion: nil)
            
        })
    }
    
    // Mark: versions older than iOS 8.0 likely to remove support later
    private func rateTheAppOldVersion() {
        let appName = Bundle(for: type(of: application.delegate!)).infoDictionary!["CFBundleName"] as? String
        let message = "Enjoying \(appName!) app? Please rate \(appName!)!"
        let alert = UIAlertView(title: "Rate \(appName!)", message: message, delegate: self, cancelButtonTitle: "Not now", otherButtonTitles: "Rate")
        alert.show()
    }
    
    @objc public func alertViewCancel(_ alertView: UIAlertView) {
        self.resetAppLaunchCount()
    }
    
    @objc public func alertView(_ alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        setAppRatingShown()
        let url = NSURL(string: "itms-apps://itunes.apple.com/app/id\(self.appID)")
        UIApplication.shared.openURL(url! as URL)
        
    }

}
