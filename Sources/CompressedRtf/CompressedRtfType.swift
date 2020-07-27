//
//  CompressedRtfType.swift
//  CompressedRtf
//
//  Created by Hugh Bellamy on 26/07/2020.
//  Copyright © 2020 Hugh Bellamy. All rights reserved.
//

internal enum CompressedRtfType : UInt32 {
    case compressed = 0x75465A4C
    case uncompressed = 0x414C454D
}
