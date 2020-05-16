//
//  StravaAPIClient.swift
//  StravaTools
//
//  Created by Csaba Szigeti on 2020. 05. 16..
//  Copyright © 2020. Csaba Szigeti. All rights reserved.
//

import Foundation
import OAuth2

class StravaAPIClient {
    private var oauth: OAuth2 {
        let oauth = OAuth2CodeGrant(settings: [
        "client_id": self.clientID(),
        "client_secret": self.clientSecret(),
        "authorize_uri": "https://www.strava.com/oauth/authorize",
        "token_uri": "https://www.strava.com/oauth/token",
        "response_type": "code",
        "approval_prompt": "force",
        "redirect_uris": ["stravatest://localhost"], // scheme registered in Info.plist
        "scope": "activity:read_all",
        "parameters": [
            "client_id": "46551",
            "client_secret": "614236a56bd82ba38a3893b33571ee866ef94e1d"
        ],
        "verbose": true,
        ] as OAuth2JSON)
        
        oauth.authConfig.authorizeEmbedded = true
        oauth.logger = OAuth2DebugLogger(.trace)
        return oauth
    }
    static let sharedInstance = StravaAPIClient()
    
    private func readFile(fileName: String, fileType: String) -> String{
        guard let filePathURL = Bundle.main.url(forResource: fileName, withExtension: fileType) else {
            return ""
        }
        guard let contents = try? NSString(contentsOf: filePathURL, encoding: String.Encoding.utf8.rawValue) as String else {
            return ""
        }
        return contents
    }
    
    private func clientID() -> String {
        return readFile(fileName: "strava", fileType: "clientID")
    }
    
    private func clientSecret() -> String {
        return readFile(fileName: "strava", fileType: "clientSecret")
    }
    
    typealias AuthenticateCallback = (_ error: OAuth2Error?) -> Void
    func authenticate(_ context: AnyObject?, completion: @escaping AuthenticateCallback) {
        oauth.authConfig.authorizeContext = context
        oauth.authorize { (a: OAuth2JSON?, error: OAuth2Error?) in
            if error != nil {
                return
            }
            //            self.currentAthlete()
            self.listActivities()
        }
    }
    
    func isLoggedIn() -> Bool {
        return oauth.hasUnexpiredAccessToken()
    }
    
    func handleRedirectURL(_ url: URL) {
        do {
            try oauth.handleRedirectURL(url)
        } catch {
            print("Unexpected error: \(error).")
        }
    }
    
    func currentAthlete() {
        //TODO
    }
    
    func listActivities() {
        //TODO
    }
}
