//
//  HTMLFormTests.swift
//  SwiftServeTests
//
//  Created by Andrew J Wagner on 6/9/19.
//

import XCTest
@testable import SwiftServe

class HTMLFormTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DatabaseSetup = DatabaseSpec(name: "db", username: "user", password: "password")
    }
    
    func testBasicForm() {
        enum TestField: String, HTMLFormField {
            case key1, key2, key3

            static let action = "testing"
        }

        let request = self.createRequest(withPostData: [
            ("key1", "value1"),
            ("key2", "value2"),
            ("key3", "value3"),
        ])

        var didParse = false
        let _: HTMLForm<TestField> = request.parseForm() { form in
            XCTAssertEqual(try form.requiredValue(for: .key1), "value1")
            XCTAssertEqual(try form.requiredValue(for: .key2), "value2")
            XCTAssertEqual(try form.requiredValue(for: .key3), "value3")
            didParse = true
            return nil
        }
        XCTAssertTrue(didParse)
    }
}

extension HTMLFormTests {
    func createRequest(withPostData postData: [(String,String)]) -> TestRequest {
        let url = URL(string: "http://example.com")!
        let raw = FormUrlEncoded.encode(postData)
        let data = raw.data(using: .utf8)!
        return TestRequest(method: .post, endpoint: url, data: data)
    }
}
