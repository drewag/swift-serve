//
//  EmailMessage.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 2/23/18.
//

public struct EmailMessage {
    public let part: MimePart

    public var headers: [String:String] {
        return self.part.headers
    }

    public var subject: String? {
        return self.headers["subject"]
    }

    public var to: [NamedEmailAddress]? {
        let raw = self.headers["to"]
        return NamedEmailAddress.addresses(from: raw)
    }

    public var content: MimePart.Content {
        return self.part.content
    }

    public init(raw: String) throws {
        self.part = try MimePart(rawContents: raw)
    }
}
