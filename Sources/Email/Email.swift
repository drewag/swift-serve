//
//  Email.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 3/2/18.
//

import Foundation
import Swiftlier
import Stencil

public class EmailSentEvent: EventType { public typealias CallbackParam = Email }

public struct Email {
    public static var DebugMode = false

    public struct Builder {
        let id: String

        var html: String = ""
        var plain: String = ""
        var attachments = [MimePart]()

        init(id: String) {
            self.id = id
        }

        var bodyAndHeaders: (body: String, headers: [CaseInsensitiveKey:String]) {
            var (body, headers) = self.rootPart.rawBodyAndHeaders
            headers["Mime-Version"] = "1.0"

            if let replyTo = self.replyTo {
                headers["Reply-To"] = Email.sanitize(replyTo)
            }

            return (body, headers)

        }

        public var replyTo: String? = nil
        public var returnPath: String? = nil
        public mutating func append(html: String) {
            self.html += html
        }

        public mutating func append(plain: String) {
            self.plain += plain
        }

        public mutating func appendAttachment(withContent content: MimePart.Content, named name: String?) {
            self.attachments.append(MimePart(content: content, name: name))
        }
    }

    let id: String
    public let subject: String
    public let recipient: String
    public let returnPath: String?
    public let from: String
    public let body: String
    public var headers = [CaseInsensitiveKey:String]()

    public init(to: String, subject: String, from: String, replyTo: String? = nil, HTMLBody: String) {
        self.init(to: to, subject: subject, from: from) { builder in
            builder.replyTo = replyTo
            builder.append(html: HTMLBody)
        }
    }

    public init(
        to: String,
        subject: String,
        from: String,
        replyTo: String? = nil,
        returnPath: String? = nil,
        template: String,
        paragraphStyle: String = "font-family:sans-serif;font-size:14px;font-weight:normal;margin:0;margin-bottom:15px",
        build: @escaping (inout [String:Any]) throws -> ()
        ) throws
    {
        try self.init(to: to, subject: subject, from: from) { builder in
            builder.replyTo = replyTo
            builder.returnPath = returnPath

            let environment = Environment(emailWithParagaraphStyle: paragraphStyle)
            var context = [String:Any]()

            try build(&context)

            if template.hasSuffix(".html") {
                builder.append(html: try environment.renderTemplate(name: template, context: context))
            }
            else if template.hasSuffix(".txt") {
                builder.append(plain: try environment.renderTemplate(name: template, context: context))
            }
            else {
                builder.append(html: try environment.renderTemplate(name: "\(template).html", context: context))
                builder.append(plain: try environment.renderTemplate(name: "\(template).txt", context: context))
            }
        }
    }

    public init(to: String, subject: String, from: String, replyTo: String? = nil, plainBody: String) {
        self.init(to: to, subject: subject, from: from) { builder in
            builder.replyTo = replyTo
            builder.append(plain: plainBody)
        }
    }

    public init(to: String, subject: String, from: String, build: (inout Builder) throws -> ()) rethrows {
        self.recipient = Email.sanitize(to)
        self.from = Email.sanitize(from)
        self.subject = Email.sanitize(subject)
        let id = UUID().uuidString
        var builder = Builder(id: id)
        try build(&builder)
        (self.body, self.headers) = builder.bodyAndHeaders
        self.id = id
        self.returnPath = builder.returnPath
    }

    @discardableResult
    public func send() -> Bool {
        do {
            print("Sending email to '\(self.recipient)' with subject '\(self.subject)'")
            let file = try self.file()

            func debug() throws -> Bool {
                var body = """
                Subject: \(self.subject)
                From: \(self.from)
                """

                for (key,value) in self.headers {
                    body += "\n\(key): \(value)"
                }
                body += "\n\(self.body)"
                let _ = try file.createFile(containing: body.data(using: .utf8), canOverwrite: true)
                print("Debug mode. See \(file.url.relativePath) for content.")
                EventCenter.defaultCenter().triggerEvent(EmailSentEvent.self, params: self)
                return true
            }

            #if os(Linux)
                guard !type(of:self).DebugMode else {
                    return try debug()
                }
                let _ = try file.createFile(containing: self.body.data(using: .utf8), canOverwrite: true)
                let task = Process()
                task.launchPath = "/bin/sh"
                var command = "cat \(file.url.relativePath) | mail '\(self.recipient)' -s '\(self.subject)' -a 'From:\(self.from)'"
                if let returnPath = self.returnPath {
                    command += " -r \(returnPath)"
                }
                for (key,value) in self.headers {
                    command += " -a '\(key):\(value)'"
                }
                task.arguments = ["-c", command]

                task.launch()
                task.waitUntilExit()
                let _ = try? file.file?.delete()
                guard task.terminationStatus == 0 else {
                    return false
                }
                EventCenter.defaultCenter().triggerEvent(EmailSentEvent.self, params: self)
                return true
            #else
                return try debug()
            #endif

        }
        catch {
            print("Error sending email: \(error)")
            return false
        }
    }
}

private extension Email.Builder {
    var rootPart: MimePart {
        let htmlPart = MimePart(content: .html(self.html), name: nil)
        let plainPart = MimePart(content: .plain(self.plain), name: nil)
        let alternativePart = MimePart(content: .multipartAlternative([plainPart,htmlPart]), name: nil)

        switch (self.html.isEmpty, self.plain.isEmpty, self.attachments.isEmpty) {
        case (false, true, true):
            return htmlPart
        case (false, true, false):
            let parts = [htmlPart] + self.attachments
            return MimePart(content: .multipartMixed(parts), name: nil)
        case (true, false, true), (true, true, true):
            return plainPart
        case (true, false, false):
            let parts = [plainPart] + self.attachments
            return MimePart(content: .multipartMixed(parts), name: nil)
        case (false, false, true):
            return alternativePart
        case (false, false, false):
            let parts = [alternativePart] + self.attachments
            return MimePart(content: .multipartMixed(parts), name: nil)
        case (true, true, false):
            return MimePart(content: .multipartMixed(self.attachments), name: nil)
        }
    }
}

private extension Email {
    static func sanitize(_ parameter: String) -> String {
        return parameter.replacingOccurrences(of: "'", with: "’")
    }

    static func sanitize(_ parameter: String?) -> String? {
        guard let param = parameter else {
            return nil
        }
        return self.sanitize(param)
    }

    func file() throws -> Path {
        return try FileSystem.default.rootDirectory.subdirectory("tmp").file("\(self.id).eml")
    }
}
