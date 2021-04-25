//
//  Asset.swift
//  AnyImageKit
//
//  Created by 刘栋 on 2021/4/23.
//  Copyright © 2021 AnyImageProject.org. All rights reserved.
//

import Foundation
import Photos

public class Asset<Resource: IdentifiableResource> {
    
    public let resource: Resource
    public let mediaType: MediaType
    
    public init(resource: Resource, mediaType: MediaType) {
        self.resource = resource
        self.mediaType = mediaType
    }
}

extension Asset: IdentifiableResource {
    
    public var identifier: String {
        return resource.identifier
    }
}

extension Asset: CustomStringConvertible {
    
    public var description: String {
        return "Asset<\(Resource.self)> id=\(identifier) mediaType=\(mediaType)\n"
    }
}

extension Asset where Resource == PHAsset {
    
    public var phAsset: PHAsset {
        return resource
    }
    
    var duration: TimeInterval {
        return phAsset.duration
    }
    
    var durationDescription: String {
        let time = Int(duration)
        let min = time / 60
        let sec = time % 60
        return String(format: "%02ld:%02ld", min, sec)
    }
}
