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
    
    typealias ShowResultAction = (() -> Void)
    private func showResult(_ title: String, _ message: String, _ okButtonPressed: ShowResultAction? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            okButtonPressed?()
        }))

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
            
            self.showResult("Success", String(describing: activities), {
                let alert = UIAlertController(title: "Open?", message: "Would you like to open longest activity in a browser?", preferredStyle: .alert)

                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                    guard let longestActivity = longest, let url = URL(string: "https://www.strava.com/activities/\(longestActivity.id)") else { return }
                    UIApplication.shared.open(url, completionHandler: nil)
                }))
                
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))

                self.present(alert, animated: true)
            })
        }
    }
    
    private static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    var activityIndicatorContainer: UIView? = nil //blocking touches meanwhile `activityIndicator` is visible
    var activityIndicatorBackground: UIView? = nil
    var activityIndicator: UIActivityIndicatorView? = nil
    var activityIndicatorLabel: UILabel? = nil
    
    func showActivityIndicatory(uiView: UIView) {
        activityIndicatorContainer = UIView()
        guard let container = activityIndicatorContainer else {
            return
        }
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.white.withAlphaComponent(0.3)

        activityIndicator = UIActivityIndicatorView()
        guard let actInd = activityIndicator else {
            return
        }
        actInd.translatesAutoresizingMaskIntoConstraints = false
        actInd.style = UIActivityIndicatorView.Style.large
        actInd.color = UIColor.white
        actInd.startAnimating()
        
        activityIndicatorLabel = UILabel()
        guard let label = activityIndicatorLabel else {
            return
        }
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.white
        label.text = "Loading..."
        
        activityIndicatorBackground = UIView()
        guard let indicatorBackground = activityIndicatorBackground else {
            return
        }
        indicatorBackground.translatesAutoresizingMaskIntoConstraints = false
        indicatorBackground.backgroundColor = UIColor.gray
        indicatorBackground.layer.cornerRadius = 10
        container.addSubview(indicatorBackground)
        indicatorBackground.addSubview(actInd)
        indicatorBackground.addSubview(label)
        uiView.addSubview(container)
        
        //container fills the view
        container.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        container.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        container.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        container.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        indicatorBackground.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        indicatorBackground.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true
        
        let views = ["actInd": actInd, "label": label]
        actInd.centerXAnchor.constraint(equalTo: indicatorBackground.centerXAnchor).isActive = true
        indicatorBackground.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[label]-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        indicatorBackground.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[actInd]-[label]-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
    }
    
    func hideActivityIndicator() {
        activityIndicator?.stopAnimating()
        activityIndicatorContainer?.removeFromSuperview()
        activityIndicatorContainer = nil
        activityIndicator?.removeFromSuperview()
        activityIndicator = nil
        activityIndicatorBackground?.removeFromSuperview()
        activityIndicatorBackground = nil
    }
    
    let activityCacheContainerPath: URL = LoginViewController.getDocumentsDirectory().appendingPathComponent("allActivities")
    lazy var activityCacheFullPath: URL = activityCacheContainerPath.appendingPathComponent("all.saved")
    @IBAction func cacheAllActivitiesButtonPressed(_ sender: Any) {
        showActivityIndicatory(uiView: self.view)
        StravaAPIClient.sharedInstance.listAllActivities(completion: {  (allActivities: [Activity], error: Error?) in
            self.hideActivityIndicator()
            self.updateLogInLogOutButtonsState()

            if error != nil {
                self.showResult("Error", String(describing: error))
                return
            }

            do {
                try FileManager.default.createDirectory(at: self.activityCacheContainerPath, withIntermediateDirectories: true, attributes: nil)
                let data = try JSONEncoder().encode(allActivities)
                try data.write(to: self.activityCacheFullPath)
            } catch {
                print("Couldn't write file")
            }
        }) { (count) in
            print("number of activities loaded so far : \(count)")
            self.activityIndicatorLabel?.text = "Loaded \(count) activities..."
        }
    }
    
    @IBAction func showOnMapButtonPressed(_ sender: Any) {
        guard FileManager.default.fileExists(atPath: activityCacheFullPath.path) else {
            showResult("Activities not cached yet", "Please cache all activities first!")
            return
        }
        
        self.navigationController?.pushViewController(MapViewController(), animated: true)
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
