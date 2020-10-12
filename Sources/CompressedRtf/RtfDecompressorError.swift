//
//  RtfDecompressorError.swift
//  
//
//  Created by Hugh Bellamy on 12/10/2020.
//

public enum RtfDecompressorError: Error {
    case invalidSize(size: UInt32)
    case invalidCompType(compType: UInt32)
    case invalidDictionaryReference
    case corrupted
}
