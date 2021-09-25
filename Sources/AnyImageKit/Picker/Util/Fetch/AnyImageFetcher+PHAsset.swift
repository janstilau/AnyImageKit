//
//  AnyImageFetcher+PHAsset.swift
//  AnyImageFetcher+PHAsset
//
//  Created by 刘栋 on 2021/8/23.
//  Copyright © 2021 AnyImageProject.org. All rights reserved.
//

import Photos
import UIKit

extension AnyImageFetcher where Resource == PHAsset {
    
    func fetchPhoto(resource: Resource, type: ImageResourceStorageType, completion: @escaping ImageResourceLoadCompletion) {
        
    }
    
    func fetchLivePhoto(resource: Resource, type: LivePhotoResourceStorageType, completion: @escaping LivePhotoResourceLoadCompletion) {
        
    }
    
    func fetchVideo(resource: Resource, type: VideoResourceStorageType, completion: @escaping VideoResourceLoadCompletion) {
        
    }
}

extension AnyImageFetcher where Resource == PHAsset {
    
    private var phImageManager: PHImageManager {
        return PHImageManager.default()
    }
    
    private func loadLibraryPhoto(resource: Resource, options: LibraryPhotoLoadOptions, completion: @escaping LibraryPhotoLoadCompletion) -> Int {
        let phRequestOptions = PHImageRequestOptions()
        phRequestOptions.version = options.version
        phRequestOptions.resizeMode = options.resizeMode
        phRequestOptions.isNetworkAccessAllowed = options.isNetworkAccessAllowed
        phRequestOptions.isSynchronous = false
        
        let identifier = resource.identifier
        let requestID = phImageManager.requestImage(for: resource, targetSize: options.targetSize, contentMode: .aspectFill, options: phRequestOptions) { (image, info) in
            guard let info = info, let requestID = info[PHImageResultRequestIDKey] as? PHImageRequestID else {
                completion(.failure(.invalidInfo))
                return
            }
            let isCancelled = info[PHImageCancelledKey] as? Bool ?? false
            let error = info[PHImageErrorKey] as? Error // FIXME: check & throw error out
            let isDegraded = info[PHImageResultIsDegradedKey] as? Bool ?? false
            let isDownloaded = !isCancelled && error == nil
            if isDownloaded, let image = image {
                completion(.success(.init(identifier: identifier, requestID: Int(requestID), image: image, isDegraded: isDegraded)))
            } else {
                let isInCloud = info[PHImageResultIsInCloudKey] as? Bool ?? false
                if isInCloud {
                    completion(.failure(AnyImageError.resourceIsInCloud))
                } else {
                    completion(.failure(AnyImageError.invalidData))
                }
            }
        }
        return Int(requestID)
    }
    
    private func loadLibraryPhotoData(resource: Resource, options: LibraryPhotoDataLoadOptions, completion: @escaping LibraryPhotoDataLoadCompletion) -> Int {
        let phRequestOptions = PHImageRequestOptions()
        phRequestOptions.version = options.version
        phRequestOptions.progressHandler = options.progressHandler
        phRequestOptions.isNetworkAccessAllowed = options.isNetworkAccessAllowed
        phRequestOptions.isSynchronous = false
        
        let identifier = resource.identifier
        func response(data: Data?, dataUTI: String?, orientation: CGImagePropertyOrientation, info: [AnyHashable: Any]?, completion: @escaping LibraryPhotoDataLoadCompletion) {
            guard let data = data, let requestID = (info?[PHImageResultRequestIDKey] as? PHImageRequestID) else {
                completion(.failure(.invalidData))
                return
            }
            guard let dataUTI = dataUTI else {
                completion(.failure(.invalidDataUTI))
                return
            }
            completion(.success(.init(identifier: identifier, requestID: Int(requestID), data: data, dataUTI: dataUTI, orientation: orientation)))
        }
        
        let requestID: PHImageRequestID
        if #available(iOS 13.0, *) {
            requestID = phImageManager.requestImageDataAndOrientation(for: resource, options: phRequestOptions) { (data, dataUTI, orientation, info) in
                response(data: data, dataUTI: dataUTI, orientation: orientation, info: info, completion: completion)
            }
        } else {
            requestID = phImageManager.requestImageData(for: resource, options: phRequestOptions) { (data, dataUTI, uiOrientation, info) in
                response(data: data, dataUTI: dataUTI, orientation: .init(uiOrientation), info: info, completion: completion)
            }
        }
        return Int(requestID)
    }
    
    private func loadLibraryLivePhoto(resource: Resource, options: LibraryLivePhotoLoadOptions, completion: @escaping LibraryLivePhotoLoadCompletion) -> Int {
        let phRequestOptions = PHLivePhotoRequestOptions()
        phRequestOptions.version = options.version
        phRequestOptions.deliveryMode = options.deliveryMode
        phRequestOptions.isNetworkAccessAllowed = options.isNetworkAccessAllowed
        phRequestOptions.progressHandler = options.progressHandler
        
        let identifier = resource.identifier
        let requestID = phImageManager.requestLivePhoto(for: resource, targetSize: options.targetSize, contentMode: .aspectFill, options: phRequestOptions) { (livePhoto, info) in
            if let livePhoto = livePhoto, let requestID = info?[PHImageResultRequestIDKey] as? PHImageRequestID {
                completion(.success(.init(identifier: identifier, requestID: Int(requestID), livePhoto: livePhoto)))
            } else {
                completion(.failure(.invalidLivePhoto))
            }
        }
        return Int(requestID)
    }
    
    private func loadLibraryVideo(resource: Resource, options: LibraryVideoLoadOptions, completion: @escaping LibraryVideoLoadComletion) -> Int {
        let phRequestOptions = PHVideoRequestOptions()
        phRequestOptions.version = options.version
        phRequestOptions.isNetworkAccessAllowed = options.isNetworkAccessAllowed
        phRequestOptions.deliveryMode = options.deliveryMode
        phRequestOptions.progressHandler = options.progressHandler
        
        let identifier = resource.identifier
        let requestID = phImageManager.requestAVAsset(forVideo: resource, options: phRequestOptions) { (avAsset, avAudioMix, info) in
            if let avAsset = avAsset, let requestID = (info?[PHImageResultRequestIDKey] as? PHImageRequestID) {
                completion(.success(.init(identifier: identifier, requestID: Int(requestID), avAsset: avAsset)))
            } else {
                completion(.failure(.invalidVideo))
            }
        }
        return Int(requestID)
    }
    
    private func loadLibraryVideoData(resource: Resource, options: LibraryVideoDataLoadOptions, completion: @escaping LibraryVideoDataLoadCompletion) -> Int {
        let requestOptions = PHVideoRequestOptions()
        requestOptions.isNetworkAccessAllowed = options.isNetworkAccessAllowed
        requestOptions.version = options.version
        requestOptions.deliveryMode = options.deliveryMode
        requestOptions.progressHandler = options.progressHandler
        
        let identifier = resource.identifier
        let requestID = phImageManager.requestExportSession(forVideo: resource, options: requestOptions, exportPreset: options.exportPreset.rawValue) { (exportSession, info) in
            if let exportSession = exportSession, let requestID = (info?[PHImageResultRequestIDKey] as? PHImageRequestID) {
                completion(.success(.init(identifier: identifier, requestID: Int(requestID), exportSession: exportSession)))
            } else {
                completion(.failure(.invalidExportSession))
            }
        }
        return Int(requestID)
    }
}

struct LibraryPhotoLoadOptions {
    
    let targetSize: CGSize
    let resizeMode: PHImageRequestOptionsResizeMode
    let version: PHImageRequestOptionsVersion
    let isNetworkAccessAllowed: Bool
    
    init(targetSize: CGSize = PHImageManagerMaximumSize,
         resizeMode: PHImageRequestOptionsResizeMode = .fast,
         version: PHImageRequestOptionsVersion = .current,
         isNetworkAccessAllowed: Bool = true) {
        self.targetSize = targetSize
        self.resizeMode = resizeMode
        self.version = version
        self.isNetworkAccessAllowed = isNetworkAccessAllowed
    }
}

struct LibraryPhotoDataLoadOptions {
    
    let version: PHImageRequestOptionsVersion
    let isNetworkAccessAllowed: Bool
    let progressHandler: PHAssetImageProgressHandler?
    
    init(version: PHImageRequestOptionsVersion = .current,
         isNetworkAccessAllowed: Bool = true,
         progressHandler: PHAssetImageProgressHandler? = nil) {
        self.version = version
        self.isNetworkAccessAllowed = isNetworkAccessAllowed
        self.progressHandler = progressHandler
    }
}

struct LibraryLivePhotoLoadOptions {
    
    let targetSize: CGSize
    let version: PHImageRequestOptionsVersion
    let deliveryMode: PHImageRequestOptionsDeliveryMode
    let isNetworkAccessAllowed: Bool
    let progressHandler: PHAssetImageProgressHandler?
    
    init(targetSize: CGSize = .init(width: 500, height: 500),
         version: PHImageRequestOptionsVersion = .current,
         deliveryMode: PHImageRequestOptionsDeliveryMode = .highQualityFormat,
         isNetworkAccessAllowed: Bool = true,
         progressHandler: PHAssetImageProgressHandler? = nil) {
        self.targetSize = targetSize
        self.version = version
        self.deliveryMode = deliveryMode
        self.isNetworkAccessAllowed = isNetworkAccessAllowed
        self.progressHandler = progressHandler
    }
}

struct LibraryVideoLoadOptions {
    
    let isNetworkAccessAllowed: Bool
    let version: PHVideoRequestOptionsVersion
    let deliveryMode: PHVideoRequestOptionsDeliveryMode
    let progressHandler: PHAssetVideoProgressHandler?
    
    init(isNetworkAccessAllowed: Bool = true,
         version: PHVideoRequestOptionsVersion = .current,
         deliveryMode: PHVideoRequestOptionsDeliveryMode = .highQualityFormat,
         progressHandler: PHAssetVideoProgressHandler? = nil) {
        self.isNetworkAccessAllowed = isNetworkAccessAllowed
        self.version = version
        self.deliveryMode = deliveryMode
        self.progressHandler = progressHandler
    }
}

struct LibraryVideoDataLoadOptions {
    
    let isNetworkAccessAllowed: Bool
    let version: PHVideoRequestOptionsVersion
    let deliveryMode: PHVideoRequestOptionsDeliveryMode
    let exportPreset: VideoExportPreset
    let progressHandler: PHAssetVideoProgressHandler?
    
    init(isNetworkAccessAllowed: Bool = true,
         version: PHVideoRequestOptionsVersion = .current,
         deliveryMode: PHVideoRequestOptionsDeliveryMode = .highQualityFormat,
         exportPreset: VideoExportPreset = .passthrough,
         progressHandler: PHAssetVideoProgressHandler? = nil) {
        self.isNetworkAccessAllowed = isNetworkAccessAllowed
        self.version = version
        self.deliveryMode = deliveryMode
        self.exportPreset = exportPreset
        self.progressHandler = progressHandler
    }
}

typealias LibraryPhotoLoadCompletion = (Result<LibraryPhotoLoadResponse, AnyImageError>) -> Void
typealias LibraryPhotoDataLoadCompletion = (Result<LibraryPhotoDataLoadResponse, AnyImageError>) -> Void
typealias LibraryLivePhotoLoadCompletion = (Result<LibraryLivePhotoLoadResponse, AnyImageError>) -> Void
typealias LibraryVideoLoadComletion = (Result<LibraryVideoLoadResponse, AnyImageError>) -> Void
typealias LibraryVideoDataLoadCompletion = (Result<LibraryVideoDataLoadResponse, AnyImageError>) -> Void

struct LibraryPhotoLoadResponse: IdentifiableResource {
    
    let identifier: String
    let requestID: Int
    let image: UIImage
    let isDegraded: Bool
}

struct LibraryPhotoDataLoadResponse: IdentifiableResource {
    
    let identifier: String
    let requestID: Int
    let data: Data
    let dataUTI: String
    let orientation: CGImagePropertyOrientation
}

struct LibraryLivePhotoLoadResponse: IdentifiableResource {
    
    let identifier: String
    let requestID: Int
    let livePhoto: PHLivePhoto
}

struct LibraryVideoLoadResponse: IdentifiableResource {
    
    let identifier: String
    let requestID: Int
    let avAsset: AVAsset
}

struct LibraryVideoDataLoadResponse: IdentifiableResource {
    
    let identifier: String
    let requestID: Int
    let exportSession: AVAssetExportSession
}