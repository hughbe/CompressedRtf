//
//  CompressedRtfHeader.swift
//
//
//  Created by Hugh Bellamy on 12/10/2020.
//

import DataStream

internal struct CompressedRtfHeader {
    public static let headerSize = 0x10

    public init(data: inout DataStream) throws {
        if data.count < CompressedRtfHeader.headerSize {
            throw RtfDecompressorError.invalidSize(size: UInt32(data.count))
        }

        self.compSize = try data.read(endianess: .littleEndian)
        self.rawSize = try data.read(endianess: .littleEndian)

        let compTypeRaw = try data.read(endianess: .littleEndian) as UInt32
        guard let compType = CompressedRtfType(rawValue: compTypeRaw) else {
            throw RtfDecompressorError.invalidCompType(compType: compTypeRaw)
        }
        self.compType = compType

        self.crc = try data.read(endianess: .littleEndian)

        if self.compSize < 0x0C || (compType == .compressed && self.compSize < 0x10) {
            throw RtfDecompressorError.invalidSize(size: self.compSize)
        }
    }
    
    public let compSize: UInt32
    public let rawSize: UInt32
    public let compType: CompressedRtfType
    public let crc: UInt32
}
