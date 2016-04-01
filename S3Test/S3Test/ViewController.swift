//
//  ViewController.swift
//  S3Test
//
//  Created by Sean Calkins on 3/31/16.
//  Copyright © 2016 Sean Calkins. All rights reserved.
//

import UIKit
import Firebase
import AmazonS3RequestManager
import AVFoundation

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    //MARK: - Audio Recorder and player instances
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    
    @IBOutlet weak var tableView: UITableView!
    
    //Properties
    var arrayOfAudioFiles = [AudioFile]()
    
    var currentAudioFile = AudioFile()
    
    let ref = Firebase(url: "https://watchosapp.firebaseio.com/audiofiles")
    
    let amazonS3Manager = AmazonS3RequestManager(bucket: "tiycourse-contentdelivery-mobilehub-1603932612",
                                                 region: .USStandard,
                                                 accessKey: "AKIAIQWXUAGVEWNQI77Q",
                                                 secret: "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")
    
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.observeAudioFiles()
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return arrayOfAudioFiles.count
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let f = arrayOfAudioFiles[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("Audio File Cell", forIndexPath: indexPath )
        cell.textLabel?.text = f.title
        return cell
        
    }
    
    //MARK: - Did select table view cell
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        //grab audio file from array and creates a new instance of it's filepath
        let f = arrayOfAudioFiles[indexPath.row]
        self.currentAudioFile = arrayOfAudioFiles[indexPath.row]
        
        self.playAudio(f.filePath)
        
        print(f.filePath)
        
    }
    
    //MARK: - Grabs documents directory
    func getDocumentsDirectory() -> NSURL {
        
        return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        
    }
    
    //MARK: - Observer
    func observeAudioFiles() {
        
        // Add observer for Audio Files
        
        self.ref.observeEventType(.Value, withBlock: { snapshot in
            
            print(snapshot.value)
            
            self.arrayOfAudioFiles.removeAll()
            
            if let snapshots = snapshot.children.allObjects as? [FDataSnapshot] {
                
                for snap in snapshots {
                    
                    if let dict = snap.value as? [String: AnyObject] {
                        
                        let key = snap.key
                        print(key)
                        let file = AudioFile(key: key, dict: dict)
                        
                        print(file.title)
                        print(file.filePath)
                        
                        self.arrayOfAudioFiles.insert(file, atIndex: 0)
                        print(self.arrayOfAudioFiles.count)
                        self.tableView.reloadData()
                        
                    }
                }
            }
        })
    }
    
    //MARK: - Record Button
    @IBAction func recordTapped(sender: UIButton) {
        
        startNewAudioFile()
        self.tableView.reloadData()
        
    }
    
    //MARK: - Pause Button
    @IBAction func pauseTapped(sender: UIButton) {
        
        if let recorder = audioRecorder {
            
            recorder.pause()
            
        }
        
    }
    
    //MARK: - Stop Tapped
    @IBAction func stopTapped(sender: UIButton) {
        
        if let recorder = audioRecorder {
            
            recorder.stop()
            
        }
        
    }
    
    
    //MARK: - Create a new audiofile
    func startNewAudioFile() {
        
        let today = NSDate()
        let timestamp = today.timeIntervalSince1970
        
        //Creates a new audiofile with a timeStamp in the filepath url and adds it to array
        self.currentAudioFile = AudioFile()
        
        self.currentAudioFile.title = "\(timestamp)"
        
        self.currentAudioFile.filePath = self.getDocumentsDirectory()
        
        self.arrayOfAudioFiles.append(self.currentAudioFile)
        
        self.currentAudioFile.save()
        
        amazonS3Manager.putObject(self.getDocumentsDirectory(), destinationPath: self.currentAudioFile.title)
        
        let filePath = self.createFilePath(self.currentAudioFile.filePath, title: self.currentAudioFile.title)
        print(filePath)
        
        //Starts new audio session with new audiofile url
        startSessionWithFilePath(filePath)
        
    }
    
    //MARK: - Start audio session
    func startSessionWithFilePath(filePath: NSURL) {
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            //Trys to create a new audio session, if it doesn't work print error
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: AVAudioSessionCategoryOptions.DefaultToSpeaker)
            
            let recorderSetting: [String: AnyObject] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.High.rawValue
            ]
            
            //Records new audio into current audiofile url
            self.audioRecorder = try AVAudioRecorder(URL: filePath, settings: recorderSetting)
            self.audioRecorder?.delegate = self
            self.audioRecorder?.prepareToRecord()
            self.audioRecorder?.record()
            
        } catch {
            print(error)
        }
        
    }
    
    func createFilePath(filePath: NSURL, title: String) -> NSURL {
        return filePath.URLByAppendingPathComponent(title)
    }
    
    func playAudio(filePath: NSURL) {
        
        print(filePath)
        
        do {
            
            //Plays that audio file from filepath using AVAudioPlayer
            audioPlayer = try AVAudioPlayer(contentsOfURL: filePath)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            
        } catch {
            print(error)
        }
    }
    
}

