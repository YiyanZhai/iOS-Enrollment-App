//
//  SecondViewController.swift
//  iOS Barcode Upload App
//
//  Created by Yiyan Zhai on 5/14/23.
//

import UIKit
import PhotosUI

class SecondViewController: UIViewController, PHPickerViewControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var imageView4: UIImageView!
    
    @IBOutlet weak var l1: UILabel!
    @IBOutlet weak var l2: UILabel!
    @IBOutlet weak var l3: UILabel!
    @IBOutlet weak var l4: UILabel!
    
    @IBOutlet weak var prev_button: UIButton!
    @IBOutlet weak var next_button: UIButton!
    
    @IBOutlet weak var product_upload_button: UIButton!
    
    var selectedImages: [UIImage] = []
    
    @IBAction func selectPhotosButtonTapped(_ sender: UIButton) {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 4 // Set the maximum number of photos to be selected

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    // Function to compare two UIImage objects based on their pixel data
//    func compareImages(_ image1: UIImage, _ image2: UIImage) -> Bool {
//        var data1 = image1.pngData()
//        var data2 = image2.pngData()
//        return data1 == data2
//    }
    
    func compareImages(_ image1: UIImage, _ image2: UIImage) -> Bool {
        return image1.pngData()?.count == image2.pngData()?.count
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true, completion: nil)
        for result in results {
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            let isDuplicate = self?.selectedImages.contains { [weak self] existingImage in
                                guard let strongSelf = self else { return false }
                                return strongSelf.compareImages(existingImage, image)
                            }
                            if let strongSelf = self, let index = strongSelf.selectedImages.firstIndex(where: { strongSelf.compareImages($0, image) }) {
                                strongSelf.l2.text = "Duplicate at index: \(index)"
                            } else {
                                self?.l2.text = "Not a duplicate"
                            }
                            if let isDuplicate = isDuplicate, !isDuplicate {
                                self?.selectedImages.append(image)
                                self?.updateImageViews()
                                
                                self?.l1.text=String(self?.selectedImages.count ?? 0)
                            }
                        }
                    }
                }
            }
        }

//        for result in results {
//            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
//                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
//                    if let image = image as? UIImage {
//                        DispatchQueue.main.async {
//                            self?.selectedImages.append(image)
//                            self?.updateImageViews()
//                        }
//                    }
//                }
//            }
//        }
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
