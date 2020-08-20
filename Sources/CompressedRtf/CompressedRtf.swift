//
//  RtfDecompressor.swift
//  CompressedRtf
//
//  Created by Hugh Bellamy on 21/07/2020.
//  Copyright © 2020 Hugh Bellamy. All rights reserved.
//

import DataStream
import Foundation

public enum RtfDecompressorError: Error {
    case invalidSize(size: UInt32)
    case invalidCompType(compType: UInt32)
    case invalidDictionaryReference
    case corrupted
}

fileprivate extension BinaryInteger {
  func bit(at index: Int) -> Bool {
    return (self >> index) & 1 == 1
  }
}

public struct CompressedRtf {
    private static let circularDictionaryMaxLength = 0x1000
    private static var initialDictionary: [UInt8] = {
        // 2.1.2.1 Dictionary
        // The writer MUST initialize the dictionary (starting at offset 0) with the following ASCII string:
        var s = ""
        s += #"{\rtf1\ansi\mac\deff0\deftab720{\fonttbl;}"#
        s += #"{\f0\fnil \froman \fswiss \fmodern \fscript "#
        s += #"\fdecor MS Sans SerifSymbolArialTimes New RomanCourier{\colortbl\red0\green0\blue0"#
        s += "\r\n"
        s += #"\par \pard\plain\f0\fs20\b\i\u\tab\tx"#
        return [UInt8](s.data(using: .ascii)!)
    }()
    
    public static func decompress(data: [UInt8]) throws -> String {
        return try decompress(data: Data(data))
    }

    public static func decompress(data: Data) throws -> String {
        let bytes = try decompressBytes(data: data)
        guard let s = String(bytes: bytes, encoding: .ascii) else {
            throw RtfDecompressorError.corrupted
        }
        
        return s
    }
    
    public static func decompressBytes(data: Data) throws -> [UInt8] {
        var dataStream = DataStream(data: data)
        let header = try CompressedRtfHeader(data: &dataStream)
        switch header.compType {
        case .uncompressed:
            // 2.2.3.1 Decompressing Input of COMPTYPE UNCOMPRESSED
            // When the COMPTYPE field is set to UNCOMPRESSED, the reader SHOULD read all bytes until the end
            // of the stream is reached, regardless of the value of the RAWSIZE field. Or, the reader MAY read the
            // number of bytes specified by the RAWSIZE field from the input (the Header field) and write them to
            // the output. The COMPTYPE, RAWSIZE and Header fields are specified in section 2.1.3.1.1.
            // The reader MUST NOT validate the value of the CRC field.
            return try dataStream.readBytes(count: dataStream.remainingCount)
        case .compressed:
            // 2.2.3.2 Decompressing Input of COMPTYPE COMPRESSED
            // If at any point during the steps specified in this section, the end of the input is reached before the
            // termination of decompression, then the reader MUST treat the input as corrupt.
            // When the COMPTYPE field is set to COMPRESSED, the decompression process is a straightforward
            // loop, as follows:
            // - Read the CONTROL field, as specified in section 2.1.3.1.1, from the input.
            // - Starting with the  lowest bit (the 0x01 bit) in the CONTROL field, test each bit and carry out the
            // actions as follows.
            // - After all bits in the CONTROL field have been tested, read another value of a CONTROL field
            // from the input and repeat the bit-testing process.
            // For each bit, the reader MUST evaluate its value and complete the corresponding steps as specified in
            // this section.
            var dictionary = [UInt8](repeating: 0, count: circularDictionaryMaxLength)
            let initialLength = initialDictionary.count
            dictionary.replaceSubrange(0..<initialLength, with: initialDictionary)
            
            var writeOffset = initialLength
            var result = [UInt8]()

            let sizeToUse = data.count//max(data.count, Int(header.compSize))
            while dataStream.position < sizeToUse {
                guard let controlByte = try? dataStream.read() as UInt8 else {
                    // Not really in the spec, but match behaviour of WrapCompressedRTFStream
                    return result
                }
                
                for j in 0..<8 {
                    // If the value of the bit is zero:
                    // 1. Read a 1-byte literal from the input and write it to the output.
                    // 2. Set the byte in the dictionary at the current write offset to the literal from step 1.
                    // 3. Increment the write offset and update the end offset, as appropriate, as specified in section 2.1.3.1.4.
                    if !controlByte.bit(at: j) {
                        guard let value = try? dataStream.read() as UInt8 else {
                            // Not really in the spec, but match behaviour of WrapCompressedRTFStream
                            return result
                        }
    
                        result.append(value)
                        dictionary[writeOffset] = value
                        writeOffset = (writeOffset + 1) % circularDictionaryMaxLength
                    } else {
                        // If the value of the bit is 1:
                        // 1. Read a 16-bit dictionary reference from the input in big-endian byte-order.
                        guard let loWord = try? dataStream.read() as UInt8, let hiWord = try? dataStream.read() as UInt8 else {
                            // Not really in the spec, but match behaviour of WrapCompressedRTFStream
                            return result
                        }
                        
                        let token = Int(loWord) << 8 | Int(hiWord)
                        
                        // 2. Extract the offset from the dictionary reference, as specified in section 2.1.3.1.5.
                        let offset = (token >> 4) & 0b111111111111
                        
                        // 3. Compare the offset to the dictionary's write offset. If they are equal, then the decompression is
                        // complete; exit the decompression loop. If they are not equal, continue to the next step.
                        if offset == writeOffset {
                            return result
                        }
                        
                        // 4. Set the dictionary's read offset to offset.
                        var readOffset = offset
                        
                        // 5. Extract the length from the dictionary reference and calculate the actual length by adding 2 to the
                        // length that is extracted from the dictionary reference.
                        let length = token & 0b1111
                        let actualLength = length + 2
                        
                        // 6. Read a byte from the current dictionary read offset and write it to the output.
                        for _ in 0..<actualLength {
                            let byte = dictionary[readOffset]
                            result.append(byte)

                            // 7. Increment the read offset, wrapping as appropriate, as specified in section 2.1.3.1.4.
                            readOffset = (readOffset + 1) % circularDictionaryMaxLength

                            // 8. Write the byte to the dictionary at the write offset.
                            dictionary[writeOffset] = byte

                            // 9. Increment the write offset and update the end offset, as appropriate, as specified in section 2.1.3.1.4
                            writeOffset = (writeOffset + 1) % circularDictionaryMaxLength

                            // 10. Continue from step 6 until the number of bytes calculated in step 5 has been read from the dictionary.
                        }
                    }
                }
            }

            return result
        }
    }
}
