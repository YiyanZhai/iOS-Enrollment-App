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
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var barcode_button: UIButton!
    @IBOutlet weak var next_button: UIButton!
    @IBOutlet weak var textbox: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textbox.delegate = self
        self.navigationController?.navigationBar.isHidden=true
        
        // Add a tap gesture recognizer to dismiss the keyboard when tapping outside the text field
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        // Create a border layer with dashed line style
        let borderLayer = CAShapeLayer()
        borderLayer.strokeColor = UIColor.black.cgColor
        borderLayer.lineWidth = 1.0
        borderLayer.lineDashPattern = [4, 4] // Adjust the values to control the dash length and gap
        borderLayer.fillColor = nil
        borderLayer.frame = imageView.bounds
        borderLayer.path = UIBezierPath(rect: imageView.bounds).cgPath
        borderLayer.cornerRadius = imageView.layer.cornerRadius // Set corner radius if needed

        // Add the border layer to the image view's layer
        imageView.layer.addSublayer(borderLayer)

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
        if let text = self.textbox.text, text.isEmpty {
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "Second")
        self.navigationController?.pushViewController(nextVC, animated: true)
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
