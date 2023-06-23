//
//  logInViewController.swift
//  iOS Barcode Upload App
//
//  Created by Yiyan Zhai on 5/25/23.
//

import UIKit

protocol LogInViewControllerDelegate: AnyObject {
    func setUsernameText(_ username: String)
}

class logInViewController: UIViewController {
    weak var delegate: LogInViewControllerDelegate?


    @IBOutlet weak var email_text: UITextField!
    @IBOutlet weak var password_text: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func logInTapped(_ sender: Any) {
        guard let username = self.email_text.text, !username.isEmpty,
              let userpassword = password_text.text, !userpassword.isEmpty else {
            displayWarning("Empty Field", "All fields are required.")
            return
        }
        
        signIn(username: username, password: userpassword)
        
//        let defaults = UserDefaults.standard
//        if let refresh = defaults.string(forKey: "refresh") {
//            print(refresh)
//        } else {
//            print("Refresh token not found")
//        }
    }

    
    func signIn(username: String, password: String) {

        // Create the request body
        let requestBody: [String: Any] = [
            "username": username,
            "password": password
        ]
        
        // Convert the request body to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            displayWarning("Error", "Failed to convert request body to JSON data")
            return
        }

        // Configure the request
        guard let url = URL(string: "http://128.2.25.96:8000/auth/login/token/") else {
            displayWarning("Error", "Invalid server URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create a URLSession task for the request
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("log in success with status code 200")
                // Successful response
                if let data = data,
                   let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let access = responseJSON["access"] as? String,
                   let refresh = responseJSON["refresh"] as? String {
                    // Store access and refresh tokens
                    let defaults = UserDefaults.standard
                    defaults.set(access, forKey: "access")
                    defaults.set(refresh, forKey: "refresh")
                    defaults.set(true, forKey: "isLoggedIn")
                    self?.saveLoginDate()
                    
                    
                    print("getting user info")
                    guard let url1 = URL(string: "http://128.2.25.96:8000/auth/userinfo") else {
                        print("Invalid URL")
                        return
                    }
                    
                    guard let accessToken = defaults.string(forKey: "access") else {
                        print("no access token")
                        return
                    }
                    
                    var request1 = URLRequest(url: url1)
                    request1.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                    
                    // Create a URLSession task for the request
                    let task1 = URLSession.shared.dataTask(with: request1) { [weak self] (data1, response1, error1) in
                        if let httpResponse1 = response1 as? HTTPURLResponse, httpResponse1.statusCode == 200 {
                            print("get user info success with status code 200")
                            // Successful response
                            if let data2 = data1,
                               let responseJSON1 = try? JSONSerialization.jsonObject(with: data2, options: []) as? [String: Any],
                               let username_ = responseJSON1["username"] as? String {
//                               let profile_image_url_ = responseJSON["profile_image_url"] as? String {
                                    print("get user info succeed")
                                    // Store access and refresh tokens
                                    let defaults = UserDefaults.standard
                                    defaults.set(username_, forKey: "username")
//                                    defaults.set(profile_image_url_, forKey: "profile_image_url")
                            } else {
                                print("get user info failed")
                            }
                        } else {
                            // Handle error response
                            self?.displayWarning("get user info failed", "Please try again.")
//                            if let data2 = data1,
//                               let responseJSON1 = try? JSONSerialization.jsonObject(with: data2, options: []) as? [String: Any],
//                               let message = responseJSON["detail"] as? String {
//                                self?.displayWarning("get user info failed", "\(message)")
//                            } else {
//                                self?.displayWarning("get user info failed", "Please try again.")
//                            }
                        }
                    }

                    // Start the URLSession task
                    task1.resume()
                    
                    // Access the app delegate instance
                    DispatchQueue.main.async {
                        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                            // Call the startTokenRefreshTimer() method
                            print("refresh restart")
                            appDelegate.startTokenRefreshTimer()
                        }
                        self?.dismiss(animated: true, completion: nil)
                    }
                } else {
                    self?.displayWarning("Sign in failed", "Invalid server response")
                }
            } else {
                // Handle error response
                if let data = data,
                   let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let message = responseJSON["detail"] as? String {
                    self?.displayWarning("Sign in failed", "\(message)")
                } else {
                    self?.displayWarning("Sign in failed", "Please try again.")
                }
            }
        }

        // Start the URLSession task
        task.resume()
    }
    
    func saveLoginDate() {
        let currentDate = Date()
        print(currentDate)
        UserDefaults.standard.set(currentDate, forKey: "LastLoginDate")
    }

    
    func displayWarning(_ title: String, _ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }


}
