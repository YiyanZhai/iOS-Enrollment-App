//
//  AppDelegate.swift
//  iOS Barcode Upload App
//
//  Created by Yiyan Zhai on 5/12/23.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var tokenRefreshTimer: Timer?
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "goLogIn" {
//            if let presentedVC = segue.destination as? logInViewController {
//                presentedVC.isModalInPresentation = true
//            }
//        }
//    }
    
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Perform actions when the app is about to enter the foreground
        // Check if the user needs to re-login
        print("applicationWillEnterForeground...")
        let defaults = UserDefaults.standard
        let isLoggedIn = defaults.bool(forKey: "isLoggedIn")
        
        if isLoggedIn {
            let lastLoginDate = defaults.object(forKey: "lastLoginDate") as? Date
            let currentDate = Date()
            
            let timeElapsed = currentDate.timeIntervalSince(lastLoginDate ?? Date.distantPast)
            let reloginInterval: TimeInterval = 30 * 60 // 30 minutes
            
            
            
            if timeElapsed >= reloginInterval {
                // Perform re-login action
                DispatchQueue.main.async {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let keyWindow = windowScene.windows.first {
                        keyWindow.rootViewController?.performSegue(withIdentifier: "goLogin", sender: self)
                    }
                }
            }
        }

    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleLogoutNotification() {
        print("log out handler")
        // Call the stopTokenRefreshTimer function
        stopTokenRefreshTimer()
    }
    func stopTokenRefreshTimer() {
        tokenRefreshTimer?.invalidate()
        tokenRefreshTimer = nil
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        NotificationCenter.default.addObserver(self, selector: #selector(handleLogoutNotification), name: Notification.Name("LogoutNotification"), object: nil)
        
        let lastLoginDate = UserDefaults.standard.object(forKey: "LastLoginDate") as? Date
        let currentDate = Date()
        
        let timeInterval = currentDate.timeIntervalSince(lastLoginDate ?? currentDate)
        let elapsedTimeInSeconds = Int(timeInterval)
        print("elapsedTimeInSeconds: ", elapsedTimeInSeconds)
        
        let maxElapsedTimeInSeconds = 5 // Unit: second

        if elapsedTimeInSeconds > maxElapsedTimeInSeconds {
            print("needed")
            // Too much time has elapsed, force the user to login again
            // Present the login view controller or perform the segue to the login view controller
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
            
//            DispatchQueue.main.async {
//                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//                   let keyWindow = windowScene.windows.first {
//                    keyWindow.rootViewController?.performSegue(withIdentifier: "goLogin", sender: self)
//                }
//            }
        }
        startTokenRefreshTimer()
        return true
    }
    
    func startTokenRefreshTimer() {
        print("startTokenRefreshTimer called")
        tokenRefreshTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            let defaults = UserDefaults.standard
            let refreshtoken = defaults.string(forKey: "refresh")
            self?.refreshAccessToken(refreshToken: refreshtoken ?? "no") { result in
                switch result {
                case .success(let accessToken):
                    // Handle successful access token refresh
                    print("Access Token: \(accessToken)")
                case .failure(let error):
                    // Handle error
                    print("Error refreshing access token: \(error)")
                }
            }
        }
    }
    

    func refreshAccessToken(refreshToken: String, completion: @escaping (Result<String, Error>) -> Void) {
        print("refreshAccessToken")
        guard let url = URL(string: "http://128.2.25.96:8000/auth/login/token/refresh/") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "refresh": refreshToken
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }
        
        // Create a URLSession task for the request
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("success with status code 200")
                // Successful response
                if let data = data,
                   let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let access = responseJSON["access"] as? String,
                   let refresh = responseJSON["refresh"] as? String {
                    // Store access and refresh tokens
                    let defaults = UserDefaults.standard
                    defaults.set(access, forKey: "access")
                    defaults.set(refresh, forKey: "refresh")
                    print("refresh after refresh: ", refresh)
                } else {
                    print("Refresh failed", "Invalid server response")
                }
            } else {
                if let httpResponse = response as? HTTPURLResponse {
                    print(httpResponse.statusCode)
                }
                // Handle error response
                if let data = data,
                   let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let message = responseJSON["detail"] as? String {
                    print("Refresh failed", "\(message)")
                } else {
                    print("Refresh failed", "Please try again.")
                }
                DispatchQueue.main.async {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let keyWindow = windowScene.windows.first {
                        keyWindow.rootViewController?.performSegue(withIdentifier: "goLogin", sender: self)
                    }
                }
            }
        }

        task.resume()
    }



    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

