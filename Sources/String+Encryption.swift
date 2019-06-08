//
//  String+Encryption.swift
//  SwiftServe
//
//  Created by Andrew Wagner on 5/17/19.
//

import CryptoSwift

extension String {
    static let base64Characters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")

    public func encrypt(withHash hash: String) -> String {
        let password: [UInt8] = self.utf8.map {$0}
        let salt: [UInt8] = hash.utf8.map {$0}
        let result = try! PKCS5.PBKDF2(password: password, salt: salt).calculate()

        var output = ""
        var firstByte: UInt8?
        var secondByte: UInt8?
        var thirdByte: UInt8?

        func appendPattern() {
            guard let first = firstByte else {
                return
            }
            let second = secondByte ?? 0
            let third = thirdByte ?? 0

            output.append(String.base64Characters[Int(first >> 2)])
            output.append(String.base64Characters[Int((first << 6) >> 2 + second >> 4)])
            if secondByte == nil {
                output.append("=")
            }
            else {
                output.append(String.base64Characters[Int((second << 4) >> 2 + third >> 6)])
            }
            if thirdByte == nil {
                output.append("=")
            }
            else {
                output.append(String.base64Characters[Int(third & 63)])
            }
        }

        for byte in result {
            guard firstByte != nil else {
                firstByte = byte
                continue
            }
            guard secondByte != nil else {
                secondByte = byte
                continue
            }
            thirdByte = byte

            appendPattern()

            firstByte = nil
            secondByte = nil
            thirdByte = nil
        }

        appendPattern()
        return output
    }
}
