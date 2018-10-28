    //
    //  ClientViewController.swift
    //  LearnFirebaseAuthenticationAndAuthorization
    //
    //  Created by Bill Weatherwax on 8/21/18.
    //  Copyright © 2018 waxcruz. All rights reserved.
    //
    
    import UIKit
    import MessageUI
    import HealthyWayFramework
    import Charts
    
    
    
    
    class ClientViewController: UIViewController, MFMailComposeViewControllerDelegate, UITableViewDelegate, UITableViewDataSource  {
        // MARK: - global model controller
        var modelController : ModelController!
        
        //MARK - outlets
        @IBOutlet weak var clientEmail: UITextField!
        @IBOutlet weak var journal: UITextView!
        @IBOutlet weak var message: UITextView!
        @IBOutlet weak var lineChart: LineChartView!
        @IBOutlet weak var copyright: UILabel!
        @IBOutlet weak var mailboxButton: UIButton!
        // MARK : - Overlay search results
        @IBOutlet weak var searchResultsContent: UIView!
        @IBOutlet weak var searchResultsTableView: UITableView!
        
        
        
        // MARK - properties
        var emailEntered : String?
        var clientUID : String?
        
        // MARK - Firebase properties
        var clientNode : [String : Any?] = [:] // key is node type journal, settings, and mealContent
        var uid : String?
        var firebaseEmail : String? // email with periods replaced by commas
        // MARK : tableview
        var cellReuseIdentifier : String = ""
        // MARK : - emails
        var fullListOfEmails : [String]? = []
        var filterdListOfEmails : [String] = []
        // MARK - output
        var htmlLayout : String?
        
        override func viewDidLoad() {
            super.viewDidLoad()
            copyright.text = makeCopyright()
            uid = ""
            htmlLayout = nil
            mailboxButton.isHidden = true
            clientEmail.addTarget(self, action: #selector(SignInViewController.textFieldDidEnd(_:)), for: UIControlEvents.editingDidEndOnExit)
            clientEmail.addTarget(self, action: #selector(textFieldDidBegin(_:)), for: UIControlEvents.editingDidBegin)
            clientEmail.addTarget(self, action: #selector(textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
            message.textContainer.lineBreakMode = NSLineBreakMode.byWordWrapping
            lineChart.noDataText = ""
            // cell reuse id (cells that scroll out of view can be reused)
            cellReuseIdentifier = "emailCell"
            modelController.getNodeEmails(errorHandler: failedToGetListOfClientEmails, handler: gotTheListOfClientEmails)
            self.searchResultsTableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
            
            // (optional) include this line if you want to remove the extra empty cell divider lines
            // self.tableView.tableFooterView = UIView()
            
            // This view controller itself will provide the delegate methods and row data for the table view.
            searchResultsTableView.delegate = self
            searchResultsTableView.dataSource = self

        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
        }
        
        func gotTheListOfClientEmails() {
            fullListOfEmails = modelController.emailsList
            filterdListOfEmails = fullListOfEmails ?? []
        }
        
        func failedToGetListOfClientEmails(message : String) {
            print("failed to get list of client emails because of error: ", message)
        }
        
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            //        Auth.auth().removeStateDidChangeListener(handle!)
            //        usersRef?.removeAllObservers()
        }
        
        @objc func textFieldDidBegin(_ textField: UITextField){
            searchResultsContent.isHidden = false
            self.journal.attributedText = nil
            self.lineChart.clear()
        }
        
        @objc func textFieldDidChange(_ textField : UITextField) {
            let searchString = (textField.text)?.lowercased()
            filterdListOfEmails = []
            for email in fullListOfEmails ?? [] {
                let lowerCaseEmail = email.lowercased()
                if lowerCaseEmail.hasPrefix(searchString ?? "") {
                    filterdListOfEmails.append(email)
                }
            }
            searchResultsTableView.reloadData()
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
            modelController.getNodeOfClient(email: email, errorHandler: errorInDatabase, handler: assembleClientData)
        }
        
        // MARK - assemble data helper methods
        func assembleClientData() {
            self.journal.attributedText = nil
            self.lineChart.clear()
            if modelController.clientNode.count == 0 {
                mailboxButton.isHidden = true
                message.text = "No data for client"
            } else {
                htmlLayout = formatJournal(clientNode: modelController.clientNode, isEmail: false)
                let attrStr = try! NSAttributedString(
                    data: (htmlLayout?.data(using: String.Encoding.unicode, allowLossyConversion: true)!)!,
                    options:[NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
                journal.attributedText = attrStr
                self.lineChartUpdate(clientNode: modelController.clientNode)
                mailboxButton.isHidden = false
            }
        }
        
        func errorInDatabase(message : String) {
            print(message)
            self.journal.attributedText = nil
            self.lineChart.clear()
            self.message.text = modelController.clientErrorMessages
            mailboxButton.isHidden = true
        }
        
        @IBAction func mailClientJournal(_ sender: Any) {
            if !MFMailComposeViewController.canSendMail() {
                NSLog("No email")
            }
            let composeVC = MFMailComposeViewController()
            composeVC.mailComposeDelegate = self
            // Configure the fields of the interface.
            composeVC.setToRecipients([modelController.signedinEmail!])
            composeVC.setSubject("Journal")
            htmlLayout = formatJournal(clientNode: modelController.clientNode, isEmail: true)
            composeVC.setMessageBody(htmlLayout!, isHTML: true)
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
            message.text = ""
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
            weightDataSet.circleColors = [UIColor .green]
            weightDataSet.colors = [UIColor .green]
            let weightData = LineChartData(dataSet: weightDataSet)
            lineChart.data = weightData
            lineChart.xAxis.valueFormatter = IndexAxisValueFormatter(values: chartLabels)
            lineChart.xAxis.granularity = 1
            lineChart.xAxis.labelRotationAngle = -45.0
            lineChart.chartDescription?.text = "The Healthy Way Maintenance Chart"
            
            lineChart.notifyDataSetChanged()
            
        }
        
        
        // MARK: - Navigation
        
        // In a storyboard-based application, you will often want to do a little preparation before navigation
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            // Get the new view controller using segue.destinationViewController.
            // Pass the selected object to the new view controller.
            let vc = segue.destination
            if vc .isKind(of: SettingsViewController.self) {
                (vc as! SettingsViewController).modelController = modelController
            } else {
                print("Unknown segue (", vc.debugDescription, ") in ClientViewController")
            }
        }
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return filterdListOfEmails.count
            
        }
        
        // create a cell for each table view row
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
            // create a new cell if needed or reuse an old one
            let cell:UITableViewCell = self.searchResultsTableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as UITableViewCell!
            
            // set the text from the data model
            cell.textLabel?.text = filterdListOfEmails[indexPath.row]
            
            return cell
        }
        
        // method to run when table view cell is tapped
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            clientEmail.text = restoreEmail(firebaseEmailKey: filterdListOfEmails[indexPath.row])
            searchResultsContent.isHidden = true

        }

        
    }
