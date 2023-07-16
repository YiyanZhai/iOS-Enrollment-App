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

class SecondViewController: UIViewController, AVCapturePhotoCaptureDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    private let maxPhotoCount = 7
    
//    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var hasUpload = false
    
    // from FirstViewController
    var barcodeValue: String = ""
    var barcodeImage: UIImage?
    
    var AuthToken = ""
    var allSuccessful = false
    
    var selectedImages: [UIImage] = []
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var capturedImages: [UIImage] = []
    
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
    var activityIndicator: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityIndicator = UIActivityIndicatorView(style: .large)
        self.activityIndicator.center = CGPoint(x:view.center.x,y:680)
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.color = .white
        view.addSubview(self.activityIndicator)

        
        let sharedData = DataStore.shared
        self.selectedImages = sharedData.selectedProductImages
        self.updateScrollView()
        
        let defaults = UserDefaults.standard
        if defaults.string(forKey: "username") != Optional("none") {
            UsernameTextBox.text = (defaults.string(forKey: "username") ?? "default")
        }
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
        self.performSegue(withIdentifier: "goLogIn2", sender: self)
    }
    
    @IBOutlet weak var prev_button: UIButton!
    @IBOutlet weak var next_button: UIButton!
    @IBOutlet weak var product_upload_button: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBAction func selectPhotosButtonTapped(_ sender: UIButton) {
        if self.selectedImages.count > self.maxPhotoCount {
            displayWarning("Image number exceeded.")
            return
        }
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
    
    func updateScrollView() {
        scrollView.subviews.forEach { $0.removeFromSuperview() }

        let scrollViewHeight: CGFloat = scrollView.bounds.height
        let spacing: CGFloat = 15.0

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
            deleteButton.tag = index
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
        updateScrollView()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        if selectedImages.count < self.maxPhotoCount {
            selectedImages.append(image)
            self.updateScrollView()
        } else {
            displayWarning("Image number exceeded.")
        }

        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func goToNextPage(_ sender: Any) {
        
        if selectedImages.count == 0 {
            displayWarning("Image is needed.")
            return
        }
        if selectedImages.count > 5 {
            displayWarning("Image number exceeded.")
            return
        }
        self.activityIndicator.startAnimating()
        
        self.sendMultipartRequest() { [weak self] success in
            if success {
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                }
                self?.displaySuccess2("Upload Succeeded.") {
                    let sharedData = DataStore.shared
                    sharedData.selectedProductImages = []
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let nextVC = storyboard.instantiateViewController(withIdentifier: "First")
                    self?.navigationController?.pushViewController(nextVC, animated: true)
                }
            } else {
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                }
                // Handle upload failure
                self?.displayWarning("Upload to server failed.")
                return
            }
        }
    }
    
    private func textFormField(name: String, value: String, boundary: String) -> String {
            var fieldString = "--\(boundary)\r\n"
            fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
            fieldString += "Content-Type: text/plain; charset=ISO-8859-1\r\n"
            fieldString += "Content-Transfer-Encoding: 8bit\r\n"
            fieldString += "\r\n"
            fieldString += "\(value)\r\n"

            return fieldString
        }
    
    func sendMultipartRequest(completion: @escaping (Bool) -> Void) {
        let url = URL(string: "http://128.2.25.96:8003/enroll_captures/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        let contentType = "multipart/form-data; boundary=\(boundary)"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        let body = NSMutableData()

        // Add barcode_image
        if let barcodeImageData = barcodeImage!.jpegData(compressionQuality: 1.0) {
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"barcode_image\"; filename=\"\(barcodeValue).jpg\"\r\n")
            body.appendString("Content-Type: image/jpeg\r\n\r\n")
            body.append(barcodeImageData)
            body.appendString("\r\n")
        }

        // Add processed_barcode
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"barcode\"\r\n\r\n")
        body.appendString("\(barcodeValue)\r\n")

        // Add capture_images
        for (index, image) in selectedImages.enumerated() {
            if let imageData = image.jpegData(compressionQuality: 1.0) {
                body.appendString("--\(boundary)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"product_images\"; filename=\"product_image_\(index).jpg\"\r\n")
                body.appendString("Content-Type: image/jpeg\r\n\r\n")
                body.append(imageData)
                body.appendString("\r\n")
            }
        }

        body.appendString("--\(boundary)--\r\n")
        print("request body is :\n",body)
        request.httpBody = body as Data
        let accesstoken_ = UserDefaults.standard.string(forKey: "access")!
        request.setValue("Bearer \(String(describing: accesstoken_))", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                print("Upload everything to server succeeded with status code 201")
                completion(true)
            } else {
                // Handle error response
                let httpResponse = response as? HTTPURLResponse
                print("Upload to server failed with status code: \(httpResponse?.statusCode ?? -1)")

                if let data = data {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Response data: \(responseString)")
                    }
                }
                self?.displayWarning("Upload to server failed.")
                completion(false)
            }
        }

        task.resume()
    }
    
    @IBAction func goBack(_ sender: Any) {
        let sharedData = DataStore.shared
        sharedData.selectedProductImages = self.selectedImages
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func clearAllButtonTapped(_ sender: Any) {
        let sharedData = DataStore.shared
        sharedData.selectedProductImages = [] // Set the selectedImages value

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
        let upc = barcodeValue
        let uuid = UUID().uuidString
        let imageName = "\(username)-\(option)-\(upc)-\(uuid).jpg"
        
        return imageName
    }
    

    func displayWarning(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Warning", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func displaySuccess2(_ message: String, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completion() // Call the completion handler when "OK" is tapped
            })
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

extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: .utf8, allowLossyConversion: true)
        append(data!)
    }
}
