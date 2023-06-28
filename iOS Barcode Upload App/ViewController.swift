//
//  ViewController.swift
//  iOS Barcode Upload App
//
//  Created by Yiyan Zhai on 5/12/23.

import UIKit
import Vision
import Photos

class FirstViewController: UIViewController, UIImagePickerControllerDelegate, UITextFieldDelegate, UINavigationControllerDelegate {

    var userEmail: String = ""
    var userPassword: String = ""
    var metadataString = ""
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goLogIn" {
            if let presentedVC = segue.destination as? logInViewController {
                presentedVC.isModalInPresentation = true
                presentedVC.onUpdateProfile = { [weak self] username, imageURL in
                    // Update the UI in the FirstViewController with the new username and imageURL
                    DispatchQueue.main.async {
                        self?.usernameTextBox.text = username
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
    var imageurl : URL? = nil
    override func viewDidAppear(_ animated: Bool) {
//        print("viewDidAppear on first")
        let defaults = UserDefaults.standard
//        print("viewDidAppear: isLoggedIn? ",defaults.bool(forKey: "isLoggedIn"))
        if defaults.bool(forKey: "isLoggedIn") == false {
            self.performSegue(withIdentifier: "goLogIn", sender: self)
        }
//        print(defaults.string(forKey: "username") as Any)
        if defaults.string(forKey: "username") != nil {
            usernameTextBox.text = (defaults.string(forKey: "username") ?? "no user info")
        } else {
            self.performSegue(withIdentifier: "goLogIn", sender: self)
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
        
        // Add a tap gesture recognizer to the usernameTextBox
        let tapGesture1 = UITapGestureRecognizer(target: self, action: #selector(showLogoutOption))
        usernameTextBox.addGestureRecognizer(tapGesture1)
        usernameTextBox.isUserInteractionEnabled = true
    }
    
    func logOutTapped() {
        NotificationCenter.default.post(name: Notification.Name("LogoutNotification"), object: nil)

        let defaults = UserDefaults.standard
        defaults.set("", forKey: "access")
        defaults.set("no user info", forKey: "username")
        defaults.set(false, forKey: "isLoggedIn")
        self.performSegue(withIdentifier: "goLogIn", sender: self)
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var barcode_button: UIButton!
    @IBOutlet weak var next_button: UIButton!
    @IBOutlet weak var textbox: UITextField!
    
    @IBOutlet weak var pic: UIImageView!
    
    var isBarcodeUploaded: Bool = false
    @IBOutlet weak var usernameTextBox: UITextField!
    
    override func viewDidLoad() {
//        print("viewDidLoad on first")
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        self.textbox.delegate = self
        self.navigationController?.navigationBar.isHidden=true
        
        // Add a tap gesture recognizer to dismiss the keyboard when tapping outside the text field
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        self.imageView.layer.cornerRadius = 7.0
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


    // Handle the return key press to dismiss the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // Dismiss the keyboard when tapping outside the text field
    @objc private func dismissKeyboard() {
        self.view.endEditing(true)
    }
    

    @IBAction func goToNextPage(_ sender: Any) {
        // Ensure the necessary data is available
        guard let barcodeValue = self.textbox.text, !barcodeValue.isEmpty,
              let barcodeImage = self.imageView.image else {
            // Display an error or prompt the user to complete the necessary fields
            self.showWarningAlert("Error", message: "Barcode image and value needed.")
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let nextVC = storyboard.instantiateViewController(withIdentifier: "Second") as? SecondViewController {
            // Pass the data to the second view controller
            nextVC.barcodeValue = barcodeValue
            nextVC.barcodeImage = barcodeImage
            nextVC.barcodeMetadata = self.metadataString
            self.navigationController?.pushViewController(nextVC, animated: true)
        }
    }
    
    @IBAction func uploadButtonTapped(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        let actionSheet = UIAlertController(title: "Select Photo Source", message: nil, preferredStyle: .actionSheet)
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            guard let self = self else { return }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePicker.sourceType = .camera
                self.present(imagePicker, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Error", message: "Camera not available", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        let libraryAction = UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            guard let self = self else { return }
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
        
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(libraryAction)
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if !isBarcodeUploaded {
            return false
        }
        
        guard let currentText = textField.text else {
            return true
        }
        
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: string)
        let numberSet = CharacterSet.decimalDigits
        let isNumber = updatedText.rangeOfCharacter(from: numberSet.inverted) == nil
        
        return isNumber
    }

    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let metadata = info[UIImagePickerController.InfoKey.mediaMetadata] as? NSDictionary {
            print("Got Metadata!")
            self.metadataString = metadata.description
        } else {
            self.metadataString = "placeholder"
            print("No metadata extracted.")
        }
        
        guard let image = info[.originalImage] as? UIImage else {
            dismiss(animated: true, completion: nil)
            return
        }
        self.imageView.image = image
        self.dismiss(animated: true, completion: nil)
        self.isBarcodeUploaded = true // Set isBarcodeUploaded to true when the image is uploaded

        if let barcodeValue = decodeBarcode(from: image) {
            self.textbox.text = barcodeValue
        } else {
            self.textbox.text = "" // Clear text box if barcode cannot be decoded
            showWarningAlert("Barcode Decoding Failed", message: "Unable to decode barcode from the image.")
        }
    }
    
    func decodeBarcode(from image: UIImage) -> String? {
        guard let ciImage = CIImage(image: image) else {
            return nil
        }
        
        var barcodeValue: String?
        
        let request = VNDetectBarcodesRequest { request, error in
            guard let results = request.results as? [VNBarcodeObservation], let barcode = results.first else {
                return
            }
            
            barcodeValue = barcode.payloadStringValue
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Error: \(error)")
        }
        
        return barcodeValue
    }
    
    func showWarningAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }

}
