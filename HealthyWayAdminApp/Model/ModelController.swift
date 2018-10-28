//
//  ModelController.swift
// HealthyWay
//
//  Created by Bill Weatherwax on 7/5/18.
//  Copyright © 2018 waxcruz. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import HealthyWayFramework

class ModelController
{
    //MARK - Firebase
        // Reference and handles
    var ref = DatabaseReference()
    var refHandle = DatabaseHandle()
    var settingsHandle  = DatabaseHandle()
    var journalHandle = DatabaseHandle()
    var mealContentsHandle = DatabaseHandle()
        // Keys and content
    var firebaseDateKey : String = "YYYY-MM-DD"
    var settingsInFirebase : Dictionary? = [:]
    var journalInFirebase : Dictionary? = [:]
    var mealContentsInFirebase : Dictionary? = [:]
    var clientNode : [String : Any?] = [:] // key is node type journal, settings, and mealContent
    var clientErrorMessages : String = ""
    var signedinUID : String?
    var signedinEmail : String?
    var emailsList : [String] = [] // list of all client emails
    // MARK: - methods
    
    func startModel(){
        ref = Database.database().reference()
        signedinUID = nil
        signedinEmail = nil
    }
    
    func stopModel(){
        ref.removeObserver(withHandle: refHandle)
    }
    
    func getDatabaseRef() -> DatabaseReference {
        return ref
    }
    // MARK - Meal management
    
    func newDay() {
        
    }
    
    func oldDay(dateOfmeal mealDate : String) {
        
    }
    
    // MARK - Helper methods for Firebase
    
    func updateChildInFirebase(fireBaseTable table : String, fireBaseChildPath path : String, value : Any) {
        let fullFirebasePath : String? = table + "/" + path
        if fullFirebasePath != nil {
            ref.child(fullFirebasePath!).setValue(value)
        } else {
            NSLog("error in updateChildInFirebase")
        }
    }
    
    func updateChildOfRecordInFirebase(fireBaseTable table : String, fireBaseRecordID recordID : String, fireBaseChildPath path : String, value : Any) {
        let fullFirebasePath : String? = table + "/" + recordID + "/" + path
        if fullFirebasePath != nil {
            ref.child(fullFirebasePath!).setValue(value)
        } else {
            NSLog("error in updateChildOfRecordInFirebase")
        }
        
    }
    // MARK - Authentication
    
    func loginUser(email : String, password : String, errorHandler : @escaping (_ : String) -> Void,  handler : @escaping ()-> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            // ...
            if user == nil {
                errorHandler((error?.localizedDescription)!)
                return
            } else {
                self.signedinUID = user?.user.uid
                self.signedinEmail = user?.user.email
                handler()
            }
        }
    }
 
    
    
    func signoutUser(errorHandler : @escaping (_ : String) -> Void) {
        if Auth.auth().currentUser?.displayName != nil {
            do {
                print("Signing out user: ", Auth.auth().currentUser?.displayName! ?? "unknown user")
                try Auth.auth().signOut()
                signedinUID = nil
                signedinEmail = nil
            } catch {
                errorHandler("Sign out failed")
                return
            }
        }

    }
    func signoutUser(errorHandler : @escaping (_ : String) -> Void,  handler : @escaping ()-> Void) {
        if Auth.auth().currentUser?.uid != nil {
            do {
                print("Signing out user: ", Auth.auth().currentUser?.email! ?? "unknown user")
                try Auth.auth().signOut()
                signedinUID = nil
                signedinEmail = nil
                handler()
            } catch {
                errorHandler("Sign out failed")
            }
        }
        
    }

    func passwordReset(clientEmail email : String, errorHandler : @escaping (_ : String) -> Void, handler : @escaping () -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { (error) in
            // error
            if let checkError = error {
                let message = "Reset email failure: \(checkError.localizedDescription)"
                errorHandler(message)
            } else {
                handler()
            }
        }

    }
    
    func updatePassword(newPassword : String, errorHandler : @escaping (_ : String) -> Void, handler : @escaping () -> Void) {
        Auth.auth().currentUser?.updatePassword(to:newPassword) {(error) in
            if error != nil {
                let message = "Failed to update new password: \(error!.localizedDescription)"
                errorHandler(message)
                return
            } else {
                handler()
            }
        }
    }
    
    
    
    func checkFirebaseConnected(handler : @escaping () -> Void) -> Void {
        
        let healthywayDatabaseRef = ref
        let connectedRef = healthywayDatabaseRef.database.reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in

           if snapshot.value as? Bool ?? false {
                print("Connected to Firebase")
            } else {
                print("Not connected to Firebase")
            }
           handler()
        })
    }
    
    func getNodeOfClient(email : String, errorHandler : @escaping (_ : String) -> Void,  handler : @escaping ()-> Void) {
        clientNode = [:]
        clientErrorMessages = ""
        let firebaseEmail = makeFirebaseEmailKey(email: email)
        let emailsRef = ref.child("emails").child(firebaseEmail)
        emailsRef.observeSingleEvent(of: .value, with:  { (snapshot)
            in
            let nodeEmailsValue = snapshot.value as? [String : Any?] ?? [:]
            let clientUID = nodeEmailsValue["uid"] as? String
            if clientUID == nil {
                self.clientErrorMessages = "No client found with that email address"
                errorHandler(self.clientErrorMessages)
                return
            }
            let usersRef = self.ref.child("users").child(clientUID!)
            usersRef.observeSingleEvent(of: .value, with:  { (snapshot)
                in
                let nodeUsersValue = snapshot.value as? [String : Any?] ?? [:]
                let userEmail = nodeUsersValue["email"] as? String
                let checkEmail = restoreEmail(firebaseEmailKey: userEmail!)
                if checkEmail == email {
                    let userDataRef = self.ref.child("userData").child(clientUID!)
                    userDataRef.observeSingleEvent(of: .value, with:
                        { (snapshot)
                            in
                            self.clientNode = snapshot.value as? [String : Any?] ?? [:]
                            handler()
                    }) { (error) in
                        self.clientErrorMessages = "Encountered error, " + error.localizedDescription +
                        ", searching for client data"
                        errorHandler(self.clientErrorMessages)
                        return
                    }
                } else {
                    self.clientErrorMessages = "Mismatch between emails and uids."
                    errorHandler(self.clientErrorMessages)
                    return
                }
            }) { (error) in
                self.clientErrorMessages = "Encountered error, " + error.localizedDescription + ", searching for client UID"
                errorHandler(self.clientErrorMessages)
                return
            }
        })  { (error) in
            self.clientErrorMessages = "Encountered error, " + error.localizedDescription + ", searching for client email"
            errorHandler(self.clientErrorMessages)
            return
        }
    }

    func createAuthUserNode(userEmail emailEntered : String, userPassword passwordEntered : String, errorHandler : @escaping (_ : String) -> Void,  handler : @escaping ()-> Void) {
        Auth.auth().createUser(withEmail: emailEntered, password: passwordEntered) { (authResult, error) in
            // ...
            self.signedinUID = authResult?.user.uid
            self.signedinEmail = authResult?.user.email
            if self.signedinUID == nil {
                let firebaseError = "Account creation failed: "
                    + (error?.localizedDescription)!
                errorHandler(firebaseError)
                return
            }else {
                handler()
            }
        }
    }
                
    func createUserInUsersNode(userUID uid : String, userEmail email : String, errorHandler : @escaping (_ : String) -> Void,  handler : @escaping ()-> Void) {
        self.ref.child("users").child(uid).setValue(["email": email, "isAdmin": true]) {
            (error:Error?, ref:DatabaseReference) in
            if let checkError = error {
                errorHandler("Account creation failed: \(checkError).")
                return
            } else {
                handler()
            }
        }
    }
    
    func createEmailInEmailsNode(userUID uid : String, userEmail email : String, errorHandling : @escaping (_ : String) -> Void, handler : @escaping () -> Void) {
        let keyEmail = makeFirebaseEmailKey(email: email)
        self.ref.child("emails").child(keyEmail).setValue(["uid" : uid]) {
            (error : Error?, ref: DatabaseReference) in
            if let checkError = error {
                errorHandling("Email creation failed:\(checkError).")
                return
            } else {
                handler()
            }
        }
    }
    
    
    // MARK : list methods
    func getNodeEmails(errorHandler : @escaping (_ : String) -> Void,  handler : @escaping ()-> Void) {
        
        let emailsRef = ref.child("emails")
        emailsRef.observeSingleEvent(of: .value, with:  { (snapshot)
            in
            let emailsNode = snapshot.value as? [String : Any?] ?? [:]
            self.emailsList = Array(emailsNode.keys).sorted()
            handler()
        })  { (error) in
            let emailsNodeErrorMessage = "Encountered error, " + error.localizedDescription + ", searching for client email"
            errorHandler(emailsNodeErrorMessage)
            return
        }
    }
    
    
}


