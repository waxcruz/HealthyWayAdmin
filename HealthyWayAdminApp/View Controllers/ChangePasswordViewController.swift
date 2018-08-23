//
//  ChangePasswordViewController.swift
//  LearnFirebaseAuthenticationAndAuthorization
//
//  Created by Bill Weatherwax on 8/21/18.
//  Copyright © 2018 waxcruz. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase


class ChangePasswordViewController: UIViewController {
    @IBOutlet weak var oldPassword: UITextField!
    @IBOutlet weak var newPassword: UITextField!
    @IBOutlet weak var confirmPassword: UITextField!
    @IBOutlet weak var message: UITextView!
    // MARK - Firebase properties
    var ref: DatabaseReference!
    var handle: AuthStateDidChangeListenerHandle?
    // MARK - properties
    var oldPasswordEntered : String?
    var newPasswordEntered : String?
    var confirmPasswordEntered : String?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        oldPassword.addTarget(self, action: #selector(ChangePasswordViewController.textFieldDidEnd(_:)), for: UIControlEvents.editingDidEndOnExit)
        newPassword.addTarget(self, action: #selector(ChangePasswordViewController.textFieldDidEnd(_:)), for: UIControlEvents.editingDidEndOnExit)
        confirmPassword.addTarget(self, action: #selector(ChangePasswordViewController.textFieldDidEnd(_:)), for: UIControlEvents.editingDidEndOnExit)
        message.textContainer.lineBreakMode = NSLineBreakMode.byWordWrapping
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            // ...
            NSLog("ChangePassword: user sign-in state changed")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    @objc func textFieldDidEnd(_ textField: UITextField){
        textField.resignFirstResponder()
    }
    

    @IBAction func submit(_ sender: Any) {
        oldPassword.resignFirstResponder()
        newPassword.resignFirstResponder()
        confirmPassword.resignFirstResponder()
        message.text = ""
        let authenticatedEmail = Auth.auth().currentUser?.email
        oldPasswordEntered = oldPassword.text
        newPasswordEntered = newPassword.text
        confirmPasswordEntered = confirmPassword.text
        if newPasswordEntered != confirmPasswordEntered {
            message.text = "Passwords mismatched. Try again"
            return
        }
        if Auth.auth().currentUser != nil {
            do {
                try Auth.auth().signOut()
                Auth.auth().signIn(withEmail: authenticatedEmail!, password: oldPasswordEntered!) { (user, error) in
                    if user == nil {
                        self.message.text = error?.localizedDescription
                        return
                    } else {
                        Auth.auth().currentUser?.updatePassword(to: self.newPasswordEntered!) { (error) in
                            if error != nil {
                                self.message.text = "Failed to update new password: \(error!.localizedDescription)"
                                return
                            } else {
                                self.message.text = "Password change succeeded"
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                }

            } catch {
                message.text = "You must be signed in"
            }
        }
        

        
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
