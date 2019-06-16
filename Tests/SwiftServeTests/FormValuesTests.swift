//
//  FormValuesTests.swift
//  SwiftServeTests
//
//  Created by Andrew J Wagner on 6/9/19.
//

import XCTest
import Foundation
import Swiftlier
import SwiftServe

class FormValuesTests: XCTestCase {
    func testBasicDict() {
        var values = FormValues()
        self.add([
            ("key1", "value1"),
            ("key2", "value2"),
            ("key3", "value3"),
        ], to: &values)

        XCTAssertNil(values.string)
        XCTAssertTrue(values.array.isEmpty)
        XCTAssertEqual(values.keys.count, 3)
        XCTAssertEqual(values["key1"]?.string, "value1")
        XCTAssertEqual(values["key2"]?.string, "value2")
        XCTAssertEqual(values["key3"]?.string, "value3")

        let rawValues = values.rawValues
        XCTAssertEqual(rawValues.count, 3)
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "key1" && $0.1 == "value1"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "key2" && $0.1 == "value2"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "key3" && $0.1 == "value3"}))
    }

    func testBasicArray() {
        var values = FormValues()
        self.add([
            ("key[]", "value1"),
            ("key[]", "value2"),
            ("key[]", "value3"),
        ], to: &values)

        XCTAssertNil(values.string)
        XCTAssertEqual(values.array.count, 0)
        XCTAssertEqual(values.keys.count, 1)

        XCTAssertNil(values["key"]?.string)
        XCTAssertEqual(values["key"]?.keys.count, 0)
        XCTAssertEqual(values["key"]?.array.count, 3)
        XCTAssertEqual(values["key"]?.array[0].string, "value1")
        XCTAssertEqual(values["key"]?.array[1].string, "value2")
        XCTAssertEqual(values["key"]?.array[2].string, "value3")

        let rawValues = values.rawValues
        XCTAssertEqual(rawValues.count, 3)
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "key[]" && $0.1 == "value1"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "key[]" && $0.1 == "value2"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "key[]" && $0.1 == "value3"}))
    }

    func testValuesAndArray() {
        var values = FormValues()
        self.add([
            ("key1[]", "value1"),
            ("key1[]", "value2"),
            ("key2", "value3"),
            ("key3", "value4"),
        ], to: &values)

        XCTAssertNil(values.string)
        XCTAssertEqual(values.array.count, 0)
        XCTAssertEqual(values.keys.count, 3)

        XCTAssertNil(values["key1"]?.string)
        XCTAssertEqual(values["key1"]?.keys.count, 0)
        XCTAssertEqual(values["key1"]?.array.count, 2)
        XCTAssertEqual(values["key1"]?.array[0].string, "value1")
        XCTAssertEqual(values["key1"]?.array[1].string, "value2")

        XCTAssertEqual(values["key2"]?.string, "value3")
        XCTAssertEqual(values["key3"]?.string, "value4")

        let rawValues = values.rawValues
        XCTAssertEqual(rawValues.count, 4)
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "key1[]" && $0.1 == "value1"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "key1[]" && $0.1 == "value2"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "key2" && $0.1 == "value3"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "key3" && $0.1 == "value4"}))
    }

    func testArrayOfDictionaries() {
        var values = FormValues()
        self.add([
            ("key1[][sub1]", "value1"),
            ("key1[][sub2]", "value2"),
            ("key1[][sub1]", "value3"),
            ("key1[][sub2]", "value4"),
            ("key2", "value5"),
            ("key3", "value6"),
        ], to: &values)

        XCTAssertNil(values.string)
        XCTAssertEqual(values.array.count, 0)
        XCTAssertEqual(values.keys.count, 3)

        XCTAssertNil(values["key1"]?.string)
        XCTAssertEqual(values["key1"]?.keys.count, 0)
        XCTAssertEqual(values["key1"]?.array.count, 2)
        XCTAssertEqual(values["key1"]?.array[0]["sub1"]?.string, "value1")
        XCTAssertEqual(values["key1"]?.array[0]["sub2"]?.string, "value2")
        XCTAssertEqual(values["key1"]?.array[1]["sub1"]?.string, "value3")
        XCTAssertEqual(values["key1"]?.array[1]["sub2"]?.string, "value4")

        XCTAssertEqual(values["key2"]?.string, "value5")
        XCTAssertEqual(values["key3"]?.string, "value6")

        let rawValues = values.rawValues
        XCTAssertEqual(rawValues.count, 6)
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "key1[][sub1]" && $0.1 == "value1"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "key1[][sub2]" && $0.1 == "value2"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "key1[][sub1]" && $0.1 == "value3"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "key1[][sub2]" && $0.1 == "value4"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "key2" && $0.1 == "value5"}))
        XCTAssertTrue(rawValues.contains(where: {$0.0 == "key3" && $0.1 == "value6"}))
    }
}

extension FormValuesTests {
    func add(_ input: [(String, String)], to values: inout FormValues) {
        for (key, value) in input {
            values.add(key: key, value: value)
        }
    }
}
