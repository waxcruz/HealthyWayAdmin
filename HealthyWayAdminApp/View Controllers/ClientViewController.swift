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
    var clientUID : String?
    
    // MARK - Firebase properties
    var ref: DatabaseReference!
    var handle: AuthStateDidChangeListenerHandle?
    var clientNode : [String : Any?] = [:] // key is node type journal, settings, and mealContent
    var usersHandle : DatabaseHandle?
    var usersRef : DatabaseReference?
    var uid : String?
    var emailsHandle : DatabaseHandle?
    var emailsRef : DatabaseReference?
    var firebaseEmail : String? // email with periods replaced by commas
    var journalRef : DatabaseReference?
    var journalHandle : DatabaseHandle?

    // MARK - output
    var htmlLayout : String?

    override func viewDidLoad() {
        super.viewDidLoad()
        uid = ""
        htmlLayout = ""
        ref = Database.database().reference()
        clientEmail.addTarget(self, action: #selector(SignInViewController.textFieldDidEnd(_:)), for: UIControlEvents.editingDidEndOnExit)
        message.textContainer.lineBreakMode = NSLineBreakMode.byWordWrapping

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            // ...
            NSLog("user sign-in state changed")
        }
        if emailEntered != "" {
            getUser()
        } else {
            journal.text = ""
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handle!)
        usersRef?.removeAllObservers()
    }
    

    @objc func textFieldDidEnd(_ textField: UITextField){
        textField.resignFirstResponder()
    }
    // MARK - process users
    func getUser() {
        guard let email = self.emailEntered else {return}
        if email == "" {
            return
        }
        firebaseEmail = makeFirebaseEmailKey(email: email)
        emailsRef = ref.child("emails").child(firebaseEmail!)
        emailsRef?.observeSingleEvent(of: .value, with:  { (snapshot)
            in
                let nodeEmailsValue = snapshot.value as? [String : Any?] ?? [:]
                self.clientUID = nodeEmailsValue["uid"] as? String
                if self.clientUID == nil {
                    self.message.text = "No client found with that email address"
                    return
                }
                    self.usersRef = self.ref.child("users").child(self.clientUID!)
                self.usersRef?.observeSingleEvent(of: .value, with:  { (snapshot)
                    in
                    let nodeUsersValue = snapshot.value as? [String : Any?] ?? [:]
                    let userEmail = nodeUsersValue["email"] as? String
                    let checkEmail = restoreEmail(firebaseEmailKey: userEmail!)
                    if checkEmail == email {
                        self.journalRef = self.ref.child("userData").child(self.clientUID!)
                        self.journalRef?.observeSingleEvent(of: .value, with:
                            { (snapshot)
                                in
                                self.clientNode = snapshot.value as? [String : Any?] ?? [:]
                                self.htmlLayout = self.formatJournal(clientNode: self.clientNode)
                        }) { (error) in
                            self.message.text = "Journal read error" + error.localizedDescription
                        }
                    } else {
                        self.message.text = "Mismatch between emails and uids."
                    }
                }) { (error) in
                    self.message.text = "Broken user ID link."
                    }
        })  { (error) in
            self.message.text = "Broken email address link."
        }
        
//        usersRef = ref.child("users")
//        usersRef?.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
//            self.users.removeAll()
//            self.email.removeAll()
//            let value = snapshot.value as? [String : Any?] ?? [:]
//            for (uid, uidDictionary) in value {
//                for (key, attribute) in uidDictionary as! [String : Any?] {
//                    if key == "email" {
//                        self.users[uid] = attribute as? String
//                        self.email[(attribute as? String)!] = uid
//                    }
//                }
//            }
//
//        })     { (error) in
//            self.message.text = error.localizedDescription + " attempting to access users"
//        }
    }
    

    
    func buildJournalDailyTotalsRow(dateOfMealString displaydate : String, settingsNode node : [String : Any?]) -> String {
        var template = Constants.JOURNAL_DAILY_TOTALS_ROW
        template = template.replacingOccurrences(of: "HW_RECORDED_DATE", with: displaydate)
        template = template.replacingOccurrences(of: "HW_DAILY_TOTAL_PROTEIN_VALUE", with: String(node["LIMIT_PROTEIN_LOW"] as? Double ?? 0.0))
        template = template.replacingOccurrences(of: "HW_DAILY_TOTAL_STARCH_VALUE", with: String(node["LIMIT_STARCH"] as? Double ?? 0.0))
        template = template.replacingOccurrences(of: "HW_DAILY_TOTAL_VEGGIES_VALUE", with: "3.0")
        template = template.replacingOccurrences(of: "HW_DAILY_TOTAL_FRUIT_VALUE", with: String(node["LIMIT_FRUIT"] as? Double ?? 0.0))
        template = template.replacingOccurrences(of: "HW_DAILY_TOTAL_FAT_VALUE", with: String(node["LIMIT_FAT"] as? Double ?? 0.0))
        return template
    }
    func buildJournalMealRow() -> String {
        var template = Constants.JOURNAL_MEAL_ROW
        template = template.replacingOccurrences(of: "HW_MEAL_NAME", with: "Breakfast")
        template = template.replacingOccurrences(of: "HW_MEAL_CONTENTS_DESCRIPTION", with: "Greek yogurt, peach, and fruit spread")
        template = template.replacingOccurrences(of: "HW_MEAL_PROTEIN_COUNT", with: "10")
        template = template.replacingOccurrences(of: "HW_MEAL_STARCH_COUNT", with: "5")
        template = template.replacingOccurrences(of: "HW_MEAL_VEGGIES_COUNT", with: "3")
        template = template.replacingOccurrences(of: "HW_MEAL_FRUIT_COUNT", with: "4")
        template = template.replacingOccurrences(of: "HW_MEAL_FAT_COUNT", with: "5")
        template = template.replacingOccurrences(of: "HW_MEAL_COMMENTS", with: "Good day comment")
        return template
        
    }
    func buildJournalDateTotals() -> String {
        var template = Constants.JOURNAL_DATE_TOTALS
        template = template.replacingOccurrences(of: "HW_DATE_TOTAL_PROTEIN", with: "10")
        template = template.replacingOccurrences(of: "HW_DATE_TOTAL_STARCH", with: "5")
        template = template.replacingOccurrences(of: "HW_DATE_TOTAL_VEGGIES", with: "3")
        template = template.replacingOccurrences(of: "HW_DATE_TOTAL_FRUIT", with: "4")
        template = template.replacingOccurrences(of: "HW_DATE_TOTAL_FAT", with: "5")
        return template
        
    }
    func buildJournalDateStats() -> String {
        var template = Constants.JOURNAL_DATE_STATS
        template = template.replacingOccurrences(of: "HW_DATE_WATER_CHECKS", with: "✔︎✔︎✔︎✔︎✔︎✔︎✔︎✔︎")
        template = template.replacingOccurrences(of: "HW_DATE_SUPPLEMENTS_CHECKS", with: "✔︎✔︎✔︎")
        template = template.replacingOccurrences(of: "HW_DATE_EXERCISE_CHECKS", with: "✔︎")

        return template
    }
    
    func buildJournalDateComments() -> String {
        var template = Constants.JOURNAL_DATE_COMMENTS
        template = template.replacingOccurrences(of: "HW_COMMENTS", with: "Full compliance and lost weight")
        return template
    }
    func buildJournalDateTrailer() -> String {
        var template = Constants.JOURNAL_DATE_TRAILER
        return template
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
        let myJournal = ""
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
    
    
    @IBAction func searchEmail(_ sender: Any) {
        emailEntered = clientEmail.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        getUser()
    }
    
    // MARK - helper methods
    
    func formatJournal(clientNode node : [String : Any?]) -> String? {
        // assumes self.clientJournal loaded from Firebase
        guard node.count > 0 else {
            return nil
        }
        var journalMockup = Constants.JOURNAL_DAY_HEADER
        journalMockup += buildJournalDailyTotalsRow(dateOfMealString: "08-26-2018", settingsNode: (clientNode["Settings"] as? [String : Any?])!)
        journalMockup += buildJournalMealRow()
        journalMockup += buildJournalDateTotals()
        journalMockup += buildJournalDateStats()
        journalMockup += buildJournalDateComments()
        journalMockup += buildJournalDateTrailer()
        
        let attrStr = try! NSAttributedString(
            data: journalMockup.data(using: String.Encoding.unicode, allowLossyConversion: true)!,
            options:[NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
        journal.attributedText = attrStr
        return "add html here"
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
