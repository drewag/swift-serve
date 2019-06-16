//
//  RequestDecodeFromFormTests.swift
//  SwiftServeTests
//
//  Created by Andrew J Wagner on 6/9/19.
//

import XCTest
import Swiftlier
@testable import SwiftServe

class RequestDecodableFromFormTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DatabaseSetup = DatabaseSpec(name: "db", username: "user", password: "password")
    }

    func testGetReturnsnil() throws {
        let request = self.createRequest(withPostData: nil)
        struct Value: Decodable { let key: String }
        let value: Value? = try request.decodableFromForm()
        XCTAssertNil(value)
    }

    func testValidBasicForm() throws {
        let date = Date.now
        let request = self.createRequest(withPostData: [
            ("string", "some string"),
            ("int", "1"),
            ("float", "2.3"),
            ("double", "4.5"),
            ("date", date.iso8601DateTime),
            ("yes", "Yes"),
            ("no", "No"),
            ("email", "user@example.com"),
        ])

        struct Value: Decodable {
            let string: String
            let int: Int
            let float: Float
            let double: Double
            let date: Date
            let yes: Bool
            let no: Bool
            let email: EmailAddress
        }

        let value: Value? = try request.decodableFromForm()
        XCTAssertNotNil(value)
        if let value = value {
            XCTAssertEqual(value.string, "some string")
            XCTAssertEqual(value.int, 1)
            XCTAssertEqual(value.float, 2.3)
            XCTAssertEqual(value.double, 4.5)
            XCTAssertEqual(value.date.iso8601DateTime, date.iso8601DateTime)
            XCTAssertTrue(value.yes)
            XCTAssertFalse(value.no)
            XCTAssertEqual(value.email.string, "user@example.com")
        }
    }

    func testMissingValue() throws {
        let request = self.createRequest(withPostData: [("string", "some string")])

        struct Value: Decodable {
            let string: String
            let missing: String
        }

        do {
            let _: Value? = try request.decodableFromForm()
            XCTFail("Should not succeed")
        }
        catch {
            XCTAssertEqual(error.localizedDescription, "missing is required")
        }
    }

    func testEmptyValue() throws {
        let request = self.createRequest(withPostData: [("empty", "")])

        struct Value: Decodable {
            let empty: String
        }

        do {
            let _: Value? = try request.decodableFromForm()
            XCTFail("Should not succeed")
        }
        catch {
            XCTAssertEqual(error.localizedDescription, "empty is required")
        }
    }

    func testInvalidInteger() {
        let request = self.createRequest(withPostData: [("int", "1.2")])

        struct Value: Decodable {
            let int: Int
        }

        do {
            let _: Value? = try request.decodableFromForm()
            XCTFail("Should not succeed")
        }
        catch {
            XCTAssertEqual(error.localizedDescription, "int is invalid. It must be an integer.")
        }
    }

    func testInvalidEmail() {
        let request = self.createRequest(withPostData: [("email", "asdfasdf")])

        struct Value: Decodable {
            let email: EmailAddress
        }

        do {
            let _: Value? = try request.decodableFromForm()
            XCTFail("Should not succeed")
        }
        catch {
            XCTAssertEqual(error.localizedDescription, "'asdfasdf' is not a valid email")
        }
    }

    func testOptional() throws {
        let request = self.createRequest(withPostData: [("string1", "some string")])

        struct Value: Decodable {
            let string1: String?
            let string2: String?
        }

        let value: Value? = try request.decodableFromForm()
        XCTAssertNotNil(value)
        if let value = value {
            XCTAssertEqual(value.string1, "some string")
            XCTAssertNil(value.string2)
        }
    }

    func testOptionalInvalid() throws {
        let request = self.createRequest(withPostData: [("int", "1.2")])

        struct Value: Decodable {
            let int: Int?
        }

        do {
            let _: Value? = try request.decodableFromForm()
            XCTFail("Should not succeed")
        }
        catch {
            XCTAssertEqual(error.localizedDescription, "int is invalid. It must be an integer.")
        }
    }


    func testNested() throws {
        let date = Date.now
        let request = self.createRequest(withPostData: [
            ("student[name]", "Jane"),
            ("student[age]", "22"),
            ("student[gpa]", "3.7"),
            ("teacher[performance]", "4.5"),
            ("teacher[hired]", date.iso8601DateTime),
            ("student[passing]", "Yes"),
            ("teacher[temp]", "No"),
        ])

        struct Value: Decodable {
            struct Student: Decodable {
                let name: String
                let age: Int
                let gpa: Float
                let passing: Bool
            }
            struct Teacher: Decodable {
                let performance: Double
                let hired: Date
                let temp: Bool
            }
            let student: Student
            let teacher: Teacher
        }

        let value: Value? = try request.decodableFromForm()
        XCTAssertNotNil(value)
        if let value = value {
            XCTAssertEqual(value.student.name, "Jane")
            XCTAssertEqual(value.student.age, 22)
            XCTAssertEqual(value.student.gpa, 3.7)
            XCTAssertEqual(value.teacher.performance, 4.5)
            XCTAssertEqual(value.teacher.hired.iso8601DateTime, date.iso8601DateTime)
            XCTAssertTrue(value.student.passing)
            XCTAssertFalse(value.teacher.temp)
        }
    }

    func testArray() throws {
        let request = self.createRequest(withPostData: [
            ("students[]", "Jane"),
            ("students[]", "John"),
            ("students[]", "Sarah"),
            ("teachers[][name]", "Deforest"),
            ("teachers[][age]", "45"),
            ("teachers[][name]", "Katherine"),
            ("teachers[][age]", "37"),
        ])

        struct Value: Decodable {
            struct Teacher: Decodable {
                let name: String
                let age: Int
            }
            let students: [String]
            let teachers: [Teacher]
        }

        let value: Value? = try request.decodableFromForm()
        XCTAssertNotNil(value)
        if let value = value {
            XCTAssertEqual(value.students.count, 3)
            if value.students.count == 3 {
                XCTAssertEqual(value.students[0], "Jane")
                XCTAssertEqual(value.students[1], "John")
                XCTAssertEqual(value.students[2], "Sarah")
            }
            XCTAssertEqual(value.teachers.count, 2)
            if value.teachers.count == 2 {
                XCTAssertEqual(value.teachers[0].name, "Deforest")
                XCTAssertEqual(value.teachers[0].age, 45)
                XCTAssertEqual(value.teachers[1].name, "Katherine")
                XCTAssertEqual(value.teachers[1].age, 37)
            }
        }
    }
}

extension RequestDecodableFromFormTests {
    func createRequest(withPostData postData: [(String,String)]?) -> TestRequest {
        let url = URL(string: "http://example.com")!
        if let postData = postData {
            let raw = FormUrlEncoded.encode(postData)
            print(raw)
            let data = raw.data(using: .utf8)!
            return TestRequest(method: .post, endpoint: url, data: data)
        }
        else {
            return TestRequest(method: .get, endpoint: url, data: Data())
        }
    }
}
