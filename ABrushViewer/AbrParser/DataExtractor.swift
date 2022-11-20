//
//  DataExtractor.swift
//  ABrushViewer
//
//  Created by Matthew.J on 2022/11/18.
//

import Foundation

class DataExtractor {
    private let data: Data
    private(set) var offset: Int

    init(data: Data) {
        self.data = data
        self.offset = 0
    }

    func seek(newOffset: Int) throws {
        guard newOffset >= 0 && newOffset < data.count else {
            throw AbrParserError.corruptedData
        }
        offset = newOffset
    }

    func skipBytes(count: Int) throws {
        guard data.count >= offset + count else {
            throw AbrParserError.corruptedData
        }
        offset += count
    }

    func readBytes(count: Int) throws -> Data {
        guard data.count >= offset + count else {
            throw AbrParserError.corruptedData
        }
        defer {
            offset += count
        }
        return data[offset..<offset + count]
    }

    func read<T>(type: T.Type) throws -> T {
        let size = MemoryLayout<T>.size
        return try readBytes(count: size).withUnsafeBytes { p in
            p.loadUnaligned(as: T.self)
        }
    }

    func readBigEndian<T: FixedWidthInteger>(type: T.Type) throws -> T {
        let value = try read(type: type)
        return T.init(bigEndian: value)
    }

}
