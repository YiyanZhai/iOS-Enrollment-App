//
//  SecondViewController.swift
//  iOS Barcode Upload App
//
//  Created by Yiyan Zhai on 5/14/23.
//

import UIKit
import PhotosUI

class SecondViewController: UIViewController, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    // from FirstViewController
    var barcodeValue: String = ""
    var barcodeImage: UIImage?
    
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var imageView4: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide the delete buttons initially
        deleteButton1.isHidden = true
        deleteButton2.isHidden = true
        deleteButton3.isHidden = true
        deleteButton4.isHidden = true
        
        imageView1.layer.cornerRadius = 4.0
        imageView2.layer.cornerRadius = 4.0
        imageView3.layer.cornerRadius = 4.0
        imageView4.layer.cornerRadius = 4.0
    }
    
    @IBOutlet weak var deleteButton1: UIButton!
    @IBOutlet weak var deleteButton2: UIButton!
    @IBOutlet weak var deleteButton3: UIButton!
    @IBOutlet weak var deleteButton4: UIButton!
    
    @IBOutlet weak var server_button: UIButton!
    
    @IBOutlet weak var prev_button: UIButton!
    @IBOutlet weak var next_button: UIButton!
    
    @IBOutlet weak var product_upload_button: UIButton!
    
    var selectedImages: [UIImage] = []
    
    @IBAction func selectPhotosButtonTapped(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "Select Photo Source", message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
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
            
            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = 4 // Set the maximum number of photos to be selected

            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            present(picker, animated: true, completion: nil)
        }
        
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(libraryAction)
        
        present(actionSheet, animated: true, completion: nil)
        
        
    }

    
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        if sender == deleteButton1 && selectedImages.count > 0 {
            // Delete action for the first image view
            selectedImages.remove(at: 0)
            updateImageViews()
        } else if sender == deleteButton2 && selectedImages.count > 1 {
            // Delete action for the second image view
            selectedImages.remove(at: 1)
            updateImageViews()
        } else if sender == deleteButton3 && selectedImages.count > 2 {
            // Delete action for the third image view
            selectedImages.remove(at: 2)
            updateImageViews()
        } else if sender == deleteButton4 && selectedImages.count > 3 {
            // Delete action for the fourth image view
            selectedImages.remove(at: 3)
            updateImageViews()
        }
    }
    
    func updateImageViews() {
        let imageViews = [imageView1, imageView2, imageView3, imageView4]
        let deleteButtons = [deleteButton1, deleteButton2, deleteButton3, deleteButton4]

        for (index, imageView) in imageViews.enumerated() {
            if index < selectedImages.count {
                imageView?.image = selectedImages[index]
                deleteButtons[index]?.isHidden = false
            } else {
                imageView?.image = nil
                deleteButtons[index]?.isHidden = true
            }
        }
    }


    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true, completion: nil)
        for result in results {
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            if self?.selectedImages.count ?? 0 < 4 {
                                self?.selectedImages.append(image)
                                self?.updateImageViews()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        if selectedImages.count < 4 {
            selectedImages.append(image)
        }

        let imageViews = [imageView1, imageView2, imageView3, imageView4]
        for (index, imageView) in imageViews.enumerated() {
            if index < selectedImages.count {
                imageView?.image = selectedImages[index]
            } else {
                imageView?.image = nil
            }
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func goToNextPage(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "First")
        self.navigationController?.pushViewController(nextVC, animated: false)
    }
    
    @IBAction func goBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: false)
    }
    
    
    func getAppUserCredentials() -> String {
        // Retrieve the user credentials
        return UserDefaults.standard.string(forKey: "username") ?? ""
    }
    
    func uploadData(_ sender: Any) {
        // Convert the images to data
        guard let barcodeImageData = barcodeImage?.jpegData(compressionQuality: 0.8)?.base64EncodedString() else {
            displayWarning("Failed to convert barcode image to data")
            return
        }
        
        if selectedImages.count == 0 {
            displayWarning("Please upload product photos.")
            return
        }
        
        var productImageDatas: [String] = []
        for image in selectedImages {
            guard let imageData = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() else {
                displayWarning("Failed to convert product image to data")
                return
            }
            productImageDatas.append(imageData)
        }
        print(barcodeImageData.count)
        print(productImageDatas.count)
        // Create the request body
        let credentials = getAppUserCredentials()
        let requestBody: [String: Any] = [
            "user_info": credentials,
            "barcode_image": barcodeImageData,
            "processed_barcode": barcodeValue,
            "product_images": productImageDatas
        ]
        
        // Convert the request body to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            displayWarning("Failed to convert request body to JSON data")
            return
        }
        
        // Configure the request
        guard let url = URL(string: "<server_url>/enroll_barcode_productimages") else {
            displayWarning("Invalid server URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        // Create a URLSession task for the request
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            if let error = error {
                self?.displayWarning("Failed to upload to the server: \(error.localizedDescription)")
            } else {
                // Check the server response and handle accordingly
                if let data = data,
                   let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let success = responseJSON["success"] as? Bool,
                   let message = responseJSON["message"] as? String {
                    if success {
                        self?.displaySuccess(message)
                    } else {
                        self?.displayWarning("Failed to upload to the server: \(message)")
                    }
                } else {
                    self?.displayWarning("Failed to parse server response")
                }
            }
        }
        
        // Start the URLSession task
        task.resume()
    }
    
    func displayWarning(_ message: String) {
        let alert = UIAlertController(title: "Warning", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func displaySuccess(_ message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func uploadToServer(_ sender: Any) {
        uploadData(sender)
    }

}

