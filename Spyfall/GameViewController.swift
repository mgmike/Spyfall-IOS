//
//  GameViewController.swift
//  Spyfall
//
//  Created by Mike Eng on 6/29/17.
//  Copyright © 2017 Mike. All rights reserved.
//

import UIKit
import Firebase

class GameViewController: UIViewController {
    
    var currentUID:String!
    var currentName:String?
    var currentUserName:String?
    var hostUserName:String?
    var hostUID:String?
    var hostName:String?
    var mRef: DatabaseReference!
    
    @IBOutlet weak var startGame: UIButton!
    @IBOutlet weak var leaveGame: UIButton!
    @IBOutlet weak var hideRole: UIButton!
    @IBOutlet weak var roleText: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //gets uid
        
        if let user = Auth.auth().currentUser {
            currentUID = user.uid
            print(currentUID ?? "none")
            
            mRef = Database.database().reference()
            mRef.child("users/" + currentUID + "/userInfo").observeSingleEvent(of: .value, with: { (dataSnapshot) in
                self.currentName = dataSnapshot.childSnapshot(forPath: "name").value as? String
                self.currentUserName = dataSnapshot.childSnapshot(forPath: "userName").value as? String
                if dataSnapshot.childSnapshot(forPath: "inGame").exists(){
                    self.hostName = dataSnapshot.childSnapshot(forPath: "inGame").value as? String
                } else {
                    
                }
                print(self.currentUID + self.currentUserName! + self.currentName!)
            }, withCancel: { (error) in
                //place alert here
            })
            
        } else {
            print("None")
            performSegue(withIdentifier: "signedOut", sender: self)
        }
        
        
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
