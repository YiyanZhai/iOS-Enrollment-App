//
//  TestViewController.swift
//  iOS Barcode Upload App
//
//  Created by Yiyan Zhai on 6/22/23.
//

import UIKit
import PhotosUI
import Photos
import Foundation
import CoreImage

class TestViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    @IBOutlet weak var scrollView: UIScrollView!

    var selectedImages: [UIImage] = []
    
    var barcodeValue: String = ""
    var AuthToken = ""
    var allSuccessful = true;
    var productImageDatas: [String] = []
    var barcodeImageData = ""
    var flagVal = 0
    var testImageDatas: [String] = []
//    var hasUpload = false
    var barcodeImage: UIImage? = nil
    var productImages: [UIImage] = []
    var barcodeMetadata = ""
    var productMetadata: [String] = []
    var testMetadata: [String] = []
    
    @IBOutlet weak var pic: UIImageView!
    @IBOutlet weak var UsernameTextBox: UITextField!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goLogIn3" {
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
        self.performSegue(withIdentifier: "goLogIn3", sender: self)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sharedData = DataStore.shared
        self.selectedImages = sharedData.selectedTestImages
        self.testMetadata = sharedData.testMetadata
        self.updateScrollView()
        
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
    
    @IBAction func goBack(_ sender: Any) {
        let sharedData = DataStore.shared
        sharedData.testMetadata = self.testMetadata
        sharedData.selectedTestImages = self.selectedImages
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func selectPhotosButtonTapped(_ sender: UIButton) {
//        let actionSheet = UIAlertController(title: "Select Photo Source", message: nil, preferredStyle: .actionSheet)
//
//        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
//            guard let self = self else { return }
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePicker.sourceType = .camera
                imagePicker.delegate = self
                self.present(imagePicker, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Error", message: "Camera not available", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
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
        testMetadata.remove(at: index)
        updateScrollView()
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        if let metadata = info[UIImagePickerController.InfoKey.mediaMetadata] as? NSDictionary {
            var current = ""
            for (key, value) in metadata {
                var thisMetadata = ""
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
                current += "\"\(key)\":\"\(thisMetadata)\","
            }
            self.testMetadata.append(String(current.dropLast()))
        } else {
            self.testMetadata.append("placeholder")
            print("No metadata extracted.")
        }
        print(self.testMetadata.count)
        
//        if let metadata = info[UIImagePickerController.InfoKey.mediaMetadata] as? NSDictionary {
//            print("Got Metadata!")
//            self.testMetadata.append(metadata.description)
//        } else {
//            self.testMetadata.append("placeholder")
//            print("No metadata extracted.")
//        }
        
        if selectedImages.count < 100 {
            selectedImages.append(image)
//            saveImageToCustomAlbum(image: image)
            self.updateScrollView()
        }
        self.dismiss(animated: true, completion: nil)
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

    
    @IBAction func goToNextPage(_ sender: Any) {
        if selectedImages.count == 0 {
            displayWarning("Images are needed.")
            return
        }
        
//        for inputImage in (self.productImages + self.selectedImages) {
//            let image_name = getName(option: "product")
//            print(image_name)
//            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
//                return
//            }
//            let fileURL = documentsDirectory.appendingPathComponent(image_name)
//            displayWarning(fileURL.absoluteString)
//            do {
//                try inputImage.jpegData(compressionQuality: 1.0)?.write(to: fileURL)
//                // Save the image to the photo library
//                UIImageWriteToSavedPhotosAlbum(inputImage, self, nil, nil)
//            } catch {
//                print("Error saving image: \(error.localizedDescription)")
//            }
//            let filePath = "\(paths[0])/\(image_name)"
//            UIImagePNGRepresentation(inputImage)?.writeToFile(filePath, atomically: true)
//            let image_name = getName(option: "product")
//            guard let inputImage = UIImage(named: image_name) else {
//                self.displayWarning("failed to name image")
//                return
//            }
//            UIImageWriteToSavedPhotosAlbum(inputImage, nil, nil, nil)
//        }
        
        self.uploadEverythingToServer() { [weak self] success in
            if success {
                print("success:", self?.testImageDatas.count, self?.selectedImages.count,self?.productImageDatas.count, self?.productImages.count)
                
                if self?.AuthToken == "" || self?.testImageDatas.count != self?.selectedImages.count || self?.allSuccessful == false || self?.productImageDatas.count != self?.productImages.count {
                    self?.displayWarning("Images upload not finished. Save these images to local photo library.")
                    return
                }

                if self?.selectedImages.count != self?.testMetadata.count || self?.productImages.count != self?.productMetadata.count {
                    self?.displayWarning("Metadata count doesn't match.")
                    return
                }

                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let nextVC = storyboard.instantiateViewController(withIdentifier: "Final") as? FinalViewController {
                    // Pass the data to the test view controller
                    nextVC.flagVal = self!.flagVal
                    nextVC.barcodeValue = self!.barcodeValue
                    nextVC.barcodeImageData = self!.barcodeImageData
                    nextVC.productImageDatas = self!.productImageDatas
                    nextVC.testImageDatas = self!.testImageDatas
                    nextVC.testMetadata = self!.testMetadata
                    nextVC.productMetadata = self!.productMetadata
                    self?.navigationController?.pushViewController(nextVC, animated: true)
                }
            } else {
                // Handle upload failure
                self?.displayWarning("Upload to cloud server failed")
                return
            }
        }
    }
    
    func uploadEverythingToServer(completion: @escaping (Bool) -> Void) {
        
//        let cur = date?.timeIntervalSince1970
//        let expires =
        getAuthToken { authToken in
            if authToken != nil {
                self.AuthToken = authToken ?? "no authToken"
                print("Auth token: \(self.AuthToken)")
            } else {
                self.displayWarning("Failed to obtain auth token")
            }
        }
        self.allSuccessful = true
        
        print("start uploading barcode images to cloud server")
        
        let image_Name_barcode = getName(option: "barcode")
        guard let barcodeImageData = barcodeImage?.jpegData(compressionQuality: 1.0) else {
            self.displayWarning("Failed to convert barcode image to data")
            self.allSuccessful = false
            return
        }
        self.uploadImageToAzureStorage(imageData: barcodeImageData, imageName: image_Name_barcode, auth: self.AuthToken, option: "barcode-captures", accumulation: 0)  { success in
            if success {
                print(image_Name_barcode+"Barcode Image upload task succeeded")
            } else {
                self.allSuccessful = false
                self.displayWarning("Barcode Image upload task failed")
                return
            }
        }
        
        print("start uploading product images to server")
        
        self.productImageDatas = []
        for image in productImages {
            guard let image_Data = image.jpegData(compressionQuality: 1.0) else {
                displayWarning("Failed to convert product image to data")
                self.allSuccessful = false
                return
            }
            let image_Name = getName(option: "product")
            uploadImageToAzureStorage(imageData: image_Data, imageName: image_Name, auth: self.AuthToken, option: "product-captures", accumulation: 0)  { success in
                if success {
                    print(image_Name+"Image upload task succeeded (product)")
                } else {
                    self.allSuccessful = false
                    print(image_Name+"Image upload task failed (product)")
                }
            }
        }
        print("product end with counnt: ", self.productImageDatas.count)
        
        if selectedImages.count == 0 {
            self.displayWarning("Please upload test image(s).")
            return
        }
        
        print("start uploading test images to server")
        self.testImageDatas = []
        self.allSuccessful = true
        for image in selectedImages {
            guard let image_Data = image.jpegData(compressionQuality: 1.0) else {
                displayWarning("Failed to convert image to data")
                return
            }
            let image_Name = getName(option: "test")
            
            uploadImageToAzureStorage(imageData: image_Data, imageName: image_Name, auth: self.AuthToken, option: "test-captures", accumulation: 0)  { success in
                if success {
                    print(image_Name+"Image upload task succeeded (test)")
                } else {
                    self.allSuccessful = false;
                    print(image_Name+"Image upload task failed (test)")
                }
            }
            if self.allSuccessful == false {
                self.displayWarning("Failed to upload all images to storage.")
            }
        }
        print("test end with count: ", self.testImageDatas.count)
        
        if self.allSuccessful == true {
            completion(true)
        } else {
            completion(false)
        }
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
    
    func getCurrentDateTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        let currentDateTime = Date()
        let formattedDateTime = dateFormatter.string(from: currentDateTime)
        return formattedDateTime
    }
    
    func uploadImageToAzureStorage(imageData: Data, imageName: String, auth: String, option: String, accumulation: Int, completion: @escaping (Bool) -> Void) {
        let storageAccount = "ultronai4walmart"
        let container = option
        let urlstring = "https://\(storageAccount).blob.core.windows.net/\(container)/\(imageName)"
        
        guard let url = URL(string: urlstring) else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        request.setValue("BlockBlob", forHTTPHeaderField: "x-ms-blob-type")
        request.setValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")
        request.setValue("2020-08-04", forHTTPHeaderField: "x-ms-version")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("\(imageData.count)", forHTTPHeaderField: "Content-Length")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ""
        let dateString = getCurrentDateTime()
        request.setValue(dateString, forHTTPHeaderField: "x-ms-date")
        let session = URLSession.shared
        
        let task = session.uploadTask(with: request, from: imageData) { (data,response, error) in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                print("\(container): Image uploaded succeed with status code 201: " + imageName)
                if option == "test-captures" {
                    self.testImageDatas.append(urlstring)
                } else if option == "product-captures" {
                    self.productImageDatas.append(urlstring)
                } else {
                    self.barcodeImageData = urlstring
                }
                print("\(option) container has " + String(self.testImageDatas.count) + " images uploaded.")
                completion(true)
            } else {
                    self.allSuccessful = false
                    let httpResponse = response as? HTTPURLResponse
                    if let data = data,
                       let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let message = responseJSON["detail"] as? String {
                        print(message)
                        self.displayWarning(imageName + " " + String(httpResponse?.statusCode ?? 0) + " Error. " + message)
                    } else {
                        self.displayWarning(imageName + " " + String(httpResponse?.statusCode ?? 0) + " Error.")
                    }
                }
                completion(false)
            }
        
        task.resume()
    }
    
    func getName(option: String) -> String {
        let username = UserDefaults.standard.string(forKey: "user_id") ?? ""
        let upc = self.barcodeValue
        let uuid = UUID().uuidString
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM_dd_HH_mm"
        let currentDate = dateFormatter.string(from: Date())
        
        let imageName = "\(username)-\(option)-\(upc)-\(currentDate)-\(uuid).jpg"
        
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
            print(json)
            completion(authToken)
        }

        task.resume()
        
        sleep(1)
    }



    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
