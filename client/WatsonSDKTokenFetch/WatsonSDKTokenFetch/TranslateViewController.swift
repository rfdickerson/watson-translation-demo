/**
 * Copyright IBM Corporation 2015
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation
import UIKit
import AVFoundation

import WatsonSDK

class TranslateViewController: UIViewController, AVAudioRecorderDelegate {
    
    var sttService: SpeechToText?
    var ttsService: TextToSpeech?
    var translateService: LanguageTranslation?
    
    var player: AVAudioPlayer? = nil
    var recorder: AVAudioRecorder!
    

    @IBOutlet weak var languageTable: UITableView!
    
    @IBAction func clickMicrophone(sender: AnyObject) {
        
        startStopRecording()
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        initRecorder()
        initSpeechRec()
        initSpeechSynthesis()
        initTranslateService()
        
        // testTranslation("The tall boy jumped over the red dog.")
        
        translateService?.getIdentifiableLanguages() {
            languages, error in
            
            
            // print (languages)
        }
        
    }
    
    func initTranslateService() {
        
        let token: String = FBSDKAccessToken.currentAccessToken().tokenString
        
        let fbAccess = FacebookAuthenticationStrategy(
            tokenURL: "https://watsonsdkdemo.mybluemix.net/language-translation-service/api/v1/token",
            fbToken: token)
        
        translateService = LanguageTranslation(authStrategy: fbAccess)
        //translateService = LanguageTranslation(
        //    username: "1b029359-ffe7-4b40-9bac-3bdcd94f626f",
        //    password: "ny8tRyFfNASZ"
        //)
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
        
        //ttsService = TextToSpeech(username: "e08066f7-a27f-4732-8d10-ac7895d0a9b4",
        //    password: "bXNBDOHvKUXE")
        
        

    }
    
    func startStopRecording() {
        
        guard let recorder = recorder else {
            print("Recorder not properly set up.")
            return
        }
        
        if let player = player {
            if (player.playing) {
                player.stop()
            }
        }
        
        if (!recorder.recording) {
            do {
                print("Starting recording...")
                let session = AVAudioSession.sharedInstance()
                try session.setActive(true)
                recorder.record()
                //startStopRecordingButton.setTitle("Stop Recording", forState: .Normal)
                //playRecordingButton.enabled = false
                //transcribeButton.enabled = false
            } catch {
                print("Error setting session active.")
            }
        } else {
            do {
                print("Stopping recording...")
                recorder.stop()
                let session = AVAudioSession.sharedInstance()
                try session.setActive(false)
                
                transcribe()
                
                //startStopRecordingButton.setTitle("Start Recording", forState: .Normal)
                //playRecordingButton.enabled = true
                //transcribeButton.enabled = true
            } catch {
                print("Error setting session inactive.")
            }
        }
        
    }
    
    func transcribe() {
        
        guard let recorder = recorder else {
            print("Recorder not properly set up.")
            return
        }
        
        print("Transcribing recording...")
        
        if let sttService = sttService {
            
            let data = NSData(contentsOfURL: recorder.url)
            
            if let data = data {
                sttService.transcribe(data , format: .WAV, oncompletion: {
                    
                    response, error in
                    
                    // print(response)
                    
                    if let response = response {
                        self.testTranslation(response.transcription())
                    }
                    
                    
                    //self.transcriptionField.text = response?.transcription()
                    
                })
            } else {
                Log.sharedLogger.error("Could not find data at \(recorder.url)")
            }
            
        }
    }

    
    func testTranslation(text: String) {
        
        if let translator = translateService {
            
            translator.translate([text],source:"en",target:"es") {
            
            results, error in
                
                print ("translation: \(error)")
            
                if let results = results {
                    
                    print(results)
                    
                    self.playAudio(results[0])
                    
                }
            
                
            }
        }
        
    }
    
    func playAudio(text: String) {
        
        if let tts = ttsService {
            
            tts.synthesize(text, voice: "es-US_SofiaVoice") {
                
            data, error in
            
            if let data = data {
                
                do {
                    self.player = try AVAudioPlayer(data: data)
                    self.player!.play()
                    
                    
                } catch { }
            }
        }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
}