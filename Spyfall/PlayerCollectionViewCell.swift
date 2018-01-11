//
//  PlayerCollectionViewCell.swift
//  Spyfall
//
//  Created by Mike Eng on 7/5/17.
//  Copyright © 2017 Mike. All rights reserved.
//

import UIKit
import Firebase

class PlayerCollectionViewCell: UICollectionViewCell{
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var kickButton: UIButton!
    
    var tempUID:String!
    var tempUserName:String?
    var isFriend:Bool?
    var mRef:DatabaseReference!
    var hostUserName:String!
    var hostUID:String!
    var location:String!
    var isClicked:Bool = true
    var showKickButton:Bool!
    
    
    
    @IBAction func onAdd(_ sender: Any) {
        //sends a request to specified user
        var tempRef:DatabaseReference = self.mRef.child("users/" + tempUID + "/friends/users/" + hostUserName)
        tempRef.child("from").setValue(true)
        tempRef.child("requestAccepted").setValue(false)
        tempRef.child("userName").setValue(hostUserName)
        //shows up on user's list also
        //get friends name to put on main user's friends list
        //add the friend on main user's list
        tempRef = self.mRef.child("users/" + hostUID + "/friends/users/" + tempUserName!)
        tempRef.child("from").setValue(false);
        tempRef.child("requestAccepted").setValue(false);
        tempRef.child("userName").setValue(self.tempUserName);
        self.addButton.isHidden = true
    }
    
    @IBAction func onKick(_ sender: Any) {
        mRef.child("friendUID").observeSingleEvent(of: .value, with: { (dataSnapshot) in
            self.mRef.child("users").child(self.hostUID).child("currentGame").child("users").child(self.tempUserName!).removeValue()
            self.mRef.child("users").child(dataSnapshot.childSnapshot(forPath: self.tempUserName!).value as! String).child("userInfo").child("inGame").removeValue()
        }) { (error) in
            //add alert
        }
    }
    
    
    
    func setupViews(parentSize:Int, hostUID:String, tempUserName:String, showKickButton:Bool){
        self.showKickButton = showKickButton
        nameLabel.text = "name"
        nameLabel.font = nameLabel.font.withSize(13)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        userNameLabel.text = "username"
        userNameLabel.font = userNameLabel.font.withSize(9)
        userNameLabel.textColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.45)
        userNameLabel.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle("Add", for: .normal)
        addButton.setTitleColor(.black, for: .normal)
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        kickButton.setTitle("Kick", for: .normal)
        kickButton.setTitleColor(.black, for: .normal)
        kickButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        kickButton.translatesAutoresizingMaskIntoConstraints = false
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-5-[v0][v1(" + String(parentSize / 6) + ")][v2(" + String(parentSize / 6) + ")]-4-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": nameLabel , "v1": addButton, "v2": kickButton]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-5-[v0][v1(" + String(parentSize / 6) + ")][v2(" + String(parentSize / 6) + ")]-4-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": userNameLabel , "v1": addButton, "v2": kickButton]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[v0][v1]-8-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": nameLabel , "v1": userNameLabel]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": addButton]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": kickButton]))
        self.hostUID = hostUID
        self.tempUserName = tempUserName
        userNameLabel.text = tempUserName
        updateValues()
    }
    
    func updateValues(){
    
        mRef = Database.database().reference()
        mRef.child("users/" + hostUID + "/userInfo").observeSingleEvent(of: .value, with: { (dataSnapshot) in
            self.hostUserName = dataSnapshot.childSnapshot(forPath: "userName").value as! String
            self.mRef.child("friendUID").observeSingleEvent(of: .value, with: { (dataSnapshot) in
                //find UID
                if(dataSnapshot.childSnapshot(forPath: self.tempUserName!).exists()) {
                    //print(dataSnapshot.childSnapshot(forPath: self.tempUserName!).value as! String + "===========================================")
                    self.tempUID = dataSnapshot.childSnapshot(forPath: self.tempUserName!).value as! String
                    
                    //find name
                    self.mRef.child("users/" + self.tempUID + "/userInfo").observeSingleEvent(of: .value, with: { (dataSnapshot) in
                        
                        if(dataSnapshot.childSnapshot(forPath: "name").exists()) {
                            self.nameLabel.text = dataSnapshot.childSnapshot(forPath: "name").value as? String ?? ""
                        }
                            
                        }) { (Error) in
                        //add alert
                    }
                    self.mRef.child("users/" + self.hostUID + "/currentGame/location").observeSingleEvent(of: .value, with: { (dataSnapshot) in
                        self.location = dataSnapshot.value as! String
                        self.updateButtons()
                    }) { (error) in
                        //add alert
                    }
                }
            }) { (error) in
                //add alert
            }
        }) { (error) in
            //add alert
        }
    }
    
    func updateButtons(){
        
        if(self.location == "none"){
            //make the alpha 1
            
            //if this item is the hosts, the buttons will not appear
            if(self.hostUserName != self.tempUserName) {
                if self.showKickButton{
                    kickButton.isHidden = false
                } else {
                    kickButton.isHidden = true
                }
                self.mRef.child("users/" + self.hostUID + "/friends/users").observeSingleEvent(of: .value, with: { (dataSnapshot) in
                    //if this item's user is not on your friends list, a button will be visible to add them
                    if (!dataSnapshot.childSnapshot(forPath: self.tempUserName!).exists()) {
                        self.isFriend = false
                        self.addButton.isHidden = false
                    } else {
                        self.isFriend = true
                        self.addButton.isHidden = true
                    }
                }) { (error) in
                    //add alert
                }
            } else {
                self.kickButton.isHidden = true
                self.addButton.isHidden = true
            }
        } else {
            self.kickButton.isHidden = true
            self.addButton.isHidden = true
        }
    }
    
    func setText(text:String){
        userNameLabel.text = text
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
