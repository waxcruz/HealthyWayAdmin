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
    var handle: AuthStateDidChangeListenerHandle?
    var emailEntered : String?
    var passwordEntered : String?
    var newPasswordEntered : String?
    
    // MARK - Sign-in fields
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var message: UITextView!

    
    // MARK - Firebase properties
    var ref: DatabaseReference!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        email.addTarget(self, action: #selector(SignInViewController.textFieldDidEnd(_:)), for: UIControlEvents.editingDidEndOnExit)
        password.addTarget(self, action: #selector(SignInViewController.textFieldDidEnd(_:)), for: UIControlEvents.editingDidEndOnExit)
        message.textContainer.lineBreakMode = NSLineBreakMode.byWordWrapping

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
    
    @IBAction func createNewAccount(_ sender: Any) {
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
        Auth.auth().createUser(withEmail: emailEntered!, password: passwordEntered!) { (authResult, error) in
            // ...
            guard let user = authResult?.user else { return }
            // write to users node
            self.ref.child("users").child(user.uid).setValue(["email": self.emailEntered!, "isAdmin": true]) {
                (error:Error?, ref:DatabaseReference) in
                if let error = error {
                    print("Data could not be saved: \(error).")
                } else {
                    print("Data saved successfully!")
                }
            }
        }
    }
    
    @IBAction func forgottenPassword(_ sender: Any) {
        Auth.auth().sendPasswordReset(withEmail: self.emailEntered!, completion: { (error) in
            // ...
            if let checkForProblem = error {
                print("Reset email error: \(error).")
            } else {
                print("Reset email sent")
            }
        })
    }
    
    
    // MARK - process data
    func getUserData() {
        // let userID = Auth.auth().currentUser?.uid
        ref.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            print("entering firebase return of data")
            if let value = snapshot.value as? NSDictionary {
                for (key, email) in value {
                    print(key, email)
                }
            }
        })
        { (error) in
            self.message.text = error.localizedDescription + " attempting to access users"
        }
        
    }
}

