//
//  Logger.swift
//  OnBeatCore
//
//  Created by Andrew J Wagner on 11/2/16.
//
//

import File

public final class Logger {
    public static var main: Logger = Logger()

    private var file: File? = nil

    public init() {}

    public func configure(forPath path: String) {
        do {
            self.file = try File(path: path, mode: .appendWrite)
        }
        catch let error {
            print("Error opening log: \(error)")
        }
    }

    public func log(_ text: String) {
        guard let file = self.file else {
            print(text)
            return
        }

        do {
            try file.write(text)
            try file.write("\n")
            try file.flush(deadline: 0)
        }
        catch {
            print(text)
        }
    }
}

extension File {
    func write(_ string: String) throws {
        try self.write(string, deadline: 0)
    }
}

