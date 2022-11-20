//
//  AbrParser.swift
//  ABrushViewer
//
//  Created by Matthew.J on 2022/11/18.
//

import Foundation

enum AbrParserError: Error {
    case unsupportedVersion(version: Int16)
    case corruptedData
}

extension AbrParserError {
    var description: String {
        switch self {
        case .unsupportedVersion(let version):
            return "unsupportedVersion \(version)"
        case .corruptedData:
            return "corruptedData"
        }
    }
}

/// logic taken from [krita](https://github.com/KDE/krita/blob/master/libs/brush/kis_abr_brush_collection.cpp)
func parseAbrData(_ data: Data) throws -> AbrData {
    let extractor = DataExtractor(data: data)
    let version = try extractor.readBigEndian(type: Int16.self)
    switch version {
    case 1: fallthrough
    case 2:
        let images = try parseAbrImagesForV1_2(version: version, extractor: extractor)
        return AbrData(version: .major1_2(version: version), images: images)
    case 6:
        let subversion = try extractor.readBigEndian(type: Int16.self)
        let images = try parseAbrImagesForV6(subversion: subversion, extractor: extractor)
        return AbrData(version: .major6(minor: subversion), images: images)
    default:
        throw AbrParserError.unsupportedVersion(version: version)
    }
}

func parseAbrImagesForV1_2(version: Int16, extractor: DataExtractor) throws -> [AbrImage] {
    let count = try extractor.readBigEndian(type: Int16.self)
    var images: [AbrImage] = []
    for _ in 0..<count {
        let brushType = try extractor.readBigEndian(type: Int16.self)
        let brushSize = try extractor.readBigEndian(type: Int32.self)
        let nextBrushOffset = extractor.offset + Int(brushSize)
        if brushType == 2 {
            try extractor.skipBytes(count: 6)
            if version == 2 {
                let nameSize = try extractor.readBigEndian(type: Int32.self)
                // ignore brush name
                try extractor.skipBytes(count: MemoryLayout<Int16>.size * Int(nameSize))
            }
            try extractor.skipBytes(count: 9)
            let top = try extractor.readBigEndian(type: Int32.self)
            let left = try extractor.readBigEndian(type: Int32.self)
            let bottom = try extractor.readBigEndian(type: Int32.self)
            let right = try extractor.readBigEndian(type: Int32.self)
            let depth = try extractor.readBigEndian(type: Int16.self)
            let compression = try extractor.read(type: Int8.self)
            let width = right - left
            let height = bottom - top
            let size = width * (Int32(depth) >> 3) * height

            if height > 16384 {
                try extractor.seek(newOffset: nextBrushOffset)
                images.append(.unsupportedType)
            } else {
                let data: Data
                if compression == 0 {
                    data = try extractor.readBytes(count: Int(size))
                } else {
                    data = try rleDecode(extractor: extractor, size: size, height: height)
                }
                images.append(AbrImage.from(data: data, width: Int(width), height: Int(height), depth: Int(depth)))
            }
        } else {
            images.append(.unsupportedType)
            try extractor.seek(newOffset: nextBrushOffset)
        }
    }
    return images
}

func parseAbrImagesForV6(subversion: Int16, extractor: DataExtractor) throws -> [AbrImage] {
    try reach8BIMSection(extractor: extractor, name: "samp")
    let sampleSectionSize = try extractor.readBigEndian(type: Int32.self)
    let sampleSectionEndOffset = extractor.offset + Int(sampleSectionSize)
    var images: [AbrImage] = []
    while extractor.offset < sampleSectionEndOffset {
        let brushSize = try extractor.readBigEndian(type: Int32.self)
        let nextBrushOffset = Int((4 - brushSize % 4) % 4 + brushSize) + extractor.offset
        try extractor.skipBytes(count: 37)
        if subversion == 1 {
            try extractor.skipBytes(count: 10)
        } else {
            try extractor.skipBytes(count: 264)
        }
        let top = try extractor.readBigEndian(type: Int32.self)
        let left = try extractor.readBigEndian(type: Int32.self)
        let bottom = try extractor.readBigEndian(type: Int32.self)
        let right = try extractor.readBigEndian(type: Int32.self)
        let depth = try extractor.readBigEndian(type: Int16.self)
        let compression = try extractor.read(type: Int8.self)
        let width = right - left
        let height = bottom - top
        let size = width * (Int32(depth) >> 3) * height

        let data: Data
        if compression == 0 {
            data = try extractor.readBytes(count: Int(size))
        } else {
            data = try rleDecode(extractor: extractor, size: size, height: height)
        }
        images.append(AbrImage.from(data: data, width: Int(width), height: Int(height), depth: Int(depth)))

        try extractor.seek(newOffset: nextBrushOffset)
    }
    return images
}

func rleDecode(extractor: DataExtractor, size: Int32, height: Int32) throws -> Data {
    var scanlineLen: [Int16] = []
    for _ in 0..<height {
        try scanlineLen.append(extractor.readBigEndian(type: Int16.self))
    }
    var data = Data(capacity: Int(size))
    for len in scanlineLen {
        var j = 0
        while j < len {
            var n = try Int(extractor.read(type: Int8.self))
            j += 1
            if n >= 128 {
                n -= 256
            }
            if n < 0 {
                if n == -128 {
                    continue
                }
                n = -n + 1
                let byte = try extractor.read(type: UInt8.self)
                j += 1
                data.append(contentsOf: Array(repeating: byte, count: n))
            } else {
                for _ in 0..<n + 1 {
                    let byte = try extractor.read(type: UInt8.self)
                    j += 1
                    data.append(byte)
                }
            }
        }
    }

    return data
}

func reach8BIMSection(extractor: DataExtractor, name: String) throws {
    while true {
        let tag = try extractor.readBytes(count: 4)
        if tag != "8BIM".data(using: .ascii) {
            throw AbrParserError.corruptedData
        }
        let tagName = try extractor.readBytes(count: 4)
        if tagName == name.data(using: .ascii) {
            return
        }
        let sectionSize = try extractor.readBigEndian(type: Int32.self)
        try extractor.skipBytes(count: Int(sectionSize))
    }
}
