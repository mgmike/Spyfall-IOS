//
//  FriendViewController.swift
//  Spyfall
//
//  Created by Mike Eng on 7/1/17.
//  Copyright © 2017 Mike. All rights reserved.
//

import UIKit
import Firebase

class FriendViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var currentUID:String!
    var mRef:DatabaseReference!
    var friendsArrayList:[String] = []
    
    @IBOutlet weak var userName: UIStackView!
    @IBOutlet weak var friendsCollectionView: UICollectionView!
    
    func onJoinGame(){
        self.performSegue(withIdentifier: "joinGame", sender: self)
        /*
        self.mRef.child("users/" + self.currentUID + "/userInfo").observeSingleEvent(of: .value, with: { (dataSnapshot) in
            self.currentUserName = dataSnapshot.childSnapshot(forPath: "userName").value as! String
            self.currentName = dataSnapshot.childSnapshot(forPath: "name").value as! String
            if (dataSnapshot.childSnapshot(forPath: "inGame").exists()){
                var inGame:String = dataSnapshot.childSnapshot(forPath: "inGame").value as! String
                if (inGame == self.currentUserName){
                    self.mRef.child("users/" + self.currentUID + "/currentGame").removeValue()
                    self.mRef.child("users/" + self.currentUID + "/userInfo/inGame").setValue(inGame)
                    self.performSegue(withIdentifier: "joinGame", sender: self)
                } else {
                    self.mRef.child("friendUID/" + inGame).observeSingleEvent(of: .value, with: { (dataSnapshot) in
                        if (dataSnapshot.exists()){
                            self.mRef.child("users/" + (dataSnapshot.value as! String) + "/currentGame/users/" + self.currentUserName).removeValue()
                            self.mRef.child("users/" + self.currentUID + "/userInfo/inGame").setValue(inGame)
                            self.performSegue(withIdentifier: "joinGame", sender: self)
                        }
                    }, withCancel: { (error) in
                        //add alert
                    })
                }
            }
        }) { (error) in
            //add alert
        }
        */
    }
    
    func populateFriendsList(){
        mRef = Database.database().reference()
        let playersRef:DatabaseReference = mRef.child("users").child(currentUID).child("friends").child("users")
        //for all the current players in the game, add to the list (if not already done)
        playersRef.observeSingleEvent(of: .value, with: { (dataSnapshot) in
            let enumerator = dataSnapshot.children
            while let tempPlayer = enumerator.nextObject() as? DataSnapshot {
                self.friendsArrayList.append(tempPlayer.key)
            }
            DispatchQueue.main.async(execute: {
                print("relaoding data1")
                self.friendsCollectionView.reloadData()
            })
            
            //when a new child in the database is added, add a Player object in the playerArrayList list so the collection view can update
            playersRef.observe(.childAdded, with: { (dataSnapshot) in
                if(!self.friendsArrayList.contains(dataSnapshot.key)){
                    print("adding " + dataSnapshot.key)
                    self.friendsArrayList.append(dataSnapshot.key)
                    DispatchQueue.main.async(execute: {
                        print("relaoding data2")
                        self.friendsCollectionView.reloadData()
                    })
                }
            }) { (error) in
                //add alert here
            }
            
            //when a child is removed from the database, it will be removed from the arraylist as well
            playersRef.observe(.childRemoved, with: { (dataSnapshot) in
                print("get rid of " + dataSnapshot.key)
                let index:Int = self.friendsArrayList.index(of: dataSnapshot.key)!
                self.friendsArrayList.remove(at: index)
                DispatchQueue.main.async(execute: {
                    print("relaoding data3")
                    self.friendsCollectionView.reloadData()
                })
            }) { (error) in
                //add alert here
            }
            
        }) { (error) in
            //add alert
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let user = Auth.auth().currentUser {
            self.currentUID = user.uid
            self.mRef = Database.database().reference()
            //sets up location list
            self.populateFriendsList()
            
        } else {
            print("None")
            //performSegue(withIdentifier: "signedOut", sender: self)
        }
        
        friendsCollectionView.delegate = self
        friendsCollectionView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.friendsArrayList.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "friendItem", for: indexPath) as! FriendCollectionViewCell
        cell.setupViews(parentSize: Int(self.friendsCollectionView.frame.width), friendUserName: friendsArrayList[indexPath.item], currentUID: currentUID)
        cell.layer.cornerRadius = 6
        cell.layer.borderWidth = 2
        cell.joinGameButton.addTarget(self, action: #selector(onJoinGame), for: .touchUpInside)
        return cell
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

extension FriendViewController: CollectionViewCellDelegate{
    func collectionViewCell(_ cell: UICollectionViewCell, buttonTapped: UIButton){
        self.performSegue(withIdentifier: "joinGame", sender: self)
    }
}
