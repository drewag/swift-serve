//
//  RouterTests.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 10/29/16.
//
//

import XCTest
import Foundation
@testable import SwiftServe

struct TestRouter: Router {
    var routes: [Route] {
        return [
            .any("echo", handler: { (request: Request) -> RouterResponse in
                return .handled(request.response(body: request.string!))
            }),
            .get("sayHello", handler: { (request: Request) -> RouterResponse in
                return .handled(request.response(body: "Hello world!"))
            }),
            .post("sayHelloTo", handler: { (request: Request) -> RouterResponse in
                return .handled(request.response(body: "Hello \(request.string!)!"))
            }),
            .any("sub", router: TestRouter()),
            .get("getSub", router: TestRouter()),
        ]
    }
}

class RouterTests: XCTestCase {
    let server = TestServer(port: 0, router: TestRouter())

    func testNotARoute() throws {
        let response = try self.server.route(string: "", at: URL(string: "http://test.com/notARoute")!, as: .get)
        XCTAssertEqual(response.string, "")
        XCTAssertEqual(response.status, .notFound)
    }

    func testEcho() throws {
        var response = try self.server.route(string: "text", at: URL(string: "http://test.com/echo")!, as: .get)
        XCTAssertEqual(response.string, "text")
        XCTAssertEqual(response.status, .ok)

        response = try self.server.route(string: "text", at: URL(string: "http://test.com/echo")!, as: .post)
        XCTAssertEqual(response.string, "text")
        XCTAssertEqual(response.status, .ok)
    }

    func testSayingHello() throws {
        var response = try self.server.route(string: "", at: URL(string: "http://test.com/sayHello")!, as: .get)
        XCTAssertEqual(response.string, "Hello world!")
        XCTAssertEqual(response.status, .ok)

        response = try self.server.route(string: "", at: URL(string: "http://test.com/sayHello")!, as: .post)
        XCTAssertEqual(response.string, "")
        XCTAssertEqual(response.status, .notFound)
    }

    func testSayingHelloTo() throws {
        var response = try self.server.route(string: "world", at: URL(string: "http://test.com/sayHelloTo")!, as: .post)
        XCTAssertEqual(response.string, "Hello world!")
        XCTAssertEqual(response.status, .ok)

        response = try self.server.route(string: "", at: URL(string: "http://test.com/sayHelloTo")!, as: .get)
        XCTAssertEqual(response.string, "")
        XCTAssertEqual(response.status, .notFound)
    }

    func testSubRouter() throws {
        var response = try self.server.route(string: "", at: URL(string: "http://test.com/sub/sayHello")!, as: .get)
        XCTAssertEqual(response.string, "Hello world!")
        XCTAssertEqual(response.status, .ok)

        response = try self.server.route(string: "world", at: URL(string: "http://test.com/sub/sayHelloTo")!, as: .post)
        XCTAssertEqual(response.string, "Hello world!")
        XCTAssertEqual(response.status, .ok)

        response = try self.server.route(string: "", at: URL(string: "http://test.com/sub/sayHelloTo")!, as: .get)
        XCTAssertEqual(response.string, "")
        XCTAssertEqual(response.status, .notFound)

        response = try self.server.route(string: "world", at: URL(string: "http://test.com/sub/sub/sayHelloTo")!, as: .post)
        XCTAssertEqual(response.string, "Hello world!")
        XCTAssertEqual(response.status, .ok)

        response = try self.server.route(string: "", at: URL(string: "http://test.com/sub/sub/sayHelloTo")!, as: .get)
        XCTAssertEqual(response.string, "")
        XCTAssertEqual(response.status, .notFound)
    }

    func testGetSubRouter() throws {
        var response = try self.server.route(string: "", at: URL(string: "http://test.com/getSub/sayHello")!, as: .get)
        XCTAssertEqual(response.string, "Hello world!")
        XCTAssertEqual(response.status, .ok)

        response = try self.server.route(string: "", at: URL(string: "http://test.com/getSub/sayHello")!, as: .post)
        XCTAssertEqual(response.string, "")
        XCTAssertEqual(response.status, .notFound)
    }

    static var allTests: [(String, (RouterTests) -> () throws -> Void)] {
        return [
            ("testNotARoute", testNotARoute),
            ("testEcho", testEcho),
            ("testSayingHello", testSayingHello),
            ("testSayingHelloTo", testSayingHelloTo),
            ("testSubRouter", testSubRouter),
            ("testGetSubRouter", testGetSubRouter),
        ]
    }
}
