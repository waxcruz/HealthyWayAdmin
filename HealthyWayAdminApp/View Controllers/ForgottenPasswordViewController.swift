//
//  ForgottenPasswordViewController.swift
//  LearnFirebaseAuthenticationAndAuthorization
//
//  Created by Bill Weatherwax on 8/21/18.
//  Copyright © 2018 waxcruz. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase

class ForgottenPasswordViewController: UIViewController {
    // MARK - properties
    var emailEntered : String?
    var hwClientPasswordEntered : String?
    var newPasswordEntered : String?
    var confirmPasswordEntered : String?
    
    // MARK - Sign-in fields
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var message: UITextView!
    
    // MARK - Firebase properties
    var ref: DatabaseReference!
    var handle: AuthStateDidChangeListenerHandle?

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        email.addTarget(self, action: #selector(ForgottenPasswordViewController.textFieldDidEnd(_:)), for: UIControlEvents.editingDidEndOnExit)
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
        message.text = Constants.NOTICE_RESET_PASSWORD
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func signIn(_ sender: Any) {
        email.resignFirstResponder()
        message.text = ""
        if Auth.auth().currentUser != nil {
            do {
                try Auth.auth().signOut()
            } catch {
                print("ForgottenPasswordViewController, Sign out failed")
            }
        }
        emailEntered = email.text
        // temporary check until Chel decides how to reset passwords
        Auth.auth().sendPasswordReset(withEmail: emailEntered!) { (error) in
            // error
            if let error = error {
                self.message.text = "Reset email failure: \(error.localizedDescription)"
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }


    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
