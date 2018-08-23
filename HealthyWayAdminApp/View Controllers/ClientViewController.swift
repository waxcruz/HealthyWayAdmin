//
//  ClientViewController.swift
//  LearnFirebaseAuthenticationAndAuthorization
//
//  Created by Bill Weatherwax on 8/21/18.
//  Copyright © 2018 waxcruz. All rights reserved.
//

import UIKit
import Firebase
import MessageUI


class ClientViewController: UIViewController, MFMailComposeViewControllerDelegate {
    //MARK - outlets
    @IBOutlet weak var clientEmail: UITextField!
    @IBOutlet weak var journal: UITextView!
    @IBOutlet weak var weightChart: UILabel!
    @IBOutlet weak var message: UITextView!
    
    // MARK - properties
    var emailEntered : String?
    
    // MARK - Firebase properties
    var ref: DatabaseReference!
    var handle: AuthStateDidChangeListenerHandle?

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        clientEmail.addTarget(self, action: #selector(SignInViewController.textFieldDidEnd(_:)), for: UIControlEvents.editingDidEndOnExit)
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
        let attrStr = try! NSAttributedString(
            data: Constants.JOURNAL_MOCKUP.data(using: String.Encoding.unicode, allowLossyConversion: true)!,
            options:[NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
        journal.attributedText = attrStr
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    

    @IBAction func mailClientJournal(_ sender: Any) {
        if !MFMailComposeViewController.canSendMail() {
            NSLog("No email")
        }
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        // Configure the fields of the interface.
        composeVC.setToRecipients(["waxcruz@yahoo.com"])
        composeVC.setSubject("Journal")
        let myJournal = Constants.JOURNAL_MOCKUP
        composeVC.setMessageBody(myJournal, isHTML: true)
        
        // Present the view controller modally.
        self.present(composeVC, animated: true, completion: nil)
    }
    
    //    func mailComposeController(controller: MFMailComposeViewController,
    //                               didFinishWithResult result: MFMailComposeResult, error: Error?) {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        // Check the result or perform other tasks.
        NSLog("Done with email")
        // Dismiss the mail compose view controller.
        controller.dismiss(animated: true, completion: nil)
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
