//
//  SecondViewController.swift
//  iOS Barcode Upload App
//
//  Created by Yiyan Zhai on 5/14/23.
//

import UIKit
import PhotosUI
import Foundation

class SecondViewController: UIViewController, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    // from FirstViewController
    var barcodeValue: String = ""
    var barcodeImage: UIImage?
    var AuthToken = ""
    var allSuccessful = false
    var productImageDatas: [String] = []
    var barcodeImageData = ""
    
    @IBOutlet weak var UsernameTextBox: UITextField!
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var imageView4: UIImageView!
    @IBOutlet weak var imageView5: UIImageView!
    @IBOutlet weak var imageView6: UIImageView!
    
    private var flagValue = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.flagValue = 0
        flagButton.setTitle("0", for: .normal)
        let color: UIColor = (flagValue == 0) ? .green : .red
        flagButton.backgroundColor = color
        
        // Hide the delete buttons initially
        deleteButton1.isHidden = true
        deleteButton2.isHidden = true
        deleteButton3.isHidden = true
        deleteButton4.isHidden = true
        deleteButton5.isHidden = true
        deleteButton6.isHidden = true
        
        imageView1.layer.cornerRadius = 4.0
        imageView2.layer.cornerRadius = 4.0
        imageView3.layer.cornerRadius = 4.0
        imageView4.layer.cornerRadius = 4.0
        imageView5.layer.cornerRadius = 4.0
        imageView6.layer.cornerRadius = 4.0
        
        let defaults = UserDefaults.standard
        print(defaults.string(forKey: "username") as Any)
        if defaults.string(forKey: "username") != Optional("none") {
            UsernameTextBox.text = (defaults.string(forKey: "username") ?? "default")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear")
        let tapGesture1 = UITapGestureRecognizer(target: self, action: #selector(showLogoutOption))
        UsernameTextBox.addGestureRecognizer(tapGesture1)
        UsernameTextBox.isUserInteractionEnabled = true
    }
    
    @IBAction func flagButtonTapped(_ sender: Any) {
        flagValue = (flagValue == 0) ? 1 : 0
        let title = "\(flagValue)"
        flagButton.setTitle(title, for: .normal)
        let color: UIColor = (flagValue == 0) ? .green : .red
        flagButton.backgroundColor = color
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
        self.performSegue(withIdentifier: "goLogIn2", sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goLogIn2" {
            if let presentedVC = segue.destination as? logInViewController {
                presentedVC.isModalInPresentation = true
//                presentedVC.delegate = self
            }
        }
    }
    
    @IBOutlet weak var deleteButton1: UIButton!
    @IBOutlet weak var deleteButton2: UIButton!
    @IBOutlet weak var deleteButton3: UIButton!
    @IBOutlet weak var deleteButton4: UIButton!
    @IBOutlet weak var deleteButton5: UIButton!
    @IBOutlet weak var deleteButton6: UIButton!
    
    @IBOutlet weak var flagButton: UIButton!
    
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
            configuration.selectionLimit = 6 // Set the maximum number of photos to be selected

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
        } else if sender == deleteButton5 && selectedImages.count > 4 {
            // Delete action for the fourth image view
            selectedImages.remove(at: 4)
            updateImageViews()
        } else if sender == deleteButton6 && selectedImages.count > 5 {
            // Delete action for the fourth image view
            selectedImages.remove(at: 5)
            updateImageViews()
        }
    }
    
    func updateImageViews() {
        let imageViews = [imageView1, imageView2, imageView3, imageView4, imageView5, imageView6]
        let deleteButtons = [deleteButton1, deleteButton2, deleteButton3, deleteButton4, deleteButton5, deleteButton6]

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
                            if self?.selectedImages.count ?? 0 < 6 {
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
        
        if selectedImages.count < 6 {
            selectedImages.append(image)
        }

        let imageViews = [imageView1, imageView2, imageView3, imageView4, imageView5, imageView6]
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
        if self.AuthToken == "" || productImageDatas.count == 0 || self.allSuccessful == false {
            displayWarning("All product Images needed to be uploaded successfully.")
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let nextVC = storyboard.instantiateViewController(withIdentifier: "Test") as? TestViewController {
            // Pass the data to the test view controller
            nextVC.flagVal = self.flagValue
            nextVC.barcodeValue = self.barcodeValue
            nextVC.AuthToken = self.AuthToken
            nextVC.allSuccessful = self.allSuccessful
            nextVC.barcodeImageData = self.barcodeImageData
            nextVC.productImageDatas = self.productImageDatas
            
            self.navigationController?.pushViewController(nextVC, animated: true)
        }
        
//        uploadData(sender) { [weak self] success in
//            if success {
//                self?.displaySuccess("Upload Succeed.")
//                let storyboard = UIStoryboard(name: "Main", bundle: nil)
//                if let nextVC = storyboard.instantiateViewController(withIdentifier: "Test") as? TestViewController {
//                    // Pass the data to the second view controller
//                    nextVC.barcodeValue = self!.barcodeValue
////                    nextVC.barcodeImage = self.barcodeImage
//                    self?.navigationController?.pushViewController(nextVC, animated: true)
//                }
//            } else {
//                // Handle upload failure
//            }
//        }
    }
    
    @IBAction func goBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: false)
    }
    
//    func getAppUserCredentials() -> String {
//        // Retrieve the user credentials
//        return UserDefaults.standard.string(forKey: "username") ?? ""
//    }
    
    
//    func uploadData(_ sender: Any, completion: @escaping (Bool) -> Void) {
//        var uploadSuccessful = true
//
//        // Convert the images to data
//        if self.AuthToken == "" || productImageDatas.count == 0 || self.allSuccessful == false {
//            displayWarning("All product Images needed to be uploaded successfully.")
//            return
//        }
//
//        print("productImageDatas num ", productImageDatas.count)
//
//        // Create the request body
////        let credentials = getAppUserCredentials()
//        let requestBody: [String: Any] = [
//            "barcode_image": barcodeImageData,
//            "processed_barcode": barcodeValue,
//            "product_images": productImageDatas
//        ]
//
//        // Convert the request body to JSON data
//        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
//            displayWarning("uploadData: Failed to convert request body to JSON data")
//            return
//        }
//
//        // Configure the request
//        guard let url = URL(string: "http://128.2.25.96:8000/enroll_barcode_productimages") else {
//            displayWarning("uploadData: Invalid server URL")
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.httpBody = jsonData
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        let accesstoken_ = UserDefaults.standard.string(forKey: "access")!
////        print("accesstoken_:",)
//        request.setValue("Bearer \(String(describing: accesstoken_))", forHTTPHeaderField: "Authorization")
//
//        // Create a URLSession task for the request
//        let task = URLSession.shared.dataTask(with: request) { [weak self] (data1, response1, error1) in
//            if let httpResponse1 = response1 as? HTTPURLResponse, httpResponse1.statusCode == 200 {
//                print("Upload to server succeed with status code 200")
//            } else {
//                uploadSuccessful = false
//                // Handle error response
//                let httpResponse1 = response1 as? HTTPURLResponse
//                print(httpResponse1?.statusCode)
//                self?.displayWarning("Upload to server failed")
//            }
//        }
//
//        // Start the URLSession task
//        task.resume()
//
//        if uploadSuccessful {
//            completion(true)
//        } else {
//            completion(false)
//        }
//    }
    
    func displayWarning(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Warning", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
//    func displayWarning(_ message: String) {
//        let alert = UIAlertController(title: "Warning", message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//        present(alert, animated: true, completion: nil)
//    }

    func displaySuccess(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    func getCurrentDateTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        
        let currentDateTime = Date()
        let formattedDateTime = dateFormatter.string(from: currentDateTime)
        
        return formattedDateTime
    }
    
    func uploadImageToAzureStorage(imageData: Data, imageName: String, auth: String, option: String, completion: @escaping (Bool) -> Void) {
        
        let storageAccount = "ultronai4walmart"
        let container = option
        
        var urlstring = "https://\(storageAccount).blob.core.windows.net/\(container)/\(imageName)"
        print(urlstring)
        if container == "barcode" {
            barcodeImageData = urlstring
        } else {
            productImageDatas.append(urlstring)
        }
        
        guard let url = URL(string: "https://\(storageAccount).blob.core.windows.net/\(container)/\(imageName)") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        request.setValue("BlockBlob", forHTTPHeaderField: "x-ms-blob-type")
        request.setValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")
        request.setValue("2020-08-04", forHTTPHeaderField: "x-ms-version")
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ""
        let currentTimeString = dateFormatter.string(from: currentDate)
        let dateString = getCurrentDateTime()
        request.setValue(dateString, forHTTPHeaderField: "x-ms-date")
        let session = URLSession.shared
        
        let task = session.uploadTask(with: request, from: imageData) { (data,response, error) in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                print("Image uploaded succeed with status code 201: " + imageName)
            }  else {
                // Handle error response
                print(imageName+" error with code")
                self.displayWarning(imageName+" error with code")
                let httpResponse = response as? HTTPURLResponse
                print(httpResponse?.statusCode as Any)
                if let data = data,
                   let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let message = responseJSON["detail"] as? String {
                    print(message)
                }
            }
        }
        task.resume()
    }
    
    @IBAction func uploadProductToServer(_ sender: Any) {
        if selectedImages.count == 0 {
            self.displayWarning("Please upload product image(s).")
            return
        }
        getAuthToken { authToken in
            if authToken != nil {
                // Authentication token successfully obtained
                self.AuthToken = authToken ?? "no authToken"
                print("Auth token: \(self.AuthToken)")
                // Use the token for your desired operations
            } else {
                // Error occurred while obtaining the authentication token
                self.displayWarning("Failed to obtain auth token")
                // Handle the error condition
            }
        }
//        sleep(2)
        
        print("start uploading barcode images to server")
        
        let option = "barcode"
        let image_Name_barcode = getName(option: option)
        
        guard let barcodeImageData = barcodeImage?.jpegData(compressionQuality: 0.8) else {
            self.displayWarning("Failed to convert barcode image to data")
            return
        }

        self.uploadImageToAzureStorage(imageData: barcodeImageData, imageName: image_Name_barcode, auth: self.AuthToken, option: "barcode-captures")  { success in
            if success {
                print("Barcode Image upload task succeeded")
            } else {
                self.displayWarning("Barcode Image upload task failed")
                return
            }
        }
        
        print("start uploading product images to server")
        
        for image in selectedImages {
            self.allSuccessful = true
            guard let image_Data = image.jpegData(compressionQuality: 0.8) else {
                displayWarning("Failed to convert product image to data")
                return
            }
            let image_Name = getName(option: "product")
            
            uploadImageToAzureStorage(imageData: image_Data, imageName: image_Name, auth: self.AuthToken, option: "product-captures")  { success in
                if success {
                    print("Image upload task succeeded")
                } else {
                    self.allSuccessful = false
                    print("Image upload task failed")
                }
            }
            if self.allSuccessful == false {
                self.displayWarning("Failed to upload all product images to storage.")
            }
        }
        
        if allSuccessful == true {
            self.displaySuccess("Upload succeed, thank you.")
        }
    }
    
    func getName(option: String) -> String {
        let username = (UserDefaults.standard.string(forKey: "username"))!
        let upc = barcodeValue
        let uuid = UUID().uuidString
        let imageName = "\(username)-\(option)-\(upc)-\(uuid).jpg"
        
        return imageName
    }

    func getAuthToken(completion: @escaping (String?) -> Void) {
        let urlString = "https://login.microsoftonline.com/6dfefb37-6886-4e5e-b19e-643474ed010b/oauth2/token"
        let clientId = "1b1d367b-a8fc-41f5-922c-6e62da393234"
        let clientSecret = "ceW8Q~wpSqNJ1Gcdv4xwBYZp1ayAABdyq_tIybe6"
        let resource = "https://storage.azure.com/"

        let parameters = [
            "grant_type": "client_credentials",
            "client_id": clientId,
            "client_secret": clientSecret,
            "resource": resource
        ]

        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let authToken = json["access_token"] as? String else {
                completion(nil)
                return
            }
            completion(authToken)
        }

        task.resume()
        
        sleep(1)
    }


}

