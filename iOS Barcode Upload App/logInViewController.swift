//
//  logInViewController.swift
//  iOS Barcode Upload App
//
//  Created by Yiyan Zhai on 5/25/23.
//

import UIKit

class logInViewController: UIViewController {

    @IBOutlet weak var email_text: UITextField!
    @IBOutlet weak var password_text: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    var onUpdateProfile: ((String, String?) -> Void)?
    
    @IBAction func logInTapped(_ sender: Any) {
        guard let username = self.email_text.text, !username.isEmpty,
              let userpassword = password_text.text, !userpassword.isEmpty else {
            displayWarning("Empty Field", "All fields are required.")
            return
        }
        
        signIn(username: username, password: userpassword)
    }
    
    
    func getUserInfo() {
        // Get the access token from UserDefaults or wherever it's stored
        guard let accessToken = UserDefaults.standard.string(forKey: "access") else {
            print("Access token not found")
            return
        }
        // Create the request URL
        guard let url = URL(string: "http://128.2.25.96:8003/auth/userinfo/") else {
            print("Invalid URL")
            return
        }
        // Create the request object
        var request = URLRequest(url: url)
        // Set the request method to GET
        request.httpMethod = "GET"
        // Set the Authorization header with the Bearer token
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        print("Bearer \(accessToken)")
        // Create a URLSession task for the request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                self.displayWarning("Getting User Information Failed","Request error: \(error)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                self.displayWarning("Getting User Information Failed","Invalid response")
                return
            }
            // Check the status code of the response
            if httpResponse.statusCode == 200 {
                // Handle the successful response
                if let data = data {
                    do {
                        // Parse the JSON response
                        let json = try JSONSerialization.jsonObject(with: data, options: [])
                        if let responseJSON = json as? [String: Any],
                           let username = responseJSON["username"] as? String,
                           let user_id = responseJSON["user_id"] as? Int {
                            let defaults = UserDefaults.standard
                            defaults.set(username, forKey: "username")
                            var imageURL = "https://img.freepik.com/free-icon/user_318-563642.jpg?w=360"
                            if let user_profile_url = responseJSON["user_profile_url"] as? String {
                                print("User Profile URL: \(user_profile_url)")
                                imageURL = user_profile_url
                                defaults.set(user_profile_url, forKey: "user_profile_url")
                            } else {
                                let defaultUrl = "https://img.freepik.com/free-icon/user_318-563642.jpg?w=360"
                                defaults.set(defaultUrl, forKey: "user_profile_url")
                            }
                            self.onUpdateProfile?(username, imageURL)
                            defaults.set(user_id, forKey: "user_id")
                            // Handle the user information
                            print("Username: \(username)")
                            print("User ID: \(user_id)")
                        } else {
                            self.displayWarning("Getting User Information Failed","Invalid server response")
                        }
                    } catch {
                        self.displayWarning("Getting User Information Failed","JSON parsing error: \(error)")
                    }
                } else {
                    self.displayWarning("Getting User Information Failed","No data received")
                }
            } else {
                // Handle the error response
                if let data = data {
                    do {
                        // Parse the JSON error response
                        let json = try JSONSerialization.jsonObject(with: data, options: [])
                        if let errorJSON = json as? [String: Any],
                           let detail = errorJSON["detail"] as? String {
                            // Handle the error message
                            self.displayWarning("Getting User Information Failed","Error: \(detail)")
                        } else {
                            self.displayWarning("Getting User Information Failed","Invalid error response")
                        }
                    } catch {
                        self.displayWarning("Getting User Information Failed","JSON parsing error: \(error)")
                    }
                } else {
                    self.displayWarning("Getting User Information Failed","No data received")
                }
            }
        }
        
        // Start the URLSession task
        task.resume()
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
        guard let url = URL(string: "http://128.2.25.96:8003/auth/login/token/") else {
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
                print("log in succeed with status code 200")
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
                    defaults.set(username, forKey: "username")
                    self?.saveLoginDate()
                    self?.getUserInfo()
                    // Access the app delegate instance
                    DispatchQueue.main.async {
                        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                            // Call the startTokenRefreshTimer() method
                            print("Refreshing restarted after logging in...")
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
