//
//  AbrData.swift
//  ABrushViewer
//
//  Created by Matthew.J on 2022/11/18.
//

import Foundation
import CoreGraphics

enum AbrVersion {
    case major1_2(version: Int16)
    case major6(minor: Int16)
}

extension AbrVersion: CustomStringConvertible {
    var description: String {
        switch self {
        case .major1_2(version: let version):
            return "version \(version)"
        case .major6(minor: let minor):
            return "version 6, subversion \(minor)"
        }
    }
}

enum AbrImage {
    case unsupportedType
    case bitmap(image: CGImage)
}

extension AbrImage {
    static func from(data: Data, width: Int, height: Int, depth: Int) -> Self {
        let newData: Data
        let bitsPerPixel: Int
        if depth == 8 {
            bitsPerPixel = 24
            var nd = Data(count: width * height * 3)
            for y in 0..<height {
                for x in 0..<width {
                    nd[(y * width + x) * 3..<(y * width + x + 1) * 3] = Data(repeating: 255 - data[y * width + x], count: 3)
                }
            }
            newData = nd
        } else if depth == 24 {
            bitsPerPixel = 24
            newData = data
        } else if depth == 32 {
            bitsPerPixel = 32
            newData = data
        } else {
            fatalError("invalid depth \(depth)")
        }

        let provider = CGDataProvider(data: newData as CFData)!
        let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: bitsPerPixel / 8 * width,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: .byteOrderDefault,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent)!

        return .bitmap(image: cgImage)
    }
}

struct AbrData {
    let version: AbrVersion
    let images: [AbrImage]
}
