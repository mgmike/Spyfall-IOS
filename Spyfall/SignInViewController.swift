//
//  SignInViewController.swift
//  Spyfall
//
//  Created by Mike Eng on 6/14/17.
//  Copyright © 2017 Mike. All rights reserved.
//

import UIKit
import Firebase

class SignInViewController: UIViewController {
    
    @IBOutlet weak var emailTextView: UITextField!
    @IBOutlet weak var passwordTextView: UITextField!
    
    var email:String!
    var password:String!
    
    //add an alert
    var myAlert = UIAlertController(title: "Log In error.", message: "Alert", preferredStyle: UIAlertControllerStyle.alert)
    
    
    @IBAction func signInButton(_ sender: Any) {
        print("button pressed")
        if Auth.auth().currentUser != nil{
            do{
                try Auth.auth().signOut()
                print("success")
            } catch let logoutError {
                print(logoutError)
            }
        }
        
    
        email = emailTextView.text
        password = passwordTextView.text

        
        if !email.contains("@"){
            myAlert.message = "Invalid e-mail."
            self.present(self.myAlert, animated: true, completion: nil)
        } else if (password.unicodeScalars.count < 6){
            myAlert.message = "Password is too short!"
            self.present(myAlert, animated: true, completion: nil)
        } else {
        
            Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                if (user != nil){
                    print(user?.email ?? "No email.")
                    print(user?.uid ?? "No uid.")
                    self.performSegue(withIdentifier: "signedIn", sender: self)
                } else {
                    if let myError = error?.localizedDescription{
                        self.myAlert.message = myError
                        self.present(self.myAlert, animated: true, completion: nil)
                    } else {
                        self.myAlert.message = "An error has occured."
                        self.present(self.myAlert, animated: true, completion: nil)
                    }
                }
                
                
            }
            
        }
        print("all done")
        
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        myAlert.addAction(UIAlertAction(title:"Continue",style: UIAlertActionStyle.default, handler:nil))
        if Auth.auth().currentUser != nil {
            performSegue(withIdentifier: "signedIn", sender: self)
        } else {
            print("No currentUser")
        }

        // Do any additional setup after loading the view.
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
