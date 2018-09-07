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
import HealthyWayFramework
import Charts
    
    


class ClientViewController: UIViewController, MFMailComposeViewControllerDelegate {
    //MARK - outlets
    @IBOutlet weak var clientEmail: UITextField!
    @IBOutlet weak var journal: UITextView!
    @IBOutlet weak var message: UITextView!
    @IBOutlet weak var lineChart: LineChartView!
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
                                self.journal.attributedText = formatJournal(clientNode: self.clientNode)
                                self.lineChartUpdate(clientNode: self.clientNode)
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
    
    // MARK: - Charting Methods
    func lineChartUpdate(clientNode node : [String : Any?]) {
        guard node.count > 0 else {
            return
        }
        let nodeJournal = node[KeysForFirebase.NODE_JOURNAL] as? [String: Any?]
        if nodeJournal == nil {
            return
        }
        let sortedKeysDates = Array(nodeJournal!.keys).sorted(by: <)
        var startDate = ""
        var startWeight = 0.0
        var chartDataPoint = [String : Double]()
        for weightDate in sortedKeysDates {
            let nodeDate = nodeJournal![weightDate] as? [String : Any?] ?? [:]
            if startDate == "" {
                startDate = weightDate // earliest date
                startWeight = nodeDate[KeysForFirebase.WEIGHED] as? Double ?? 0.0
                chartDataPoint[weightDate] = 0.0
            } else {
                chartDataPoint[weightDate] = (nodeDate[KeysForFirebase.WEIGHED] as? Double ?? 0.0) - startWeight
            }
        }

        // now format chart series
        var chartSeries = [ChartDataEntry]()
        var chartLabels = [String]()
        var xValue = 0.0
        for weightDate in sortedKeysDates {
            let weightDateAsDate = makeDateFromString(dateAsString: weightDate)
            let weightMonthSlashDayKey = weightDateAsDate.makeMonthSlashDayDisplayString()
            let point = ChartDataEntry(x: xValue, y:  chartDataPoint[weightDate]!)
            chartSeries.append(point)
            chartLabels.append(weightMonthSlashDayKey)
            xValue += 1.0
        }
        let weightDataSet = LineChartDataSet(values: chartSeries, label: "Weight Loss/Gain")
        weightDataSet.valueColors = [UIColor .black]
        let weightData = LineChartData(dataSet: weightDataSet)
        lineChart.data = weightData
        lineChart.xAxis.valueFormatter = IndexAxisValueFormatter(values: chartLabels)
        lineChart.xAxis.granularity = 1
        lineChart.xAxis.labelRotationAngle = -45.0
        lineChart.chartDescription?.text = "The Healthy Way Maintenance Chart"
        lineChart.notifyDataSetChanged()
        
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
