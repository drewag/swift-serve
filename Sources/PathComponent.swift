//
//  PathComponent.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 10/29/16.
//
//

import Swiftlier

public protocol PathComponent {
    func matches(path: String, using method: HTTPMethod) -> Bool
    func consume(path: String) -> String
}

struct StaticPathComponent: PathComponent {
    let pattern: String
    let method: HTTPMethod
    let allowSubPaths: Bool

    func matches(path: String, using method: HTTPMethod) -> Bool {
        guard method.matches(self.method) else {
            return false
        }

        if allowSubPaths {
            return path.hasPrefix(self.pattern + "/") || path == self.pattern
        }
        else {
            return path == self.pattern || path == "\(self.pattern)/"
        }
    }

    func captureTextFromPath(path: String) -> String {
        if path.hasPrefix(self.pattern) {
            return self.pattern
        }
        return ""
    }

    func consume(path: String) -> String {
        var output = String()
        for (index, character) in path.characters.enumerated() {
            if index < self.pattern.characters.count
                || index == self.pattern.characters.count && character == "/"
            {
                continue
            }
            output.append(character)
        }
        return output
    }
}

struct VariablePathComponent<CaptureType: CapturableType>: PathComponent {
    let method: HTTPMethod
    let consumeEntireSubPath: Bool

    init(type: CaptureType.Type, method: HTTPMethod, consumeEntireSubPath: Bool) {
        self.method = method
        self.consumeEntireSubPath = consumeEntireSubPath
    }

    func matches(path: String, using method: HTTPMethod) -> Bool {
        guard method.matches(self.method) else {
            return false
        }

        return self.process(path: path) != nil
    }

    func process(path: String) -> CaptureType? {
        guard let thisComponent = self.captureText(fromPath: path) else {
            return nil
        }
        return CaptureType(fromCaptureText: thisComponent)
    }

    func captureText(fromPath path: String) -> String? {
        guard !self.consumeEntireSubPath else {
            return path
        }

        var output = String()
        for character in path.characters {
            if character == "/" {
                break
            }
            output.append(character)
        }

        return output
    }

    func consume(path: String) -> String {
        var output = String()
        var foundSlash = false
        for character in path.characters {
            if foundSlash {
                output.append(character)
            }
            else if character == "/" {
                foundSlash = true
            }
        }
        return output
    }
}

struct AllPathComponent: PathComponent {
    let method: HTTPMethod

    func matches(path: String, using method: HTTPMethod) -> Bool {
        guard method.matches(self.method) else {
            return false
        }
        return true
    }

    func consume(path: String) -> String {
        return path
    }
}
