//
//  ViewController.swift
//  iOS Barcode Upload App
//
//  Created by Yiyan Zhai on 5/12/23.
//

import UIKit
import AVFoundation
import Vision

class FirstViewController: UIViewController, UIImagePickerControllerDelegate, UITextFieldDelegate, UINavigationControllerDelegate, AVCaptureMetadataOutputObjectsDelegate {
    
    var userEmail: String = ""
    var userPassword: String = ""
    
    override func viewDidAppear(_ animated: Bool) {
        let defaults = UserDefaults.standard
        print(defaults.bool(forKey: "isLoggedIn"))
        if defaults.bool(forKey: "isLoggedIn") == false {
            self.performSegue(withIdentifier: "goLogIn", sender: self)
        }
        
    }
    
    @IBAction func logOutTapped(_ sender: Any) {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: "isLoggedIn")
        self.performSegue(withIdentifier: "goLogIn", sender: self)
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var barcode_button: UIButton!
    @IBOutlet weak var next_button: UIButton!
    @IBOutlet weak var textbox: UITextField!
    
    @IBOutlet weak var logOut: UIButton!
    
    var isBarcodeUploaded: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textbox.delegate = self
        self.navigationController?.navigationBar.isHidden=true
        
        // Add a tap gesture recognizer to dismiss the keyboard when tapping outside the text field
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        imageView.layer.cornerRadius = 6.0
    }

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "goLogIn" {
//            // Handle preparation for the login segue, if needed
//            // For example, you can pass data to the destination view controller
//            if let destinationVC = segue.destination as? logInViewController {
//                destinationVC.username = "john_doe"
//            }
//        }
//    }
    

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
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let nextVC = storyboard.instantiateViewController(withIdentifier: "Second") as? SecondViewController {
            // Pass the data to the second view controller
            nextVC.barcodeValue = barcodeValue
            nextVC.barcodeImage = barcodeImage
            
            self.navigationController?.pushViewController(nextVC, animated: true)
        }
    }
    
    @IBAction func uploadButtonTapped(_ sender: UIButton) {
        let defaults = UserDefaults.standard
        userEmail = defaults.string(forKey: "Username") ?? "default value"
        print("Received data from modal: \(userEmail)")
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
        guard let image = info[.originalImage] as? UIImage else {
            dismiss(animated: true, completion: nil)
            return
        }

        self.imageView.image = image
        self.dismiss(animated: true, completion: nil)
        self.isBarcodeUploaded = true // Set isBarcodeUploaded to true when the image is uploaded
        
        if let barcodeValue = decodeBarcode(from: image) {
            if let number = Int(barcodeValue) {
                self.textbox.text = "\(number)" // Display only numeric value
            } else {
                self.textbox.text = "" // Clear text box if barcode is not a number
                showWarningAlert("Invalid Barcode", message: "The scanned barcode is not a number.")
            }
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
