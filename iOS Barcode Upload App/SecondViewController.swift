//
//  SecondViewController.swift
//  iOS Barcode Upload App
//
//  Created by Yiyan Zhai on 5/14/23.
//

import UIKit
import PhotosUI
import Foundation
import AVFoundation

class SecondViewController: UIViewController, PHPickerViewControllerDelegate, AVCapturePhotoCaptureDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    private let maxPhotoCount = 100
    
    var hasUpload = false
    var barcodeMetadata = ""
    var productMetadata: [String] = []
    
    // from FirstViewController
    var barcodeValue: String = ""
    var barcodeImage: UIImage?
    
    var AuthToken = ""
    var allSuccessful = false
    var productImageDatas: [String] = []
    var barcodeImageData = ""
    
    @IBOutlet weak var UsernameTextBox: UITextField!
    @IBOutlet weak var pic: UIImageView!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goLogIn2" {
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
    
    private var flagValue = 0
    
    override func viewDidLoad() {
//        print("viewDidLoad second")
        super.viewDidLoad()
        
        let sharedData = DataStore.shared
        self.selectedImages = sharedData.selectedProductImages
        self.productMetadata = sharedData.productMetadata
        self.updateScrollView()
//        self.hasUpload = sharedData.hasUploadProduct
//        if self.selectedImages.count != 0 {
//            self.isReuse = true
//        }
//        self.allSuccessful = sharedData.allSuccessful
//        self.AuthToken = sharedData.AuthToken
        
        self.flagValue = sharedData.flagValue
        let color: UIColor = (flagValue == 0) ? .green : .red
        flagButton.tintColor = color
        
        // Hide the delete buttons initially
        
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
    
    override func viewDidAppear(_ animated: Bool) {
//        print("viewDidAppear second")
        let tapGesture1 = UITapGestureRecognizer(target: self, action: #selector(showLogoutOption))
        UsernameTextBox.addGestureRecognizer(tapGesture1)
        UsernameTextBox.isUserInteractionEnabled = true
    }
    
    @IBAction func flagButtonTapped(_ sender: Any) {
        flagValue = (flagValue == 0) ? 1 : 0
//        let title = "\(flagValue)"
//        flagButton.setTitle(title, for: .normal)
        let color: UIColor = (flagValue == 0) ? .green : .red
        flagButton.tintColor = color
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
    
    @IBOutlet weak var flagButton: UIButton!
    
    @IBOutlet weak var prev_button: UIButton!
    @IBOutlet weak var next_button: UIButton!
    
    @IBOutlet weak var product_upload_button: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var selectedImages: [UIImage] = []
    
    
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var capturedImages: [UIImage] = []
    
    @IBAction func selectPhotosButtonTapped(_ sender: UIButton) {
//        let actionSheet = UIAlertController(title: "Select Photo Source", message: nil, preferredStyle: .actionSheet)

//        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
//            guard let self = self else { return }
//            self.startCameraSession()
//        }
        
//        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
//            guard let self = self else { return }
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
//        }
//
//        let libraryAction = UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
//            guard let self = self else { return }
//
//            var configuration = PHPickerConfiguration()
//            configuration.selectionLimit = self.maxPhotoCount // Set the maximum number of photos to be selected
//            let picker = PHPickerViewController(configuration: configuration)
//            picker.delegate = self
//            present(picker, animated: true, completion: nil)
//        }
//        actionSheet.addAction(cameraAction)
//        actionSheet.addAction(libraryAction)
//        present(actionSheet, animated: true, completion: nil)
    }
    
    func startCameraSession() {
        // Check if the device has a camera
        guard let device = AVCaptureDevice.default(for: .video) else {
            let alert = UIAlertController(title: "Error", message: "Camera not available", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }

        do {
            // Create an input using the device
            let input = try AVCaptureDeviceInput(device: device)

            // Create a capture session
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)

            // Create a preview layer to display the camera feed
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.frame = view.bounds
            view.layer.addSublayer(previewLayer!)

            // Start the capture session
            captureSession?.startRunning()
        } catch {
            print("Error setting up camera: \(error.localizedDescription)")
        }
    }
    
    @IBAction func takePhotoButtonTapped(_ sender: UIButton) {
        guard let captureSession = captureSession else { return }

        // Create a photo output
        let photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)

            // Configure the photo settings
            let photoSettings = AVCapturePhotoSettings()
            photoSettings.isHighResolutionPhotoEnabled = true

            // Capture the photo
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    @IBAction func exitCaptureSession(_ sender: UIButton) {
        // Perform necessary actions to exit the capture session
        
        // Append the captured images to the selected data
        selectedImages += capturedImages
        
        // Update the scroll view with the new images
        updateScrollView()
        
        // Reset the capturedImages array
        capturedImages.removeAll()
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
            // Add the captured image to the array
            capturedImages.append(image)
        }
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true, completion: nil)
        
//        let requestOptions = PHImageRequestOptions()
//        requestOptions.isSynchronous = true
//        for result in results {
//            if let assetIdentifier = result.assetIdentifier {
//                PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil).enumerateObjects { (phAsset, _, _) in
//                    PHImageManager.default().requestImageData(for: phAsset, options: requestOptions) { (data, _, _, info) in
//                        if let metadata = info?[kCGImagePropertyExifDictionary as String] as? NSDictionary {
//                            print("Metadata got!")
//                            let metadataString = metadata.description
//                            print("Metadata: \(metadataString)")
//                            self.productMetadata.append(metadataString)
//                        }
//                    }
//                }
//            }
//        }
//        print(self.productMetadata.count)

        for result in results {
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            if self?.selectedImages.count ?? 0 < 100 {
                                self?.productMetadata.append("placeholder")
                                self?.selectedImages.append(image)
                                self?.updateScrollView()
                            }
                        }
                    }
                }
            }
        }
        print(self.productMetadata.count)
        print(self.selectedImages.count)
    }
    
    func updateScrollView() {
        scrollView.subviews.forEach { $0.removeFromSuperview() }

        let scrollViewHeight: CGFloat = scrollView.bounds.height
        let spacing: CGFloat = 15.0 // Adjust the spacing here

        var contentWidth: CGFloat = 0.0

        for (index, image) in selectedImages.enumerated() {
            let aspectRatio = image.size.width / image.size.height
            let imageHeight = scrollViewHeight
            let imageWidth = imageHeight * aspectRatio

            let containerView = UIView(frame: CGRect(x: contentWidth, y: 0, width: imageWidth, height: scrollViewHeight))

            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.layer.cornerRadius = 4.7
                imageView.clipsToBounds = true
            imageView.frame = CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight)

            containerView.addSubview(imageView)
            
            let deleteButton = UIButton(type: .system)
            deleteButton.setTitle("Remove", for: .normal)
            deleteButton.frame = CGRect(x: 0, y: imageHeight - 30, width: imageWidth, height: 30)
            deleteButton.addTarget(self, action: #selector(deleteButtonTapped(_:)), for: .touchUpInside)
            deleteButton.tag = index // Set the tag to identify the corresponding image
            // Set colors
            deleteButton.backgroundColor = UIColor.red.withAlphaComponent(0.35)
            deleteButton.setTitleColor(.white, for: .normal)
            deleteButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            containerView.addSubview(deleteButton)

            scrollView.addSubview(containerView)

            contentWidth += imageWidth + spacing
        }

        scrollView.contentSize = CGSize(width: contentWidth, height: scrollViewHeight)
    }

    @objc func deleteButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        selectedImages.remove(at: index)
        productMetadata.remove(at: index)
        updateScrollView()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        if let metadata = info[UIImagePickerController.InfoKey.mediaMetadata] as? NSDictionary {
//            do {
//                let jsonData = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
//                let jsonString = String(data: jsonData, encoding: .utf8)
//                print("JSON string: \(jsonString ?? "")")
//            } catch {
//                print("Error serializing metadata to JSON: \(error)")
//            }

            var current = ""
            for (key, value) in metadata {
                var thisMetadata = ""
//                print(key, type(of: value))
                if let v = metadata.value(forKey: key as! String) as? NSDictionary {
                    for (key1, value1) in v {
                        let newline = "\"\(key1)\":\"\(value1)\","
                        thisMetadata += newline
                    }
                    thisMetadata = String(thisMetadata.dropLast())
                } else if let number = metadata.value(forKey: key as! String) as? NSNumber {
                    thisMetadata = number.stringValue
                }  else if let data = metadata.value(forKey: key as! String) as? NSData {
                    thisMetadata = String(data: data as Data, encoding: .utf8) ?? ""
                }
//                print(thisMetadata)
                current += "\"\(key)\":\"\(thisMetadata)\","
            }
            print("New Metadata Element: ",String(current.dropLast()))
            self.productMetadata.append(String(current.dropLast()))
//            let metadata0 = metadata.value(forKey: "{Exif}") as! NSDictionary
//            var thisMetadata = ""
//            for (key, value) in metadata0 {
//                let newline = "\"\(key)\":\"\(value)\","
//                thisMetadata += newline
//                print(newline, type(of: value))
//            }
//            print(thisMetadata)
//            self.productMetadata.append(String(thisMetadata.dropLast()))
//            if let metadata0 = metadata.value(forKey: "{Exif}") {
//                let metadataStr = (metadata0 as! NSDictionary).description
//                print("Exif Metadata: \(metadataStr)")
//            }
//            self.productMetadata.append(metadata.description)
//            print("Product meta: ",type(of: metadata))
//            print("Product Meta: ")
//            print(metadata.description)
            print(productMetadata.count)
        } else {
            self.productMetadata.append("placeholder")
            print("No metadata extracted.")
        }
        print(self.productMetadata.count)
        
        if selectedImages.count < self.maxPhotoCount {
            selectedImages.append(image)
            self.updateScrollView()
        }

        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func goToNextPage(_ sender: Any) {
        if selectedImages.count == 0 {
            displayWarning("Images are needed.")
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let nextVC = storyboard.instantiateViewController(withIdentifier: "Test") as? TestViewController {
            // Pass the data to the test view controller
            nextVC.flagVal = self.flagValue
            nextVC.barcodeValue = self.barcodeValue
            nextVC.barcodeImage = self.barcodeImage!
            nextVC.productImages = self.selectedImages
            
            nextVC.barcodeMetadata = self.barcodeMetadata
            nextVC.productMetadata = self.productMetadata

            self.navigationController?.pushViewController(nextVC, animated: true)
        }
    }
    
    @IBAction func goBack(_ sender: Any) {
        let sharedData = DataStore.shared
        sharedData.selectedProductImages = self.selectedImages // Set the selectedImages value
        sharedData.flagValue = self.flagValue
        sharedData.productMetadata = self.productMetadata

        self.navigationController?.popViewController(animated: true)
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
        
        let urlstring = "https://\(storageAccount).blob.core.windows.net/\(container)/\(imageName)"
        print(urlstring)
        if container == "barcode-captures" {
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ""
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
    
    func uploadProductToServer() {
        if hasUpload != false {
            self.displayWarning("You already successfully uploaded the image(s).")
            return
        }
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
        
        self.productImageDatas = []
        self.allSuccessful = true
        for image in selectedImages {
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
//            self.displaySuccess("Upload succeed, thank you.")
            hasUpload = true
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

    
    func getName(option: String) -> String {
        let username = (UserDefaults.standard.string(forKey: "user_id"))!
//        let username = "default"
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


    func displayWarning(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Warning", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    func displaySuccess(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

