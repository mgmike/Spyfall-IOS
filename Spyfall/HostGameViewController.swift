//
//  HostGameViewController.swift
//  Spyfall
//
//  Created by Mike Eng on 6/30/17.
//  Copyright © 2017 Mike. All rights reserved.
//

import UIKit
import Firebase


class HostGameViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource{
    
    var currentUID:String!
    var currentUserName:String!
    var location:String!
    var time = 480
    var locationArrayList:[String] = []	
    var playerArrayList:[String] = []
    var mRef:DatabaseReference!
    var timer:Timer!
    
    @IBOutlet weak var startGameButton: UIButton!
    @IBOutlet weak var leaveGameButton: UIButton!
    @IBOutlet weak var hideRoleButton: UIButton!
    @IBOutlet weak var roleText: UILabel!
    @IBOutlet weak var timeText: UILabel!
    @IBOutlet weak var timeChange: UIStepper!
    @IBOutlet weak var locationCollectionView: UICollectionView!
    @IBOutlet weak var playerCollectionView: UICollectionView!
    @IBOutlet weak var locationsView: UIView!
    @IBOutlet weak var playersView: UIView!
    
    
    func displayRole() {
        mRef.child("users/" + currentUID + "/currentGame").observeSingleEvent(of: .value, with: { (dataSnapshot) in
            let loc:String = dataSnapshot.childSnapshot(forPath: "location").value as! String
            let role:String = dataSnapshot.childSnapshot(forPath: "users/" + self.currentUserName! + "/role").value as! String
            if (role == "Spy") {
                self.roleText.text = "You are the Spy!"
            } else {
                self.roleText.text = "The location is " + loc + ".\nYour Role is " + role + "."
            }
        }) { (error) in
            //add alert
        }
    }
    
    func populateLocationList() {
        mRef = Database.database().reference()
        mRef.child("defaultLocations").observeSingleEvent(of: .value, with: { (dataSnapshot) in
            self.locationArrayList.removeAll()
            var i:Int = 1
            for temp in dataSnapshot.children.allObjects as! [DataSnapshot]{
                self.locationArrayList.append(temp.key)
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
        let playersRef:DatabaseReference = mRef.child("users").child(currentUID).child("currentGame").child("users")
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
                print("get rid of " + dataSnapshot.key)
                let index:Int = self.playerArrayList.index(of: dataSnapshot.key)!
                self.playerArrayList.remove(at: index)
                DispatchQueue.main.async(execute: {
                    print("relaoding data3")
                    self.playerCollectionView.reloadData()
                })
            }) { (error) in
                //add alert here
            }
            
        }) { (error) in
            //add alert
        }
    }
    
    @IBAction func onHideRole(_ sender: Any) {
        if (self.hideRoleButton.currentTitle == "Hide role") {
            self.hideRoleButton.setTitle("Show role", for: .normal)
            self.roleText.text = "Play fair!"
        } else {
            self.hideRoleButton.setTitle("Hide role", for: .normal)
            displayRole()
        }
    }
    
    @IBAction func onLeaveGame(_ sender: Any) {
        mRef.child("friendUID").observeSingleEvent(of: .value, with: { (friendUIDSnapshot) in
            self.mRef.child("users/" + self.currentUID + "/currentGame/users").observeSingleEvent(of: .value, with: { (dataSnapshot) in
                //removes inGame status for each player
                for temp in dataSnapshot.children.allObjects as! [DataSnapshot] {
                    self.mRef.child("users/" + (friendUIDSnapshot.childSnapshot(forPath: temp.childSnapshot(forPath: "userName").value as! String).value as! String) + "/userInfo/inGame").removeValue()
                }
                self.mRef.child("users").child(self.currentUID).child("userInfo").child("inGame").removeValue()
                self.mRef.child("users").child(self.currentUID).child("currentGame").removeValue()
                self.performSegue(withIdentifier: "toMain", sender: self)
            }, withCancel: { (error) in
                //add alert
            })
        }) { (error) in
            //add alert
        }
    }
    
    @IBAction func onTimeChange(_ sender: UIStepper) {
        time = Int(timeChange.value) * 60
        timeText.text = String(time / 60) + ":00"
        mRef.child("users/" + currentUID + "/currentGame/startTime").setValue(self.time * 1000)
    }
    
    @IBAction func onStartGame(_ sender: Any) {
        //finds location
        mRef.child("users/" + currentUID + "/currentGame/location").observeSingleEvent(of: .value, with: { (dataSnapshot) in
            self.location = dataSnapshot.value as! String
            
            // host just started game. start the game
            if (self.location == "none") {
                self.startGameButton.setTitle("End Game", for: .normal)
                self.leaveGameButton.isHidden = true
                self.hideRoleButton.isHidden = false
                self.timeChange.isHidden = true
                
                
                //Creates a list of all players
                self.mRef.child("users/" + self.currentUID + "/currentGame/users").observeSingleEvent(of: .value, with: { (dataSnapshot) in
                    let playerCount:Int =  Int(dataSnapshot.childrenCount)
                    var i:Int = 0
                    var playerList = [[String]](repeating: [String](repeating:"", count:2), count: playerCount)
                    for temp in dataSnapshot.children.allObjects as! [DataSnapshot] {
                        playerList[i][0] = temp.key
                        print(playerList[i][0])
                        i += 1
                    }
                    
                    //picks a random location and updates database
                    let randomNum:Int  = Int(arc4random_uniform(UInt32(self.locationArrayList.count)))
                    self.location = self.locationArrayList[randomNum]

                    self.mRef.child("defaultLocations/" + self.location).observeSingleEvent(of: .value, with: { (dataSnapshot) in
                        let rolesCount:Int = Int(dataSnapshot.childSnapshot(forPath: "roles").childrenCount)
                        var roleList = [String](repeating: "", count: playerCount)
                        //if there are less players than roles then roles are assigned as normal
                        if((playerCount - 1) <= rolesCount && playerCount > 0){
                            for j in 0..<(playerCount - 1) {
                                roleList[j] = dataSnapshot.childSnapshot(forPath: "roles").childSnapshot(forPath: String(j)).value as! String
                            }
                            roleList[playerCount - 1] = "Spy"
                            //if there are more players than roles, then repeats are used
                        } else {
                            for j in 0..<(rolesCount){
                                roleList[j] = dataSnapshot.childSnapshot(forPath: "roles").childSnapshot(forPath: String(j)).value as! String
                                print(roleList[j])
                            }
                            let playersLeft:Int = playerCount - rolesCount - 1
                            let repeatCount:Int = Int(dataSnapshot.childSnapshot(forPath: "repeats").childrenCount)
                            for k in 0..<(playersLeft){
                                roleList[rolesCount + k] = dataSnapshot.childSnapshot(forPath: "repeats").childSnapshot(forPath: String((playersLeft - k) % repeatCount)).value as! String
                                print(roleList[rolesCount + k])
                            }
                            roleList[playerCount - 1] = "Spy"
                        }
                        
                        //Assigns each player a role
                        var tempSub:Int
                        for k in 0..<(playerCount) {
                            tempSub = Int(arc4random_uniform(UInt32(playerCount)))
                            while (playerList[tempSub][1] != "") {
                                tempSub = Int(arc4random_uniform(UInt32(playerCount)))
                            }
                            playerList[tempSub][1] = roleList[k]
                            print(playerList[tempSub][0] + "------" + playerList[tempSub][1])
                        }
                        
                        //updates the database
                        for l in 0..<(playerCount) {
                            self.mRef.child("users/" + self.currentUID + "/currentGame").child("users/" + (playerList[l][0]) + "/role").setValue(playerList[l][1])
                        }
                        self.displayRole();
                        
                        //sets up timer and updates database
                        /*
                        var currentTime:String = self.getCurrentTime()
                        var currentTimeArray:[String] = currentTime.components(separatedBy: ":")
                        var endTime:String = (currentTimeArray[0] + ":")
                        endTime += (currentTimeArray[1] + ":")
                        endTime += (currentTimeArray[2] + ":")
                        endTime += (currentTimeArray[3] + ":")
                        var mins = Int(currentTimeArray[4])! + (self.time / 60)
                        endTime += (String(mins) + ":")
                        endTime += currentTimeArray[5]
                        print(currentTime + " " + endTime)
                        self.mRef.child("users/" + self.currentUID + "/currentGame/endTime").setValue(endTime)
                        if self.timer != nil{
                            self.timer.invalidate()
                        }
                        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.counter), userInfo: nil, repeats: true)
                        */
                        let currentTime:Int = Int(NSDate().timeIntervalSince1970 * 1000)
                        let endTime:Int = currentTime + (self.time * 1000)
                        self.mRef.child("users/" + self.currentUID + "/currentGame/endTime").setValue(endTime)
                        if self.timer != nil{
                            self.timer.invalidate()
                        }
                        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.counter), userInfo: nil, repeats: true)
                        
                        
                        //remove all kick buttons in the collectionview
                        for i in 0..<self.playerCollectionView.numberOfItems(inSection: 0){
                            let cell = self.playerCollectionView.cellForItem(at: IndexPath(item: i, section: 0)) as! PlayerCollectionViewCell
                            cell.location = self.location
                            cell.updateButtons()
                        }
                        
                    }, withCancel: { (error) in
                        //add alert
                    })
                    
                    self.mRef.child("users/" + self.currentUID + "/currentGame/location").setValue(self.location)
                }, withCancel: { (error) in
                    //add alert
                })
            //if the host ends the game...
            } else {
                self.mRef.child("users/" + self.currentUID + "/currentGame").observeSingleEvent(of: .value, with: { (startTimeSnapshot) in
                    if(startTimeSnapshot.childSnapshot(forPath: "startTime").exists()){
                        self.time = (startTimeSnapshot.childSnapshot(forPath: "startTime").value as! Int) / 1000
                    } else {
                        self.time = 480
                    }
                    print(self.time)
                    self.timeChange.value = Double(self.time / 60)
                    self.timer.invalidate()
                    self.timeText.text = String(String(self.time / 60) + ":00")
                    self.mRef.child("users/" + self.currentUID + "/currentGame/endTime").removeValue()
                }, withCancel: { (error) in
                    //add alert
                })
                /*
                if(!timeText.getText().equals("Time's up!")) {
                    String time = String.format("%02d:%02d", TimeUnit.MILLISECONDS.toMinutes(startTime),
                                                TimeUnit.MILLISECONDS.toSeconds(startTime) - TimeUnit.MINUTES.toSeconds(TimeUnit.MILLISECONDS.toMinutes(startTime)));
                    timeText.setText(time);
                }
                */
                self.startGameButton.setTitle("Start Game", for: .normal)
                self.leaveGameButton.isHidden = false
                self.hideRoleButton.isHidden = true
                self.timeChange.isHidden = true
                self.roleText.text = "Pres 'Start Game' to begin!"
                self.mRef.child("users/" + self.currentUID + "/currentGame/location").setValue("none")
                self.mRef.child("users/" + self.currentUID + "/currentGame/users").observeSingleEvent(of: .value, with: { (dataSnapshot) in
                    for temp in dataSnapshot.children.allObjects as! [DataSnapshot] {
                        self.mRef.child("users/" + self.currentUID + "/currentGame/users").child(temp.key).child("role").removeValue()
                    }
                }, withCancel: { (error) in
                    //add alert
                })
                //put all kick buttons in collectionview back
                for i in 0..<self.playerCollectionView.numberOfItems(inSection: 0){
                    let cell = self.playerCollectionView.cellForItem(at: IndexPath(item: i, section: 0)) as! PlayerCollectionViewCell
                    cell.location = self.location
                    cell.updateValues()
                }
                self.timeChange.isHidden = false
            }
        
        }) { (error) in
            //place alert
        }
    
    }

    
    func counter() {
        time -= 1
        if (time % 60 > 10){
            timeText.text = (String(time / 60) + ":" + String(time % 60))
        } else {
            timeText.text = (String(time / 60) + ":0" + String(time % 60))
        }
        
        if(time == 0){
            timer.invalidate()
            onStartGame(self)
        }
    }
    
    func updateUI(){
        var gameOver:Bool = false
        //grabs username and populates currentGame field in database if not already populated
        mRef.child("users/" + self.currentUID!).observeSingleEvent(of: .value, with: { (dataSnapshot) in
            self.currentUserName = dataSnapshot.childSnapshot(forPath: "userInfo/userName").value as! String
            if (dataSnapshot.childSnapshot(forPath: "currentGame").exists() == false){
                let ref:DatabaseReference = self.mRef.child("users/" + self.currentUID + "/currentGame")
                ref.child("location").setValue("none")
                ref.child("host").setValue(self.currentUserName)
                ref.child("users/" + self.currentUserName + "/userName").setValue(self.currentUserName)
                self.mRef.child("users/" + self.currentUID + "/userInfo/inGame").setValue(self.currentUserName)
            }
        }, withCancel: { (error) in
            //place alert here
        })
        
        mRef.child("users/" + self.currentUID + "/currentGame").observeSingleEvent(of: .value, with: { (dataSnapshot) in
            
            if (dataSnapshot.childSnapshot(forPath: "location").exists()) {
                self.location = dataSnapshot.childSnapshot(forPath: "location").value as! String
                
            } else {
                self.location = "none"
            }
            //if user is in lobby, screen will update
            if (self.location == "none") {
                self.startGameButton.isHidden = false
                self.startGameButton.setTitle("StartGame", for: .normal)
                self.leaveGameButton.isHidden = false
                self.hideRoleButton.isHidden = true
                self.timeChange.isHidden = false
                self.roleText.text = "Press 'Start Game' to begin!"
                if(self.timeText.text != "Time's up!") {
                    if (dataSnapshot.childSnapshot(forPath: "startTime").exists()){
                        let startTimeTemp:DataSnapshot = dataSnapshot.childSnapshot(forPath: "startTime")
                        self.time = Int(startTimeTemp.value as! Int64) / 1000
                        self.timeText.text = String(self.time / 60) + ":00"
                        self.timeChange.value = Double(self.time / 60)
                    } else {
                        self.timeText.text = "8:00"
                    }
                }
                //if user is mid game, screen will update
            } else {
                print(self.location)
                self.startGameButton.isHidden = false
                self.startGameButton.setTitle("End Game", for: .normal)
                self.leaveGameButton.isHidden = true
                self.hideRoleButton.isHidden = false
                self.timeChange.isHidden = true
                self.displayRole()
                
                //set up the timer based on how much time is left
                /*
                if let endTime:Int = dataSnapshot.childSnapshot(forPath: "endTime").value as? Int{
                    var current:[String] = self.getCurrentTime().components(separatedBy: ":")
                    for i in 0...4 {
                        if ((Int(endTimeArray[i])! - Int(currentTimeArray[i])!) > 0){
                            print(String(i) + " " + endTimeArray[i] + " " + currentTimeArray[i])
                        } else {
                            gameOver = true
                        }
                    }
                    self.time = (Int(endTimeArray[4])! - Int(currentTimeArray[4])!) * 60 + (Int(endTimeArray[5])! - Int(currentTimeArray[5])!)
                    print(endTimeArray[4] + " " +  currentTimeArray[4] + " " + endTimeArray[5] + " " +  currentTimeArray[5])
                    if self.timer != nil{
                        self.timer.invalidate()
                    }
                    self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.counter), userInfo: nil, repeats: true)
                }*/
                
                
                if let endTime:Int = dataSnapshot.childSnapshot(forPath: "endTime").value as? Int{
                    let currentTime:Int = Int(NSDate().timeIntervalSince1970 * 1000)
                    if ((endTime - currentTime) > 0){
                        print(endTime)
                        print(currentTime)
                        self.time = (endTime - currentTime) / 1000
                        if self.timer != nil{
                            self.timer.invalidate()
                        }
                        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.counter), userInfo: nil, repeats: true)
                    } else {
                        gameOver = true
                    }
                }
                
            }
        }, withCancel: { (error) in
            //place alert here
        })
        
        if gameOver == true {
            self.timeText.text = "Time's up!"
            print("Restarting Game")
            self.onStartGame(self)
        }
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
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /*
        DispatchQueue.main.async(execute: {
            print("relaoding data0")
            print(String(self.playerCollectionView.numberOfItems(inSection: 0)) + "&&&&&")
            self.playerCollectionView.reloadData()
            print(String(self.playerArrayList.count) + "&&&&&&&")
        })
 */
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        /*
        playerArrayList.removeAll()
        for i in 0..<playerCollectionView.numberOfItems(inSection: 0){
            playerCollectionView.deleteItems(at: [IndexPath(item: i, section: 0)])
            DispatchQueue.main.async(execute: {
                print("deleting old cells")
                self.playerCollectionView.reloadData()
            })
        }
        */
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateUI()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        
        if let user = Auth.auth().currentUser {
            currentUID = user.uid
            //creates game in database
            mRef = Database.database().reference()
            timer = Timer()
            updateUI()
            //sets up location list
            self.populateLocationList()
            
            //creates a list of players
            self.populatePlayerList()
            
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
        startGameButton.layer.cornerRadius = 6
        startGameButton.layer.borderWidth = 2
        leaveGameButton.layer.cornerRadius = 6
        leaveGameButton.layer.borderWidth = 2
        hideRoleButton.layer.cornerRadius = 6
        hideRoleButton.layer.borderWidth = 2
        
        self.playerCollectionView.contentInset = UIEdgeInsetsMake(6, 0, 0, 0)
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
            //cell.temp = cell.viewWithTag(1) as! UILabel
            //cell.setText(text: playerArrayList[indexPath.item].userName)
            cell.setupViews(parentSize: Int(self.playerCollectionView.frame.width), hostUID: self.currentUID, tempUserName: playerArrayList[indexPath.item], showKickButton: true)
            cell.layer.cornerRadius = 6
            cell.layer.borderWidth = 2
            print(playerArrayList.count)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = playerCollectionView.cellForItem(at: indexPath) as! PlayerCollectionViewCell
        if cell.isClicked {
            cell.backgroundColor = UIColor(colorLiteralRed: 0.922, green: 0.482, blue: 0.176, alpha: 0.48)
            cell.isClicked = false
        } else{
            cell.backgroundColor = UIColor(colorLiteralRed: 0.922, green: 0.482, blue: 0.176, alpha: 0.8)
            cell.isClicked = true
        }
        playerCollectionView.deselectItem(at: indexPath, animated: false)
    }
    
    //***************************^ Collection View ^*******************************\\

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











