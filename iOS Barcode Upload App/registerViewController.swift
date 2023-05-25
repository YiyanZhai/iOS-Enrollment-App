//
//  registerViewController.swift
//  iOS Barcode Upload App
//
//  Created by Yiyan Zhai on 5/24/23.
//

import UIKit

class registerViewController: UIViewController {

    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var repeatPassword: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var usrname: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func registerButtonTapped(_ sender: Any) {
        guard let username = self.usrname.text, !username.isEmpty,
              let usrpassword = password.text, !usrpassword.isEmpty,
              let usrrepeatPassword = repeatPassword.text, !usrrepeatPassword.isEmpty else {
            displayWarning("Empty Field", "All fields are required.")
            return
        }
        
        if (usrpassword != usrrepeatPassword) {
            displayWarning("Different Passwords", "Passwords do not match.")
            return
        }
        
        // store data to server
//        signUp(username: username, password: usrpassword)
        let successAlert = UIAlertController(title: "Registration Succeed", message: "Registration is completed, thank you!", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            self.dismiss(animated: true, completion: nil)
        }
        successAlert.addAction(okAction)
        self.present(successAlert, animated: true, completion: nil)
    }
    
    
    
    @IBAction func backToSignIn(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func signUp(username: String, password: String) {
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
        guard let url = URL(string: "<server_url>/sign_up") else {
            displayWarning("Error", "Invalid server URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData

        // Create a URLSession task for the request
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            if let error = error {
                self?.displayWarning("Sign up failed", "Failed to Sign up: \(error.localizedDescription)")
            } else {
                // Check the server response and handle accordingly
                if let data = data,
                   let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let success = responseJSON["success"] as? Bool {
                    if success {
                        let successAlert = UIAlertController(title: "Registration Succeed", message: "Registration is completed, thank you!", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                            self?.dismiss(animated: true, completion: nil)
                        }
                        successAlert.addAction(okAction)
                        self?.present(successAlert, animated: true, completion: nil)
                    } else {
                        if let message = responseJSON["message"] as? String {
                            self?.displayWarning("Sign up failed", "\(message)")
                        } else {
                            self?.displayWarning("Sign up failed", "Please try again.")
                        }
                    }
                } else {
                    self?.displayWarning("Sign up failed", "Failed to parse server response")
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
