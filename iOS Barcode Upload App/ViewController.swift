//
//  ViewController.swift
//  iOS Barcode Upload App
//
//  Created by Yiyan Zhai on 5/12/23.
//

import UIKit
import AVFoundation

class FirstViewController: UIViewController, UIImagePickerControllerDelegate, UITextFieldDelegate, UINavigationControllerDelegate, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var barcode_button: UIButton!
    @IBOutlet weak var next_button: UIButton!
    @IBOutlet weak var textbox: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textbox.delegate = self
        self.navigationController?.navigationBar.isHidden=true
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

    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            dismiss(animated: true, completion: nil)
            return
        }

        self.imageView.image = image
        self.dismiss(animated: true, completion: nil)
        
        if let barcodeValue = decodeBarcode(from: image) {
            showBarcodeAlert(barcodeValue)  // Barcode decoded successfully
            textbox.text = barcodeValue
        } else {
            showBarcodeAlert("Unable to decode barcode from the image")
        }
        
//        let imageSize = getImageSizeString(image) // Get the size string of the image
//        textbox.text = imageSize // Update the text of the text field
//
//        func getImageSizeString(_ image: UIImage) -> String {
//            let sizeInBytes = image.pngData()?.count ?? 0
//            let sizeInKB = sizeInBytes / 1024
//            return "\(sizeInKB)"
//        }
    }
    
    func decodeBarcode(from image: UIImage) -> String? {
        guard let ciImage = CIImage(image: image) else {
            return nil
        }
        
        let options: [String: Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: options)
        
        let features = detector?.features(in: ciImage)
        guard let qrCodeFeature = features?.first as? CIQRCodeFeature else {
            return nil
        }
        
        let barcodeValue = qrCodeFeature.messageString
        return barcodeValue
    }
    
    func showBarcodeAlert(_ barcodeValue: String) {
        let alert = UIAlertController(title: "Barcode", message: barcodeValue, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }

}
