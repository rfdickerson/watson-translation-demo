//
//  TranslateViewController.swift
//  WatsonSDKTokenFetch
//
//  Created by Robert Dickerson on 12/13/15.
//  Copyright © 2015 Robert Dickerson. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

import WatsonSDK

class TranslateViewController: UIViewController, AVAudioRecorderDelegate {
    
    var sttService: SpeechToText?
    var ttsService: TextToSpeech?
    
    var player: AVAudioPlayer? = nil
    var recorder: AVAudioRecorder!
    
    @IBOutlet weak var languageTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        initRecorder()
        //initSpeechRec()
        initSpeechSynthesis()
        
        
    }
    
    func initRecorder() {
        
        // create file to store recordings
        let filePath = NSURL(fileURLWithPath: "\(NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0])/SpeechToTextRecording.wav")
        
        // set up session and recorder
        let session = AVAudioSession.sharedInstance()
        var settings = [String: AnyObject]()
        // settings[AVFormatIDKey] = NSNumber(unsignedInt: kAudioFormatMPEG4AAC)
        settings[AVSampleRateKey] = NSNumber(float: 44100.0)
        settings[AVNumberOfChannelsKey] = NSNumber(int: 1)
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
            recorder = try AVAudioRecorder(URL: filePath, settings: settings)
        } catch {
            print("Error setting up session or recorder.")
        }
        
        // ensure recorder is set up
        guard let recorder = recorder else {
            print("Could not set up recorder.")
            return
        }
        
        // prepare recorder to record
        recorder.delegate = self
        recorder.meteringEnabled = true
        recorder.prepareToRecord()

    }
    
    func initSpeechRec() {
        
        let token: String = FBSDKAccessToken.currentAccessToken().tokenString
        
        let fbAccess = FacebookAuthenticationStrategy(
            tokenURL: "https://watsonsdkdemo.mybluemix.net/speech-to-text-service/api/v1/token",
            fbToken: token)
        
        sttService = SpeechToText(authStrategy: fbAccess)
    }
    
    func initSpeechSynthesis() {
        
        let token: String = FBSDKAccessToken.currentAccessToken().tokenString
        
        let fbAccess = FacebookAuthenticationStrategy(
            tokenURL: "https://watsonsdkdemo.mybluemix.net/text-to-speech-service/api/v1/token",
            fbToken: token)
        
        ttsService = TextToSpeech(authStrategy: fbAccess)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
}