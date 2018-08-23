//
//  CreateNewAccountViewController.swift
//  LearnFirebaseAuthenticationAndAuthorization
//
//  Created by Bill Weatherwax on 8/21/18.
//  Copyright © 2018 waxcruz. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase

class CreateNewAccountViewController: UIViewController {
    // MARK - Sign-in fields
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var confirmPassword: UITextField!
    @IBOutlet weak var message: UITextView!
    // MARK - Firebase properties
    var ref: DatabaseReference!
    var handle: AuthStateDidChangeListenerHandle?
    // MARK - properties
    var emailEntered : String?
    var passwordEntered : String?
    var confirmPasswordEntered : String?

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        email.addTarget(self, action: #selector(CreateNewAccountViewController.textFieldDidEnd(_:)), for: UIControlEvents.editingDidEndOnExit)
        password.addTarget(self, action: #selector(CreateNewAccountViewController.textFieldDidEnd(_:)), for: UIControlEvents.editingDidEndOnExit)
        confirmPassword.addTarget(self, action: #selector(CreateNewAccountViewController.textFieldDidEnd(_:)), for: UIControlEvents.editingDidEndOnExit)
        message.textContainer.lineBreakMode = NSLineBreakMode.byWordWrapping
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            // ...
            NSLog("CreateNewAccount: user sign-in state changed")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    @objc func textFieldDidEnd(_ textField: UITextField){
        textField.resignFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func signIn(_ sender: Any) {
        email.resignFirstResponder()
        password.resignFirstResponder()
        confirmPassword.resignFirstResponder()
        message.text = ""
        if Auth.auth().currentUser != nil {
            do {
                try Auth.auth().signOut()
            } catch {
                print("CreateNewAccountViewController, Sign out failed")
            }
        }
        emailEntered = email.text
        passwordEntered = password.text
        confirmPasswordEntered = confirmPassword.text
        if passwordEntered != confirmPasswordEntered {
            message.text = "Passwords mismatched. Try again"
            return
        }
        Auth.auth().createUser(withEmail: emailEntered!, password: passwordEntered!) { (authResult, error) in
            // ...
            guard let user = authResult?.user else { return }
            // write to users node
            self.ref.child("users").child(user.uid).setValue(["email": self.emailEntered!, "isAdmin": true]) {
                (error:Error?, ref:DatabaseReference) in
                if let error = error {
                    self.message.text = "Account creation failed: \(error)."
                } else {
                    self.message.text = "Account created!"
                }
            }
        }
        // authentication complete, show client view
        performSegue(withIdentifier: Constants.SEGUE_FROM_CREATE_TO_CLIENT_ID, sender: nil)
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
