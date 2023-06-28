//
//  TestViewController.swift
//  iOS Barcode Upload App
//
//  Created by Yiyan Zhai on 6/22/23.
// av foundation codebase
import UIKit
//import PhotosUI
import Foundation

class FinalViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    var barcodeValue: String = ""
    var productImageDatas: [String] = []
    var barcodeImageData = ""
    var flagVal = 0
    var testImageDatas: [String] = []
    var testMetadata: [String] = []
    var productMetadata: [String] = []
//    var barcodeMetadata = ""
    
    @IBOutlet weak var pic: UIImageView!
    @IBOutlet weak var UsernameTextBox: UITextField!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goLogIn4" {
            if let presentedVC = segue.destination as? logInViewController {
                presentedVC.isModalInPresentation = true
                presentedVC.onUpdateProfile = { [weak self] username, imageURL in
                    // Update the UI in the FirstViewController with the new username and imageURL
                    DispatchQueue.main.async {
                        self?.UsernameTextBox.text = username
                        if let imageURL = imageURL, let url = URL(string: imageURL) {
                            DispatchQueue.global().async {
                                if let data = try? Data(contentsOf: url) {
                                    let image = UIImage(data: data)
                                    DispatchQueue.main.async {
                                        self?.pic.image = image
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let tapGesture1 = UITapGestureRecognizer(target: self, action: #selector(showLogoutOption))
        UsernameTextBox.addGestureRecognizer(tapGesture1)
        UsernameTextBox.isUserInteractionEnabled = true
    }
    
    @objc func showLogoutOption() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let logoutAction = UIAlertAction(title: "Log Out", style: .destructive) { _ in
            self.logOutTapped()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(logoutAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func logOutTapped() {
        NotificationCenter.default.post(name: Notification.Name("LogoutNotification"), object: nil)
        let defaults = UserDefaults.standard
        defaults.set("", forKey: "access")
        defaults.set(false, forKey: "isLoggedIn")
        self.performSegue(withIdentifier: "goLogIn4", sender: self)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        let defaults = UserDefaults.standard
//        print("username",defaults.string(forKey: "username") as Any)
        if defaults.string(forKey: "username") != Optional("none") {
            UsernameTextBox.text = (defaults.string(forKey: "username") ?? "default")
        }
//        print("profile_image_url",defaults.string(forKey: "profile_image_url") as Any)
        let profile_image_url = defaults.string(forKey: "profile_image_url")
        let p = profile_image_url ?? "https://img.freepik.com/free-icon/user_318-563642.jpg?w=360"
        let imageURL = URL(string: p)
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: imageURL!) {
                DispatchQueue.main.async {
                    self.pic.image = UIImage(data: data)
                }
            }
        }
    }
    
    @IBAction func clearAllButtonTapped(_ sender: Any) {
        let sharedData = DataStore.shared
        sharedData.selectedTestImages = [] // Set the selectedImages value
        sharedData.selectedProductImages = [] // Set the selectedImages value
        sharedData.flagValue = 0
        sharedData.testMetadata = []
        sharedData.productMetadata = []
        
        let alertController = UIAlertController(title: "Clear All", message: "Are you sure you want to start a new session? This will remove all the added items.", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { [weak self] (_) in
            // User confirmed, start a new session
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let nextVC = storyboard.instantiateViewController(withIdentifier: "First")
            self?.navigationController?.pushViewController(nextVC, animated: true)
        }
        alertController.addAction(confirmAction)
        
        present(alertController, animated: true, completion: nil)
    }

    
    @IBAction func goBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func Submit(_ sender: Any) {
        uploadData(sender) { [weak self] success in
            if success {
                self?.displaySuccess("Upload Succeeded.") { // Add completion handler
                    let sharedData = DataStore.shared
                    sharedData.selectedTestImages = [] // Set the selectedImages value
                    sharedData.selectedProductImages = [] // Set the selectedImages value
                    sharedData.flagValue = 0
                    sharedData.testMetadata = []
                    sharedData.productMetadata = []
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let nextVC = storyboard.instantiateViewController(withIdentifier: "First")
                    self?.navigationController?.pushViewController(nextVC, animated: true)
                }
            } else {
                // Handle upload failure
                self?.displayWarning("Upload to server failed. Try to log out and log back in.")
                return
            }
        }
    }

    func displaySuccess(_ message: String, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completion() // Call the completion handler when "OK" is tapped
            })
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func uploadData(_ sender: Any, completion: @escaping (Bool) -> Void) {
//        var uploadSuccessful = false
        
        // Convert the images to data
        if productImageDatas.count == 0 || testImageDatas.count == 0 {
            print(productImageDatas.count,testImageDatas.count)
            displayWarning("All images needed to be uploaded successfully. Please go back.")
            return
        }
        
//        print(self.testMetadata,self.productMetadata)
//        print("testImageDatas count:", testImageDatas.count, self.testMetadata.count)
//        print("productImageDatas count:",productImageDatas.count, self.productMetadata.count)
//        print("Barcode Value to be uploaded:",barcodeValue)
        
        // Create the request body
        let requestBody: [String: Any] = [
            "barcode_image_url": barcodeImageData,
            "processed_barcode": barcodeValue,
            "product_images_urls": productImageDatas,
            "test_images_urls": testImageDatas,
            "flag": flagVal,
            "product_images_meta": self.productMetadata,
            "test_images_meta": self.testMetadata
        ]
        
//        let requestBody: [String: Any] = [
//            "barcode_image_url": barcodeImageData,
//            "processed_barcode": barcodeValue,
//            "product_images_urls": productImageDatas,
//            "test_images_urls": testImageDatas,
//            "flag": flagVal,
//            "product_images_meta": [],
//            "test_images_meta": []
//        ]
        
        // Convert the request body to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            self.displayWarning("upload data error: Failed to convert request body to JSON data")
            print("uploadData: Failed to convert request body to JSON data")
            return
        }
        
        // Configure the request
        guard let url = URL(string: "http://128.2.25.96:8003/enroll_captures/") else {
            self.displayWarning("uploadData: Invalid server URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let accesstoken_ = UserDefaults.standard.string(forKey: "access")!
        request.setValue("Bearer \(String(describing: accesstoken_))", forHTTPHeaderField: "Authorization")
        
        // Create a URLSession task for the request
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("Upload everything to server succeeded with status code 200")
//                uploadSuccessful = true
                completion(true)
            } else {
//                uploadSuccessful = false
                // Handle error response
                let httpResponse = response as? HTTPURLResponse
                print("Upload to server failed with status code: \(httpResponse?.statusCode ?? -1)")
                
                if let data = data {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Response data: \(responseString)")
                    }
                }
                self?.displayWarning("Upload to server failed. Try to log out and log in again.")
                completion(false)
            }
        }

        // Start the URLSession task
        task.resume()
        
//        print("uploadSuccessful?",uploadSuccessful)
//        if uploadSuccessful {
//            completion(true)
//        } else {
//            completion(false)
//        }
    }
    
    func displayWarning(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Warning", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

//    func displaySuccess(_ message: String) {
//        DispatchQueue.main.async {
//            let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//            self.present(alert, animated: true, completion: nil)
//        }
//    }

}
