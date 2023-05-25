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
    
    @IBAction func logInTapped(_ sender: Any) {
        guard let username = self.email_text.text, !username.isEmpty,
              let userpassword = password_text.text, !userpassword.isEmpty else {
            displayWarning("Empty Field", "All fields are required.")
            return
        }
        
        
        // store data to server
//        signIn(username: username, password: userpassword)
        let defaults = UserDefaults.standard
        defaults.set(username, forKey: "Username")
        defaults.set(true, forKey: "isLoggedIn")
        self.dismiss(animated: true, completion: nil)
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
        // ***********
        guard let url = URL(string: "<server_url>/sign_in") else {
            displayWarning("Error", "Invalid server URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData

        // Create a URLSession task for the request
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            if let error = error {
                self?.displayWarning("Sign in failed", "Failed to Sign in: \(error.localizedDescription)")
            } else {
                // Check the server response and handle accordingly
                if let data = data,
                   let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let success = responseJSON["success"] as? Bool {
                    if success {
                        let defaults = UserDefaults.standard
                        defaults.set(username, forKey: "Username")
                        self?.dismiss(animated: true, completion: nil)
                    } else {
                        if let message = responseJSON["message"] as? String {
                            self?.displayWarning("Sign in failed", "\(message)")
                        } else {
                            self?.displayWarning("Sign in failed", "Please try again.")
                        }
                    }
                } else {
                    self?.displayWarning("Sign in failed", "Failed to parse server response")
                }
            }
        }

        // Start the URLSession task
        task.resume()
    }
    
    
    
    func displayWarning(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }


}
