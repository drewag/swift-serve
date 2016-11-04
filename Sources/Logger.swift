//
//  Logger.swift
//  OnBeatCore
//
//  Created by Andrew J Wagner on 11/2/16.
//
//

import Foundation

public final class Logger {
    public static var main: Logger = Logger()

    private var file: FileHandle? = nil

    public init() {}

    public func configure(forPath path: String) {
        self.file = FileHandle(forWritingAtPath: path)
    }

    public func log(_ text: String) {
        guard let file = self.file else {
            print(text)
            return
        }

        file.write(text)
        file.write("\n")
    }
}

extension FileHandle {
    func write(_ string: String) {
        self.write(string.data(using: .utf8)!)
    }
}
