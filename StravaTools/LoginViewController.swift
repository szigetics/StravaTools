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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.isEnabled = !StravaAPIClient.sharedInstance.isLoggedIn()
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        StravaAPIClient.sharedInstance.authenticate(self) { error in
            print("error : \(String(describing: error))")
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
