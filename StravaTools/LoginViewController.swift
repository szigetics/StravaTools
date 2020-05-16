//
//  LoginViewController.swift
//  StravaTools
//
//  Created by Csaba Szigeti on 2020. 05. 16..
//  Copyright © 2020. Csaba Szigeti. All rights reserved.
//

import UIKit
import SwiftUI

final class LoginViewController: UIViewController {

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        StravaAPIClient.sharedInstance.oauth.authConfig.authorizeContext = self
        
        updateLogInLogOutButtonsState()
    }
    
    private func updateLogInLogOutButtonsState() {
        loginButton.isEnabled = !StravaAPIClient.sharedInstance.isLoggedIn()
        logoutButton.isEnabled = StravaAPIClient.sharedInstance.isLoggedIn()
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        StravaAPIClient.sharedInstance.authenticate(self) { error in
            self.updateLogInLogOutButtonsState()
            
            if error != nil {
                self.showResult("Error", String(describing: error))
                return
            }
            
            self.showResult("Success", "Successfully logged in")
        }
    }
    
    @IBAction func logOutButtonPressed(_ sender: Any) {
        StravaAPIClient.sharedInstance.logOut() {
            self.updateLogInLogOutButtonsState()
        }
    }
    
    private func showResult(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        self.present(alert, animated: true)
    }
    
    @IBAction func currentAthleteButtonPressed(_ sender: Any) {
        StravaAPIClient.sharedInstance.currentAthlete { (json, error) in
            self.updateLogInLogOutButtonsState()
            
            if error != nil {
                self.showResult("Error", String(describing: error))
                return
            }
            
            self.showResult("Success", String(describing: json))
        }
    }
    
    @IBAction func listActivitiesButtonPressed(_ sender: Any) {
        StravaAPIClient.sharedInstance.listActivities { (activities: [Activity], error: Error?) in
            self.updateLogInLogOutButtonsState()
            
            if error != nil {
                self.showResult("Error", String(describing: error))
                return
            }
            
            let act = activities.filter { $0.distance == 15684.8 }
            print(act)
            
            let longest = activities.max{$0.distance < $1.distance}
            print(longest ?? "failed to find longest activity")
            
            let max_speed = activities.max{$0.max_speed < $1.max_speed}
            print(max_speed ?? "failed to find acitivity with highest speed")
            
            let max_heartrate = activities.max{$0.max_heartrate ?? 0 < $1.max_heartrate ?? 0}
            print(max_heartrate ?? "failed to find acitivity with highest max heart rate")
            
            self.showResult("Success", String(describing: activities))
        }
    }
    
}

extension LoginViewController: UIViewControllerRepresentable {
    public typealias UIViewControllerType = LoginViewController
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<LoginViewController>) -> LoginViewController {
        return LoginViewController()
    }
    
    func updateUIViewController(_ uiViewController: LoginViewController, context: UIViewControllerRepresentableContext<LoginViewController>) {
    }
}
