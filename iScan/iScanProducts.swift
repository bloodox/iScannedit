//
//  iScanProducts.swift
//  
//
//  Created by William Thompson on 5/21/17.
//  Copyright © 2017 J.W.Enterprises LLC. All rights reserved.
//

import Foundation

public struct iScanProducts {
    
    public static let RemoveAds = "com.CarpenterBlood.iScan.RemoveAds"
    
    fileprivate static let productIdentifiers: Set<ProductIdentifier> = [iScanProducts.RemoveAds]
    
    public static let store = IAPHelper(productIds: iScanProducts.productIdentifiers)
}

func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
    return productIdentifier.components(separatedBy: ".").last
}
