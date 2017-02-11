//
//  fileDirectory.swift
//  iScan
//
//  Created by William Thompson on 1/28/17.
//  Copyright © 2017 William Thompson. All rights reserved.
//

import UIKit
class fileDirectory {
    func listFile(atPath path: String) -> [Any] {
        //-----> LIST ALL FILES <-----//
        print("LISTING ALL FILES FOUND")
        var count: Int
        var directoryContent: [Any]? = (try? FileManager.default.contentsOfDirectory(atPath: path))
        for count in 0..<Int((directoryContent?.count)!) {
            print("File \(count + 1): \(directoryContent?[count])")
        }
        return directoryContent!
    }
}
