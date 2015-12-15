//
//  ViewController.swift
//  WatsonSDKTokenFetch
//
//  Created by Robert Dickerson on 12/8/15.
//  Copyright © 2015 Robert Dickerson. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {

    @IBOutlet weak var tokenLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (FBSDKAccessToken.currentAccessToken() != nil) {
                // User already logged in.
            
            print("User already logged in with token \(FBSDKAccessToken.currentAccessToken().tokenString)")
            
            let translateController = self.storyboard?
                .instantiateViewControllerWithIdentifier("TranslateController") as? TranslateViewController
            self.navigationController?.pushViewController(translateController!, animated: true)
            
            // tokenLabel.text = FBSDKAccessToken.currentAccessToken().tokenString
            
        } else { }
        
        let loginView: FBSDKLoginButton = FBSDKLoginButton()
        
        self.view.addSubview(loginView)
        loginView.center = self.view.center
        loginView.center.y += 20
        loginView.readPermissions = ["public_profile", "email", "user_friends"]
        loginView.delegate = self

        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Facebook Delegate Methods
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        
        let token = FBSDKAccessToken.currentAccessToken()
        print("User logged in with token: \(token.tokenString)")
        
        let translateController = self.storyboard?.instantiateViewControllerWithIdentifier("TranslateController") as? TranslateViewController
        self.navigationController?.pushViewController(translateController!, animated: true)
        
        // tokenLabel.text = FBSDKAccessToken.currentAccessToken().tokenString
        
        if ((error) != nil)
        {
            // Process error
        }
        else if result.isCancelled {
            // Handle cancellations
        }
        else {
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            if result.grantedPermissions.contains("email")
            {
                // Do work
            }
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("User Logged Out")
        
        // tokenLabel.text = ""
    }


}

