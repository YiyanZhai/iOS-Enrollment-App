//
//  DataStore.swift
//  Data Upload
//
//  Created by Yiyan Zhai on 6/25/23.
//

import Foundation
import UIKit
class DataStore {
    static let shared = DataStore()
    var selectedTestImages: [UIImage] = []
    var selectedProductImages: [UIImage] = []
    var flagValue = 0
    var testMetadata: [String] = []
    var productMetadata: [String] = []
//    var hasUploadTest = false
//    var hasUploadProduct = false
//    var AuthToken = ""
//    var allSuccessful = false
}
