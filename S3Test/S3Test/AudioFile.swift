//
//  AudioFile.swift
//  S3Test
//
//  Created by Sean Calkins on 3/31/16.
//  Copyright © 2016 Sean Calkins. All rights reserved.
//

import Foundation
import Firebase
import AmazonS3RequestManager

class AudioFile {
    
    let amazonS3Manager = AmazonS3RequestManager(bucket: "tiycourse-contentdelivery-mobilehub-1603932612",
                                                 region: .USStandard,
                                                 accessKey: "AKIAIQWXUAGVEWNQI77Q",
                                                 secret: "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")
    
    let firebaseRef = Firebase(url: "https://watchosapp.firebaseio.com/audiofiles")
    var ref: Firebase?
    var title: String = ""
    var filePath = NSURL()
    
    init(){}
    
    init(key: String, dict: [String: AnyObject]) {
        
        self.ref = Firebase(url: "https://watchosapp.firebaseio.com/audiofiles/\(key)")
        
        if let title = dict["title"] as? String {
            
            self.title = title
            
        }
        
        self.filePath = getDocumentsDirectory().URLByAppendingPathComponent(self.title)
        
        amazonS3Manager.downloadObject(self.title, saveToURL: self.filePath)
        
    }
    
    func getDocumentsDirectory() -> NSURL {
        
        return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        
    }
    
    func save() {
        
           print("saving with title \(self.title)")
            
            let dict = [
                
                "title": self.title
    
            ]
            
            let firebaseEvent = self.firebaseRef.childByAutoId()
            firebaseEvent.setValue(dict)
        
    }
    
}