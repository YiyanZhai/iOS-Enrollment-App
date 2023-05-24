//
//  SecondViewController.swift
//  iOS Barcode Upload App
//
//  Created by Yiyan Zhai on 5/14/23.
//

import UIKit
import PhotosUI

class SecondViewController: UIViewController, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var imageView4: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the image views with dotted borders
        addDottedBorder(to: imageView1)
        addDottedBorder(to: imageView2)
        addDottedBorder(to: imageView3)
        addDottedBorder(to: imageView4)
    }

    func addDottedBorder(to imageView: UIImageView) {
        let borderLayer = CAShapeLayer()
        borderLayer.strokeColor = UIColor.black.cgColor
        borderLayer.lineWidth = 1.0
        borderLayer.lineDashPattern = [4, 4]
        borderLayer.fillColor = nil
        borderLayer.frame = imageView.bounds
        borderLayer.path = UIBezierPath(rect: imageView.bounds).cgPath
        borderLayer.cornerRadius = imageView.layer.cornerRadius
        
        imageView.layer.addSublayer(borderLayer)
    }
    
    @IBOutlet weak var deleteButton1: UIButton!
    @IBOutlet weak var deleteButton2: UIButton!
    @IBOutlet weak var deleteButton3: UIButton!
    @IBOutlet weak var deleteButton4: UIButton!
    
    
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
        for (index, imageView) in imageViews.enumerated() {
            if index < selectedImages.count {
                imageView?.image = selectedImages[index]
            } else {
                imageView?.image = nil
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
}


//                            if let strongSelf = self {
//                                if strongSelf.selectedImages.count < 4 {
//                                    let isDuplicate = self?.selectedImages.contains { [weak self] existingImage in
//                                        return self?.compareImages(existingImage, image) ?? false
//                                    }
//                                    if let isDuplicate = isDuplicate, !isDuplicate {
//                                        self?.selectedImages.append(image)
//                                        self?.updateImageViews()
//                                    }
//                                }
//                            }
