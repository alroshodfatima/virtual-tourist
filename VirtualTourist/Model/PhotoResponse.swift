//
//  PhotoResponse.swift
//  VirtualTourist
//
//  Created by Fatimah on 09/04/1441 AH.
//  Copyright © 1441 Fatimah. All rights reserved.
//

import Foundation

struct PhotoResponse: Codable {
    let photos: PhotosObject
}

struct PhotosObject: Codable {
    let photo: [PhotoObject]
}

struct PhotoObject: Codable {
    let id: String
    let secret: String
    let server: String
    let farm: Int
}
