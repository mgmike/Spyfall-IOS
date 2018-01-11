//
//  MainMenuViewController.swift
//  Spyfall
//
//  Created by Mike Eng on 6/15/17.
//  Copyright © 2017 Mike. All rights reserved.
//

import UIKit
import Firebase
import GoogleMobileAds

class MainMenuViewController: UIViewController {
    
    var currentUID:String!
    var currentName:String?
    var currentUserName:String?
    var hostUserName:String?
    var hostUID:String?
    var hostName:String?
    var mRef: DatabaseReference!
    
    @IBOutlet weak var displayName: UILabel!
    @IBOutlet weak var displayUserName: UILabel!
    @IBOutlet weak var userInfoField: UIView!
    @IBOutlet weak var startGame: UIButton!
    @IBOutlet weak var friendButton: UIButton!
    
    
    @IBAction func onLogOut(_ sender: Any) {
        do{
            try Auth.auth().signOut()
            print("success")
            self.performSegue(withIdentifier: "signedOut", sender: self)
        } catch let logoutError {
            print(logoutError)
        }
        
    }
    
    
    @IBAction func startGame(_ sender: Any) {
        if hostUserName != nil{
            if self.hostUserName == self.currentUserName{
                performSegue(withIdentifier: "onHostGame", sender: self)
            } else {
                performSegue(withIdentifier: "onJoinGame", sender: self)
            }
        } else {
            performSegue(withIdentifier: "onHostGame", sender: self)
        }
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        print("Main menu has loaded.")
        self.navigationItem.hidesBackButton = true
        
        //if user is logged in, get uid
        
        if let user = Auth.auth().currentUser {
            currentUID = user.uid
            print(currentUID ?? "none")
        } else {
            print("No currentUser")
            performSegue(withIdentifier: "signedOut", sender: self)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        userInfoField.layer.cornerRadius = 6
        userInfoField.layer.borderWidth = 2
        startGame.layer.cornerRadius = 6
        startGame.layer.borderWidth = 2
        friendButton.layer.cornerRadius = 6
        friendButton.layer.borderWidth = 2
        mRef = Database.database().reference()
        
        mRef.child("users/" + currentUID + "/userInfo").observeSingleEvent(of: .value, with: { (userInfoDataSnapshot) in
            
            if(userInfoDataSnapshot.hasChild("userName")) {
                self.currentUserName = userInfoDataSnapshot.childSnapshot(forPath: "userName").value as? String
                self.currentName = userInfoDataSnapshot.childSnapshot(forPath: "name").value as? String
                print(self.currentUserName! + self.currentUID + "******************************")
                self.displayUserName.text = self.currentUserName
                self.displayName.text = self.currentName
                if (userInfoDataSnapshot.hasChild("inGame")) {
                    self.hostUserName = userInfoDataSnapshot.childSnapshot(forPath: "inGame").value as? String
                    
                    if (self.hostUserName == self.currentUserName) {
                        self.startGame.setTitle("Join your own game", for: .normal)
                    } else {
                        //gets the hosts UID
                        self.mRef.child("friendUID").observeSingleEvent(of: .value, with: { (dataSnapshot) in
                            self.hostUID = dataSnapshot.childSnapshot(forPath: self.hostUserName!).value as? String
                            self.mRef.child("users/" + self.hostUID! + "/userInfo/name").observeSingleEvent(of: .value, with: { (dataSnapshot) in
                                self.hostName = dataSnapshot.value as? String
                                self.startGame.setTitle("Join " + self.hostName! + "'s game", for: .normal)
                                print(self.currentName!)
                                print(self.currentUserName!)
                                print(self.hostName!)
                                print(self.hostUID!)
                                
                            }, withCancel: { (Error) in
                                //alert here
                            })
                            
                            
                        }, withCancel: { (Error) in
                            //put alert here
                        })
                        
                    }
                } else {
                    self.startGame.setTitle("Start Game", for: .normal)
                }
            }
            
        }, withCancel: { (Error) in
            //put alert here
            //Toast.makeText(MainActivity.this, "Connection Error", Toast.LENGTH_LONG).show();
            
        })

    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
