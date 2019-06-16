//
//  FormEncoderTests.swift
//  SwiftServeTests
//
//  Created by Andrew J Wagner on 6/9/19.
//

import XCTest
import Swiftlier
@testable import SwiftServe

class FormEncoderTests: XCTestCase {
    func testValidBasicForm() throws {
        struct Value: Encodable {
            let string: String = "some string"
            let int: Int = 1
            let float: Float = 2.3
            let double: Double = 4.5
            let date: Date = Date.now
            let yes: Bool = true
            let no: Bool = false
            let email = try! EmailAddress(string: "user@example.com")
        }

        let value = Value()
        let encoder = FormEncoder()
        try value.encode(to: encoder)

        let rawValues = encoder.values.rawValues
        XCTAssertEqual(rawValues.count, 8)
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "string" && $0.1 == "some string"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "int" && $0.1 == "1"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "float" && $0.1 == "2.3"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "double" && $0.1 == "4.5"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "date" && $0.1 == value.date.iso8601DateTime}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "yes" && $0.1 == "Yes"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "no" && $0.1 == "No"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "email" && $0.1 == "user@example.com"}))
    }

    func testOptional() throws {
        struct Value: Encodable {
            let string1: String? = "some string"
            let string2: String? = nil
        }

        let value = Value()
        let encoder = FormEncoder()
        try value.encode(to: encoder)

        let rawValues = encoder.values.rawValues
        XCTAssertEqual(rawValues.count, 1)
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "string1" && $0.1 == "some string"}))
    }

    func testNested() throws {
        struct Value: Encodable {
            struct Student: Encodable {
                let name: String = "Jane"
                let age: Int = 22
                let gpa: Float = 3.7
                let passing: Bool = true
            }
            struct Teacher: Encodable {
                let performance: Double = 4.5
                let hired: Date = Date.now
                let temp: Bool = false
            }
            let student = Student()
            let teacher = Teacher()
        }

        let value = Value()
        let encoder = FormEncoder()
        try value.encode(to: encoder)

        let rawValues = encoder.values.rawValues
        XCTAssertEqual(rawValues.count, 7)
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "student[name]" && $0.1 == "Jane"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "student[age]" && $0.1 == "22"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "student[gpa]" && $0.1 == "3.7"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "student[passing]" && $0.1 == "Yes"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "teacher[performance]" && $0.1 == "4.5"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "teacher[hired]" && $0.1 == value.teacher.hired.iso8601DateTime}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "teacher[temp]" && $0.1 == "No"}))
    }

    func testArray() throws {
        struct Value: Encodable {
            struct Teacher: Encodable {
                let name: String
                let age: Int
            }
            let students: [String] = ["Jane", "John", "Sarah"]
            let teachers: [Teacher] = [
                Teacher(name: "Deforest", age: 45),
                Teacher(name: "Katherine", age: 37),
            ]
        }

        let value = Value()
        let encoder = FormEncoder()
        try value.encode(to: encoder)

        let rawValues = encoder.values.rawValues
        XCTAssertEqual(rawValues.count, 7)
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "students[]" && $0.1 == "Jane"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "students[]" && $0.1 == "John"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "students[]" && $0.1 == "Sarah"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "teachers[][name]" && $0.1 == "Deforest"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "teachers[][age]" && $0.1 == "45"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "teachers[][name]" && $0.1 == "Katherine"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "teachers[][age]" && $0.1 == "37"}))
    }
}
