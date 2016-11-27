//
//  Logger.swift
//  OnBeatCore
//
//  Created by Andrew J Wagner on 11/2/16.
//
//

public protocol FileWriter {
    func openFileForWriting(at path: String)
    func write(_ text: String) -> Bool
}

public class Logger {
    static public var main = Logger()

    private var fileWriter: FileWriter?

    public func configureWithWriter(fileWriter: FileWriter) {
        self.fileWriter = fileWriter
    }

    public func log(_ text: String) {
        guard let fileWriter = self.fileWriter, fileWriter.write(text) else {
            print(text)
            return
        }
    }
}
