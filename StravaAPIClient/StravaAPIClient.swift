//
//  StravaAPIClient.swift
//  StravaTools
//
//  Created by Csaba Szigeti on 2020. 05. 16..
//  Copyright © 2020. Csaba Szigeti. All rights reserved.
//

import Foundation
import OAuth2
import Alamofire

class StravaAPIClient {
    let base = URL(string: "https://www.strava.com/api/v3")!
    
    static let sharedInstance = StravaAPIClient()
    var oauth: OAuth2
    var loader: OAuth2DataLoader? = nil
    
    init() {
        self.oauth = OAuth2CodeGrant(settings: [
            "client_id": StravaAPIClient.clientID(),
            "client_secret": StravaAPIClient.clientSecret(),
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
    }
    
    static private func readFile(fileName: String, fileType: String) -> String{
        guard let filePathURL = Bundle.main.url(forResource: fileName, withExtension: fileType) else {
            return ""
        }
        guard let contents = try? NSString(contentsOf: filePathURL, encoding: String.Encoding.utf8.rawValue) as String else {
            return ""
        }
        return contents
    }
    
    static private func clientID() -> String {
        return readFile(fileName: "strava", fileType: "clientID")
    }
    
    static private func clientSecret() -> String {
        return readFile(fileName: "strava", fileType: "clientSecret")
    }
    
    typealias AuthenticateCallback = (_ error: OAuth2Error?) -> Void
    func authenticate(_ context: AnyObject?, completion: @escaping AuthenticateCallback) {
        oauth.authConfig.authorizeContext = context
        oauth.authorize { (a: OAuth2JSON?, error: OAuth2Error?) in
            completion(error)
        }
    }
    
    func handleRedirectURL(_ url: URL) {
        do {
            try oauth.handleRedirectURL(url)
        } catch {
            print("Unexpected error: \(error).")
        }
    }
    
    func isLoggedIn() -> Bool {
        return oauth.hasUnexpiredAccessToken()
    }
    
    typealias LogoutCallback = () -> Void
    func logOut(completion: @escaping LogoutCallback) {
        oauth.forgetTokens()
        completion()
    }
    
    typealias CurrentAthleteCallback = (_ json: OAuth2JSON?, _ error: Error?) -> Void
    func currentAthlete(completion: @escaping CurrentAthleteCallback) {
        let url = base.appendingPathComponent("athlete")
        
        let req = self.oauth.request(forURL: url)
        
        self.loader = OAuth2DataLoader(oauth2: self.oauth)
        self.loader?.perform(request: req) { response in
            do {
                let dict = try response.responseJSON()
                DispatchQueue.main.async {
                    completion(dict, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
    
    typealias ListActivitiesCallback = (_ activities: [Activity], _ error: Error?) -> Void
    func listActivities(page: Int = 1,
                        per_page: Int = 30, //30 is the Strava API default value
                        completion: @escaping ListActivitiesCallback) {
        //Note : OAuth2DataLoader fails to parse the JSON so we use Alamofire instead to send the request and process the response
        let url = base.appendingPathComponent("athlete/activities")
        
        let interceptor = OAuth2RetryHandler(oauth)
        AF.request(url, method: .get, parameters: [ "page": "\(page)", "per_page": "\(per_page)" ], interceptor: interceptor)
            .validate()
            .response { response in
                switch response.result {
                case .success(let data):
                    guard let data = data else {
                        completion([], NSError(domain:"", code:1, userInfo:nil))
                        return
                    }
                    do {
                        print("\(String(describing: String(data: data, encoding: .utf8)))")
                        
                        let decoder = JSONDecoder()
                        let activities = try decoder.decode([Activity].self, from: data)
                        completion(activities, nil)
                    } catch {
                        print("Error with data \(String(describing: String(data: data, encoding: .utf8)))")
                        print("failure \(error)")
                        completion([], NSError(domain:"", code:2, userInfo:nil))
                    }
                case .failure(let error):
                    print("failure \(error)")
                    completion([], NSError(domain:"", code:3, userInfo:nil))
                }
        }
    }
    
    typealias ListAllActivitiesProgressCallback = (_ numberOfDownloadedActivities: Int) -> Void
    func listAllActivities(completion: @escaping ListActivitiesCallback, progress: @escaping ListAllActivitiesProgressCallback) {
        let maxAllowedPerPageValue = 200
        
        var page = 0
        var allActivities: [Activity] = []
        
        var requestNextPage: (() -> Void)!
        requestNextPage = { [weak self] in
            guard let self = self else { return }
            page += 1
            self.listActivities(page: page, per_page: maxAllowedPerPageValue) {  (activities: [Activity], error: Error?) in
                if error != nil {
                    completion(allActivities, error)
                    return
                }
                
                if activities.count > 0 {
                    allActivities.append(contentsOf: activities)
                    progress(allActivities.count)
                    print("loading more pages...")
                    requestNextPage()
                } else {
                    print("no more pages")
                    completion(allActivities, error)
                }
            }
        }
        requestNextPage()
    }
}
