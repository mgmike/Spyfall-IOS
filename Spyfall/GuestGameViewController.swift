	//
//  GuestGameViewController.swift
//  Spyfall
//
//  Created by Mike Eng on 7/18/17.
//  Copyright © 2017 Mike. All rights reserved.
//

import UIKit
import Firebase

class GuestGameViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var currentUID:String!
    var currentUserName:String!
    var currentName:String?
    var inGame:String!
    var hostUID:String!
    var hostName:String?
    var location:String!
    var time = 0
    var locationArrayList:[String] = []
    var playerArrayList:[String] = []
    var mRef:DatabaseReference!
    var startTime:Int64?
    var timer:Timer?
    
    @IBOutlet weak var leaveGameButton: UIButton!
    @IBOutlet weak var hideRoleButton: UIButton!
    @IBOutlet weak var roleText: UILabel!
    @IBOutlet weak var timeText: UILabel!
    @IBOutlet weak var playersView: UIView!
    @IBOutlet weak var locationsView: UIView!
    @IBOutlet weak var locationCollectionView: UICollectionView!
    @IBOutlet weak var playerCollectionView: UICollectionView!
    
    @IBAction func onLeaveGame(_ sender: Any) {
        print(hostUID)
        print(currentUserName)
        mRef.child("users/" + hostUID + "/currentGame/users/" + currentUserName).removeValue();
        mRef.child("users/" + currentUID + "/userInfo/inGame").removeValue();
        self.performSegue(withIdentifier: "toMain2", sender: self)
    }
    
    @IBAction func onHideRole(_ sender: Any) {
        if (hideRoleButton.currentTitle == "Hide role") {
            self.hideRoleButton.setTitle("Show role", for: .normal)
            roleText.text  = ("Play fair!");
        } else {
            self.hideRoleButton.setTitle("Hide role", for: .normal)
            displayRole();
        }
    }
    
    
    
    func populateLocationList() {
        mRef = Database.database().reference()
        mRef.child("defaultLocations").observeSingleEvent(of: .value, with: { (dataSnapshot) in
            self.locationArrayList.removeAll()
            var i:Int = 1
            for temp in dataSnapshot.children.allObjects as! [DataSnapshot]{
                self.locationArrayList.append(temp.key)
                self.locationCollectionView.cellForItem(at: IndexPath(row: i, section: 0))
                i += 1
            }
            DispatchQueue.main.async(execute: {
                self.locationCollectionView.reloadData()
            })
        }, withCancel: { (error) in
            //add alert
        })
    }
    
    func populatePlayerList(){
        mRef = Database.database().reference()
        let playersRef:DatabaseReference = mRef.child("users").child(hostUID).child("currentGame").child("users") //-------change this-------//
        //for all the current players in the game, add to the list (if not already done)
        playersRef.observeSingleEvent(of: .value, with: { (dataSnapshot) in
            let enumerator = dataSnapshot.children
            while let tempPlayer = enumerator.nextObject() as? DataSnapshot {
                self.playerArrayList.append(tempPlayer.key)
            }
            DispatchQueue.main.async(execute: {
                print("relaoding data1")
                self.playerCollectionView.reloadData()
            })
            
            //when a new child in the database is added, add a Player object in the playerArrayList list so the collection view can update
            playersRef.observe(.childAdded, with: { (dataSnapshot) in
                if(!self.playerArrayList.contains(dataSnapshot.key)){
                    print("adding " + dataSnapshot.key)
                    self.playerArrayList.append(dataSnapshot.key)
                    DispatchQueue.main.async(execute: {
                        print("relaoding data2")
                        self.playerCollectionView.reloadData()
                    })
                }
            }) { (error) in
                //add alert here
            }
            
            //when a child is removed from the database, it will be removed from the arraylist as well
        playersRef.observe(.childRemoved, with: { (dataSnapshot) in
            if(dataSnapshot.key == self.currentUserName){
                self.performSegue(withIdentifier: "toMain2", sender: self)
            } else {
                print("get rid of " + dataSnapshot.key)
                let index:Int = self.playerArrayList.index(of: dataSnapshot.key)!
                self.playerArrayList.remove(at: index)
                DispatchQueue.main.async(execute: {
                    print("relaoding data3")
                    self.playerCollectionView.reloadData()
                })
            }
            }) { (error) in
                //add alert here
            }
            
        }) { (error) in
            //add alert
        }
    }
    
    
    func displayRole() {
        mRef.child("users/" + self.hostUID + "/currentGame").observeSingleEvent(of: .value, with: { (dataSnapshot) in
            self.location = dataSnapshot.childSnapshot(forPath: "location").value as! String
            print(self.location)
            let role:String = (dataSnapshot.childSnapshot(forPath: "users").childSnapshot(forPath: self.currentUserName).childSnapshot(forPath: "role").value as! String)
            print(role)
            if (role == "Spy") {
                self.roleText.text = "You are the Spy!"
            } else {
                self.roleText.text = "The location is " + self.location + ".\nYour Role is " + role + "."
            }
        }) { (error) in
            //add alert
        }
    }
    
    func updateUI(currentLocSnapshot:DataSnapshot){
        if (currentLocSnapshot.exists()) {
            //no game is occurring or game has ended
            //update locationView cells alpha here
            print(currentLocSnapshot.key)
            if (currentLocSnapshot.key == "location"){
                self.location = (currentLocSnapshot.value as! String)
                if (self.location == "none") {
                    if (self.hostName == nil) {
                        self.mRef.child("users/" + self.hostUID + "/userInfo/name").observeSingleEvent(of: .value, with: { (dataSnapshot) in
                            self.hostName = dataSnapshot.value as? String ?? ""
                            self.roleText.text = ("Waiting for " + self.hostName! + " to start!")
                        }, withCancel: { (error) in
                            //add alert
                        })
                    } else {
                        self.roleText.text = ("Waiting for " + self.hostName! + " to start!")
                    }
                    self.leaveGameButton.isHidden = false
                    self.hideRoleButton.isHidden = true
                    
                    if(timer != nil){
                        timer?.invalidate()
                    }
                    
                    //if time ends, times up will stay
                    if(timeText.text != ("Time's up!")){
                        timeText.text = String(time / 60) + ":00"
                    }
                    //update timer when host changes it
                    
                    
                    if (self.location == ("none") && self.timeText.text != ("Time's up!") && self.startTime != nil) {
                        self.timeText.text = (String(startTime! / 60000) + ":00")
                    } else if (self.startTime == nil){
                        self.timeText.text = "8:00"
                    }
                    
                    //self.mRef.child("users/" + self.hostUID + "/currentGame/users/" + self.currentUserName).child("time").removeValue()
                    
                    //game is in progress
                } else {
                    self.displayRole()
                    self.leaveGameButton.isHidden = true
                    self.hideRoleButton.isHidden = false
                    self.hideRoleButton.setTitle("Hide role", for: .normal)
                    
                    //set up timer
                    mRef.child("users/" + hostUID + "/currentGame").observeSingleEvent(of: .value, with: { (dataSnapshot) in
                        /*
                        if let endTime:String = dataSnapshot.childSnapshot(forPath: "endTime").value as? String{
                            var endTimeArray:[String] = endTime.components(separatedBy: ":")
                            var currentTimeArray:[String] = self.getCurrentTime().components(separatedBy: ":")
                            for i in 0...4 {
                                if ((Int(endTimeArray[i])! - Int(currentTimeArray[i])!) > 0){
                                    print(String(i) + " " + endTimeArray[i] + " " + currentTimeArray[i])
                                }
                            }
                            self.time = (Int(endTimeArray[4])! - Int(currentTimeArray[4])!) * 60 + (Int(endTimeArray[5])! - Int(currentTimeArray[5])!)
                            print(endTimeArray[4] + " " +  currentTimeArray[4] + " " + endTimeArray[5] + " " +  currentTimeArray[5])
                            if self.timer != nil{
                                self.timer?.invalidate()
                            }
                            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.counter), userInfo: nil, repeats: true)
                        }*/
                        
                        
                        if let endTime:Int = dataSnapshot.childSnapshot(forPath: "endTime").value as? Int{
                            let currentTime:Int = Int(NSDate().timeIntervalSince1970 * 1000)
                            self.time = (endTime - currentTime)
                            if self.timer != nil{
                                self.timer?.invalidate()
                            }
                            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.counter), userInfo: nil, repeats: true)
                        }
                        
                        
                        /*
                        long rightNow = Calendar.getInstance().getTimeInMillis();
                        if (dataSnapshot.child("startTime").exists()) {
                            startTime = Integer.parseInt(dataSnapshot.child("startTime").getValue().toString());
                        }
                        if (dataSnapshot.child("users").child(currentUserName).child("time").exists()) {
                            long timeLeft = startTime - (rightNow - Long.parseLong(dataSnapshot.child("time").getValue().toString()));
                            if (timeLeft > 0 && timeLeft < startTime) {
                                timer = new CounterClass(timeLeft, 1000);
                                timer.start();
                            }
                        } else {
                            mRef = FirebaseDatabase.getInstance().getReference("users/" + hostUID + "/currentGame/users/" + currentUserName);
                            mRef.child("time").setValue(rightNow);
                            timer = new CounterClass(startTime - 1000, 1000);
                            timer.start();
                        }
                        */
                    }, withCancel: { (error) in
                        //add alert
                    })
                }
            }
            
            //host has left game
        }

    }
    
    func startUp(){
        mRef = Database.database().reference()
        mRef.child("users/" + currentUID + "/userInfo").observeSingleEvent(of: .value, with: { (currentUserInfoSnapshot) in
            self.currentUserName = currentUserInfoSnapshot.childSnapshot(forPath: "userName").value as! String
            self.inGame = currentUserInfoSnapshot.childSnapshot(forPath: "inGame").value as! String
            self.mRef.child("friendUID").observeSingleEvent(of: .value, with: { (friendUIDSnapshot) in
                self.hostUID = friendUIDSnapshot.childSnapshot(forPath: self.inGame).value as! String
                //loads screen when user just segued into scene
                self.mRef.child("users/" + self.hostUID + "/currentGame").observeSingleEvent(of: .value, with: { (dataSnapshot) in
                    self.startTime = dataSnapshot.childSnapshot(forPath: "startTime").value as? Int64
                    self.updateUI(currentLocSnapshot: dataSnapshot.childSnapshot(forPath: "location"))
                }, withCancel: { (error) in
                    //add alert
                })
                
                //changes whenever location is updated
                self.mRef.child("users/" + self.hostUID + "/currentGame").observe(.childChanged, with: { (dataSnapshot) in
                    if(dataSnapshot.key == "location"){
                        self.updateUI(currentLocSnapshot: dataSnapshot)
                    } else if (dataSnapshot.key == "startTime"){
                        self.startTime = dataSnapshot.value as? Int64
                        if(self.location == "none"){
                            self.timeText.text = (String(self.startTime! / 60000) + ":00")
                        }
                    }
                }, withCancel: { (error) in
                    //add alert
                })
                
                self.populatePlayerList()
                
                /*
                //insert start time into database
                //fix this after android
                self.mRef.child("users/" + self.hostUID + "/currentGame/startTime").observe(.childChanged, with: { (dataSnapshot) in
                 
                    if(dataSnapshot.exists()){
                        startTime = Integer.parseInt(dataSnapshot.getValue().toString())
                    }
                }, withCancel: { (error) in
                    //add alert
                })
                 */
                
            }, withCancel: { (error) in
                //add alert
            })
        }, withCancel: { (error) in
            //add alert
        })
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        
        
        if let user = Auth.auth().currentUser {
            currentUID = user.uid
            //creates game in database0
            mRef = Database.database().reference()
            startUp()
            //sets up location list
            self.populateLocationList()
            
            //creates a list of players
            //self.populatePlayerList()
            
        } else {
            print("None")
            performSegue(withIdentifier: "signedOut", sender: self)
        }
        
        //sets up collection views
        locationCollectionView.delegate = self
        locationCollectionView.dataSource = self
        playerCollectionView.delegate = self
        playerCollectionView.dataSource = self
        //sets up the ui stuff
        locationsView.layer.cornerRadius = 6
        locationsView.layer.borderWidth = 2
        playersView.layer.cornerRadius = 6
        playersView.layer.borderWidth = 2
        leaveGameButton.layer.cornerRadius = 6
        leaveGameButton.layer.borderWidth = 2
        hideRoleButton.layer.cornerRadius = 6
        hideRoleButton.layer.borderWidth = 2
        
        self.playerCollectionView.contentInset = UIEdgeInsetsMake(6, 0, 0, 0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getCurrentTime() -> String{
        let date = Date()
        let calendar = Calendar.current
        let year:String = String(calendar.component(.year, from: date))
        let month:String = String(calendar.component(.month, from: date))
        let day:String = String(calendar.component(.day, from: date))
        let hour:String = String(calendar.component(.hour, from: date))
        let minute:String = String(calendar.component(.minute, from: date))
        let sec:String = String(calendar.component(.second , from: date))
        
        return(year + ":" + month + ":" + day + ":" + hour + ":" + minute + ":" + sec)
    }
    
    func counter() {
        time -= 1
        if (time % 60 > 10){
            timeText.text = (String(time / 60) + ":" + String(time % 60))
        } else {
            timeText.text = (String(time / 60) + ":0" + String(time % 60))
        }
        
        if(time <= 0){
            timer?.invalidate()
        }
    }
    
    func getStartTime(){
        
        self.mRef.child("users/" + self.hostUID + "/currentGame/startTime").observeSingleEvent(of: .value, with: { (dataSnapshot) in
            self.startTime = dataSnapshot.value as? Int64
        }) { (error) in
            //add alert
        }
        
        self.mRef.child("users/" + self.hostUID + "/currentGame/startTime").observe(.childChanged, with: { (dataSnapshot) in
            self.startTime = dataSnapshot.value as? Int64
        }, withCancel: { (error) in
            //add alert
        })
        
    }
    
    
    //***************************v Collection View v*******************************\\
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(collectionView == locationCollectionView){
            return self.locationArrayList.count
        } else {
            return self.playerArrayList.count
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if(collectionView == locationCollectionView){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "locationItem", for: indexPath) as! CollectionViewCell
            cell.locationButton = cell.viewWithTag(1) as! UIButton
            cell.setText(text: self.locationArrayList[indexPath.item])
            cell.layer.cornerRadius = 6
            cell.layer.borderWidth = 2
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "playerItem", for: indexPath) as! PlayerCollectionViewCell
            cell.setupViews(parentSize: Int(self.playerCollectionView.frame.width), hostUID: self.hostUID, tempUserName: playerArrayList[indexPath.item], showKickButton: false)
            cell.backgroundColor = UIColor(colorLiteralRed: 235/255, green: 123/255, blue: 45/255, alpha: 0.8)
            cell.layer.cornerRadius = 6
            cell.layer.borderWidth = 2
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(collectionView == playerCollectionView){
            print("a player was pressed")
            let cell = playerCollectionView.cellForItem(at: indexPath) as! PlayerCollectionViewCell
            if cell.isClicked {
                cell.backgroundColor = UIColor(colorLiteralRed: 235/255, green: 123/255, blue: 45/255, alpha: 0.48)
                cell.isClicked = false
            } else{
                cell.backgroundColor = UIColor(colorLiteralRed: 235/255, green: 123/255, blue: 45/255, alpha: 0.8)
                cell.isClicked = true
            }
            playerCollectionView.deselectItem(at: indexPath, animated: false)
        } else {
            print("a location was pressed")
            let cell = locationCollectionView.cellForItem(at: indexPath) as! CollectionViewCell
            if cell.isClicked {
                cell.backgroundColor = UIColor(colorLiteralRed: 235/255, green: 123/255, blue: 45/255, alpha: 0.48)
                cell.isClicked = false
            } else{
                cell.backgroundColor = UIColor(colorLiteralRed: 235/255, green: 123/255, blue: 45/255, alpha: 0.8)
                cell.isClicked = true
            }
            locationCollectionView.deselectItem(at: indexPath, animated: false)
        }
    }
    
    //***************************^ Collection View ^*******************************\\
    

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
