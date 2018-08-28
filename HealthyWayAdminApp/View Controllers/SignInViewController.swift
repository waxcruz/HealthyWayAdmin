//
//  ViewController.swift
//  LearnFirebaseAuthenticationAndAuthorization
//
//  Created by Bill Weatherwax on 8/19/18.
//  Copyright © 2018 waxcruz. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase

class SignInViewController: UIViewController {
    // MARK - properties

    var emailEntered : String?
    var passwordEntered : String?

    
    // MARK - Sign-in fields
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var message: UITextView!

    
    // MARK - Firebase properties
    var ref: DatabaseReference!
    var handle: AuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        email.addTarget(self, action: #selector(SignInViewController.textFieldDidEnd(_:)), for: UIControlEvents.editingDidEndOnExit)
        password.addTarget(self, action: #selector(SignInViewController.textFieldDidEnd(_:)), for: UIControlEvents.editingDidEndOnExit)
        message.textContainer.lineBreakMode = NSLineBreakMode.byWordWrapping
        email.text = "wmyronw@yahoo.com"
        password.text = "waxwax"

    }

    @objc func textFieldDidEnd(_ textField: UITextField){
        textField.resignFirstResponder()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            // ...
            NSLog("user sign-in state changed")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handle!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK - actions
    @IBAction func login(_ sender: Any) {
        email.resignFirstResponder()
        password.resignFirstResponder()
        if Auth.auth().currentUser != nil {
            do {
                try Auth.auth().signOut()
            } catch {
                print("Sign out failed")
            }
        }
        emailEntered = email.text
        passwordEntered = password.text
        Auth.auth().signIn(withEmail: emailEntered!, password: passwordEntered!) { (user, error) in
            // ...
            if user == nil {
                self.message.text = error?.localizedDescription
            } else {
                self.getUserData()
            }
        }
    }
    
    @IBAction func unwindToSignInViewController(segue:UIStoryboardSegue) { }
    
    
    
    // MARK - process data
    func getUserData() {
        // let userID = Auth.auth().currentUser?.uid
        ref.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
//            print("entering firebase return of data")
//            if let value = snapshot.value as? NSDictionary {
//                for (key, email) in value {
//                    print(key, email)
//                }
//            }
            self.performSegue(withIdentifier: Constants.SEGUE_FROM_SIGNIN_TO_CLIENT_ID, sender: nil)
        })
        { (error) in
            self.message.text = error.localizedDescription + " attempting to access users"
        }
        
    }
}

