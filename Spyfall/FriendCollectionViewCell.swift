//
//  FriendCollectionViewCell.swift
//  Spyfall
//
//  Created by Mike Eng on 7/19/17.
//  Copyright © 2017 Mike. All rights reserved.
//

import UIKit
import Firebase

protocol CollectionViewCellDelegate: class{
    func collectionViewCell(_ cell: UICollectionViewCell, buttonTapped: UIButton)
}

class FriendCollectionViewCell: UICollectionViewCell {
    
    var friendUserName:String!
    var friendUID:String!
    var friendName:String?
    var friendGameStatus:String? //host user name
    var currentUserName:String!
    var currentUID:String!
    var currentName:String?
    var currentGame:String?
    var currentGameUID:String?
    var hostUID:String?
    var mRef:DatabaseReference
    weak var delegate: CollectionViewCellDelegate?
    
    @IBOutlet weak var friendImage: UIImageView!
    @IBOutlet weak var nameText: UILabel!
    @IBOutlet weak var userNameText: UILabel!
    @IBOutlet weak var statusText: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var joinGameButton: UIButton!
    
    override init(frame: CGRect) {
        mRef = Database.database().reference()
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        mRef = Database.database().reference()
        super.init(coder: aDecoder)
    }
    
    @IBAction func onAccept(_ sender: Any) {
        //changes the friend's profile under the users account to true
        mRef.child("users/" + self.currentUID + "/friends/users").child(friendUserName).child("requestAccepted").setValue(true)
        //changes the users friend account under the friend's profile
        mRef.child("users/" + self.friendUID + "/friends/users").child(currentUserName).child("requestAccepted").setValue(true)
        
        //checkGameStatus(friendName, friendUID, friendUserName, friendGameStatus)
        checkGameStatus()
    }
    
    @IBAction func onDecline(_ sender: Any) {
        mRef.child("users/" + currentUID + "/friends/users").child(self.friendUserName).removeValue()
        mRef.child("users/" + self.friendUID + "/friends/users").child(self.currentUserName).removeValue()
    }
    
    @IBAction func onJoinGame(_ sender: Any) {
        //if the user is in any game
        if (self.currentGame != nil){
            //if the user is currently their own game, end the game and join the friends game
            if (self.currentGame == self.currentUserName){
                self.mRef.child("users/" + self.currentUID + "/currentGame").removeValue()
                self.mRef.child("users/" + self.currentUID + "/userInfo/inGame").setValue(self.friendGameStatus)
                mRef.child("users").child(self.hostUID!).child("currentGame").child("users").child(self.currentUserName).child("userName").setValue(self.currentUserName)
                self.delegate?.collectionViewCell(self, buttonTapped: self.joinGameButton)
            } else if (self.currentGame == friendGameStatus){ //if the user is already in the friend's game, they will just rejoin it
                self.delegate?.collectionViewCell(self, buttonTapped: self.joinGameButton)
            } else { //if the user is in another friends game, they will leave that game and join the new one
                self.mRef.child("users/" + self.currentGameUID! + "/currentGame/users/" + self.currentUserName).removeValue()
                self.mRef.child("users/" + self.currentUID + "/userInfo/inGame").setValue(self.friendGameStatus)
                mRef.child("users").child(self.hostUID!).child("currentGame").child("users").child(self.currentUserName).child("userName").setValue(self.currentUserName)
                self.delegate?.collectionViewCell(self, buttonTapped: self.joinGameButton)
            }
        } else {
            mRef.child("users").child(self.currentUID).child("userInfo").child("inGame").setValue(self.friendGameStatus)
            mRef.child("users").child(self.hostUID!).child("currentGame").child("users").child(self.currentUserName).child("userName").setValue(self.currentUserName)
            self.delegate?.collectionViewCell(self, buttonTapped: joinGameButton)
        }
    }
    
    
    func checkGameStatus(){
        if (friendGameStatus != nil) {
            //if they are not in your game
            if(friendGameStatus != currentUserName) {
                self.mRef.child("friendUID").observeSingleEvent(of: .value, with: { (dataSnapshot) in
                    //gets the UID of game host
                    self.hostUID = dataSnapshot.childSnapshot(forPath: self.friendGameStatus!).value as? String
                
                    self.mRef.child("users/" + self.hostUID! + "/currentGame").observeSingleEvent(of: .value, with: { (dataSnapshot) in
                        if (dataSnapshot.exists()) {
                            let location = dataSnapshot.childSnapshot(forPath: "location").value as! String
                            if (location == "none") {
                                self.acceptButton.isHidden = true
                                self.declineButton.isHidden = true
                                self.joinGameButton.isHidden = false
                                self.statusText.text = self.friendName! + " is in " + self.friendGameStatus! + "'s game."
                                
                            } else {
                                self.acceptButton.isHidden = true
                                self.declineButton.isHidden = true
                                self.joinGameButton.isHidden = true
                                self.statusText.text = "Wait for " + self.friendName! + "'s game to end"
                            }
                        }
                    }, withCancel: { (error) in
                        //add alert
                    })
                    
                    self.mRef.child("users/" + self.hostUID!).observe(.childRemoved, with: { (dataSnapshot) in
                        if (dataSnapshot.exists()) {
                            if (dataSnapshot.childSnapshot(forPath: "currentGame").exists()){
                                let location = dataSnapshot.childSnapshot(forPath: "location").value as! String
                                if (location == "none") {
                                    self.acceptButton.isHidden = true
                                    self.declineButton.isHidden = true
                                    self.joinGameButton.isHidden = false
                                    self.statusText.text = self.friendName! + " is in " + self.friendGameStatus! + "'s game."
                                    
                                } else {
                                    self.acceptButton.isHidden = true
                                    self.declineButton.isHidden = true
                                    self.joinGameButton.isHidden = true
                                    self.statusText.text = "Wait for " + self.friendName! + "'s game to end"
                                }
                            } else {
                                self.acceptButton.isHidden = true
                                self.declineButton.isHidden = true
                                self.joinGameButton.isHidden = true
                                self.statusText.text = self.friendName! + " is not in game!"
                            }
                        }
                    }, withCancel: { (error) in
                        //add alert
                    })
                    
                    self.mRef.child("users/" + self.hostUID! + "/currentGame").observe(.childChanged, with: { (dataSnapshot) in
                        if (dataSnapshot.exists()) {
                            if (dataSnapshot.childSnapshot(forPath: "location").exists()){
                                let location = dataSnapshot.childSnapshot(forPath: "location").value as! String
                                if (location == "none") {
                                    self.acceptButton.isHidden = true
                                    self.declineButton.isHidden = true
                                    self.joinGameButton.isHidden = false
                                    self.statusText.text = self.friendName! + " is in " + self.friendGameStatus! + "'s game."
                                    
                                } else {
                                    self.acceptButton.isHidden = true
                                    self.declineButton.isHidden = true
                                    self.joinGameButton.isHidden = true
                                    self.statusText.text = "Wait for " + self.friendName! + "'s game to end"
                                }
                            } else {
                                self.acceptButton.isHidden = true
                                self.declineButton.isHidden = true
                                self.joinGameButton.isHidden = true
                                self.statusText.text = self.friendName! + " is not in game!"
                            }
                        }
                    }, withCancel: { (error) in
                        //add alert
                    })
                }, withCancel: { (error) in
                    //add alert
                })
                //if they are not in your game
            } else {
                self.acceptButton.isHidden = true
                self.declineButton.isHidden = true
                self.joinGameButton.isHidden = true
                self.statusText.text = (self.friendName! + " is in your game!")
            }
        } else {
            self.acceptButton.isHidden = true
            self.declineButton.isHidden = true
            self.joinGameButton.isHidden = true
            self.statusText.text = (self.friendName! + " is not in game.")
        }
    }
    
    func setupViews(parentSize:Int, friendUserName:String, currentUID:String){
        self.friendUserName = friendUserName
        self.currentUID = currentUID
        userNameText.text = " (" + friendUserName + ")"
        mRef = Database.database().reference()
        
        nameText.font = nameText.font.withSize(18)
        userNameText.font = userNameText.font.withSize(14)
        statusText.font = statusText.font.withSize(14)
        friendImage.translatesAutoresizingMaskIntoConstraints = false
        nameText.translatesAutoresizingMaskIntoConstraints = false
        userNameText.translatesAutoresizingMaskIntoConstraints = false
        statusText.translatesAutoresizingMaskIntoConstraints = false
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        declineButton.translatesAutoresizingMaskIntoConstraints = false
        joinGameButton.translatesAutoresizingMaskIntoConstraints = false
        /*
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat:
            "H:|-5-[v0(" + String(parentSize / 8) + ")]-5-[v1]-2-[v2][v3(" + String(parentSize / 8) + ")][v4(" + String(parentSize / 8) + ")][v5(" + String(parentSize / 8) + ")]-4-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": friendImage , "v1": nameText, "v2": userNameText, "v3":acceptButton, "v4":declineButton, "v5":joinGameButton]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat:
            "H:|-5-[v0(" + String(parentSize / 8) + ")]-5-[v1][v3(" + String(parentSize / 8) + ")][v4(" + String(parentSize / 8) + ")][v5(" + String(parentSize / 8) + ")]-4-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": friendImage , "v1": statusText, "v3":acceptButton, "v4":declineButton, "v5":joinGameButton]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat:
            "V:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": friendImage]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat:
            "V:|-5-[v0]-10-[v1]-5-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": nameText, "v1":statusText]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat:
            "V:|-5-[v0]-10-[v1]-5-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": userNameText, "v1":statusText]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat:
            "V:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": acceptButton]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat:
            "V:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": declineButton]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat:
            "V:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": joinGameButton]))
 */
        
        
        //find the UID of user so name and game status can be gathered
        mRef.child("friendUID").observeSingleEvent(of: .value, with: { (dataSnapshot) in
            if(dataSnapshot.childSnapshot(forPath: friendUserName).exists()) {
                self.friendUID = dataSnapshot.childSnapshot(forPath: friendUserName).value as! String
                
                //find name and game status
                self.mRef.child("users/" + self.friendUID + "/userInfo").observe(.value, with: { (dataSnapshot) in
                    if(dataSnapshot.childSnapshot(forPath: "name").exists()) {
                        self.friendName = dataSnapshot.childSnapshot(forPath: "name").value as? String ?? friendUserName
                        self.nameText.text = self.friendName
                        
                        if (dataSnapshot.childSnapshot(forPath: "inGame").exists()) {
                            self.friendGameStatus = dataSnapshot.childSnapshot(forPath: "inGame").value as? String
                        }
                        
                        //get currentUserName
                        self.mRef.child("users/" + self.currentUID + "/userInfo").observeSingleEvent(of: .value, with: { (dataSnapshot) in
                            self.currentUserName = dataSnapshot.childSnapshot(forPath: "userName").value as! String
                            self.currentName = dataSnapshot.childSnapshot(forPath: "name").value as? String
                            if (dataSnapshot.childSnapshot(forPath: "inGame").exists()){
                                self.currentGame = dataSnapshot.childSnapshot(forPath: "inGame").value as? String
                                self.mRef.child("friendUID/" + self.currentGame!).observeSingleEvent(of: .value, with: { (dataSnapshot) in
                                    self.currentGameUID = dataSnapshot.value as? String
                                }, withCancel: { (error) in
                                    //add alert
                                })
                            }
                        }, withCancel: { (error) in
                            //add alert
                        })
                        
                        self.mRef.child("users/" + self.currentUID + "/friends/users/" + self.friendUserName).observeSingleEvent(of: .value, with: { (dataSnapshot) in
                            //if the friend request needs to be accepted, and it is from another user
                            if (dataSnapshot.childSnapshot(forPath: "from").exists() && dataSnapshot.childSnapshot(forPath: "requestAccepted").exists()){
                                let requestAccepted:Bool = dataSnapshot.childSnapshot(forPath: "requestAccepted").value as! Bool
                                let from:Bool = dataSnapshot.childSnapshot(forPath: "from").value as! Bool
                                if (!requestAccepted && from) {
                                    //the accept and decline buttons will be shown
                                    self.acceptButton.isHidden = false
                                    self.declineButton.isHidden = false
                                    self.joinGameButton.isHidden = true
                                    self.statusText.text = "Accept friend request?"
                                    
                                    //if friend request needs to be accepted, and current user sent it,
                                } else if (!requestAccepted && !from) {
                                    self.acceptButton.isHidden = true
                                    self.declineButton.isHidden = true
                                    self.joinGameButton.isHidden = true
                                    self.statusText.text = "Waiting for " + self.friendName! + " to accept."
                                }
                                
                                //if the friend request has been accepted, join button will show
                                if (requestAccepted) {
                                    
                                    //checkGameStatus(view, tempName, tempUID, tempUserName, tempGameStatus);
                                    self.checkGameStatus()
                                }
                            }
                        }, withCancel: { (error) in
                            //add alert
                        })
                        
                        self.mRef.child("users/" + currentUID + "/friends/" + friendUserName).observe(.childChanged, with: { (dataSnapshot) in
                            //if the friend request needs to be accepted, and it is from another user
                            if (dataSnapshot.childSnapshot(forPath: "from").exists() && dataSnapshot.childSnapshot(forPath: "requestAccepted").exists()){
                                let requestAccepted:Bool = dataSnapshot.childSnapshot(forPath: "requestAccepted").value as! Bool
                                let from:Bool = dataSnapshot.childSnapshot(forPath: "from").value as! Bool
                                if (!requestAccepted && from) {
                                    //the accept and decline buttons will be shown
                                    self.acceptButton.isHidden = false
                                    self.declineButton.isHidden = false
                                    self.joinGameButton.isHidden = true
                                    self.statusText.text = "Accept friend request?"
                                    
                                    //if friend request needs to be accepted, and current user sent it,
                                } else if (!requestAccepted && !from) {
                                    self.acceptButton.isHidden = true
                                    self.declineButton.isHidden = true
                                    self.joinGameButton.isHidden = true
                                    self.statusText.text = "Waiting for " + self.friendName! + " to accept."
                                }
                                
                                //if the friend request has been accepted, join button will show
                                if (requestAccepted) {
                                    
                                    //checkGameStatus(view, tempName, tempUID, tempUserName, tempGameStatus);
                                    self.checkGameStatus()
                                }
                            }

                        }, withCancel: { (error) in
                            
                        })
                    }
                }, withCancel: { (error) in
                    //add alert
                })
                
            }

        }) { (error) in
            //add alert
        }
    }
    
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
