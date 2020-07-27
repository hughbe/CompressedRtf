//
//  CompressedRtfHeader.swift
//  CompressedRtf
//
//  Created by Hugh Bellamy on 26/07/2020.
//  Copyright © 2020 Hugh Bellamy. All rights reserved.
//

import DataStream

internal struct CompressedRtfHeader {
    public static let headerSize = 0x10

    public init(data: inout DataStream) throws {
        if data.count < CompressedRtfHeader.headerSize {
            throw RtfDecompressorError.invalidSize(size: UInt32(data.count))
        }

        compSize = try data.readUInt32()
        rawSize = try data.readUInt32()
        let compTypeRaw = try data.readUInt32()
        crc = try data.readUInt32()

        guard let compType = CompressedRtfType(rawValue: compTypeRaw) else {
            throw RtfDecompressorError.invalidCompType(compType: compTypeRaw)
        }
        self.compType = compType

        if compSize < 0x0C || (compType == .compressed && compSize < 0x10) {
            throw RtfDecompressorError.invalidSize(size: compSize)
        }
    }
    
    public let compSize: UInt32
    public let rawSize: UInt32
    public let compType: CompressedRtfType
    public let crc: UInt32
    
    func dump() {
        print("-- CompressedRtfHeader ---")
        print("Comp Size: \(compSize.hexString)")
        print("Raw Size: \(rawSize.hexString)")
        print("Comp Type: \(compType)")
        print("Crc: \(crc.hexString)")
    }
}

