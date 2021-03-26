//
//  ImageTools.swift
//  Images
//
//  Created by Jakub Charvat on 24.11.2020.
//

import SwiftUI

//MARK: System Image
#if os(macOS)
typealias SystemImage = NSImage
#else
typealias SystemImage = UIImage
#endif


struct ImageTools {
    static private let fm = FileManager.default
    
    static func createCroppedImages(from image: NSImage) throws -> [NSImage] {
        let wholeImageSize = image.size
        let numX = 4
        let numY = 4
        let width = wholeImageSize.width / CGFloat(numX)
        let height = wholeImageSize.height / CGFloat(numY)
        let size = CGSize(width: width, height: height)
        
        var images = [NSImage]()
        
        for var yIdx in 0..<numY {
            yIdx = numY - (yIdx + 1)
            
            for xIdx in 0..<numX {
                let x = CGFloat(xIdx) * width
                let y = CGFloat(yIdx) * height
                let rect = CGRect(origin: CGPoint(x: x, y: y), size: size)
                
                guard let rep = image.bestRepresentation(for: rect, context: nil, hints: nil) else { throw ImageError.noRepresentation }
                let image = NSImage(size: size)
                
                image.lockFocus()
                if (rep.draw(in: NSRect(origin: .zero, size: size), from: rect, operation: .copy, fraction: 1, respectFlipped: false, hints: [:])) {
                    images.append(image)
                } else {
                    throw ImageError.unableToDrawImage
                }
                image.unlockFocus()
            }
        }
        
        return images
    }
}


//MARK: - Save Single Image
extension ImageTools {
    static func saveImage(_ image: SystemImage, at dir: URL, named name: String) throws {
        var rect = CGRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: [:]) else { throw ImageError.noRepresentation }
        let bits = NSBitmapImageRep(cgImage: cgImage)
        guard let pbm = bits.representation(using: .jpeg, properties: [:]) else { throw ImageError.unableToGenerateData }

        let folderExists = (try? dir.checkResourceIsReachable()) ?? false
        if !folderExists {
            try fm.createDirectory(at: dir, withIntermediateDirectories: false)
        }
        try pbm.write(to: dir.appendingPathComponent("\(name).jpeg"))
    }
}


//MARK: - Assigning File Names
extension ImageTools {
    static func getNextFileName(in dir: URL) throws -> String {
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
        
        let existingImages = try fm.contentsOfDirectory(atPath: dir.path)
            .map { $0.replacingOccurrences(of: ".pbm", with: "") }
            .map { $0.replacingOccurrences(of: ".jpeg", with: "") }
            .compactMap(Int.init)
            .sorted()
        
        guard let maxNumber = existingImages.max() else { return "0" }
        let imageNamesTillMax = Set(0...maxNumber)
        let availableImageNames = imageNamesTillMax.subtracting(existingImages)
        if let firstAvailableName = availableImageNames.first { return "\(firstAvailableName)" }
        return "\(maxNumber + 1)"
    }
}


//MARK: - Image Error
enum ImageError: Error {
    case noImage
    case outOfImages
    case noRepresentation
    case unableToGenerateData
    case unableToDrawImage
}
