import Swift
import Foundation
import XCTest
@testable import NSDictionaryEncoder

final class NSDictionaryEncoderTests: XCTestCase {
    // MARK: - Encoding Top-Level Empty Types
    func testEncodingTopLevelEmptyStruct() {
        let empty = EmptyStruct()
        _testRoundTrip(of: empty, expectedNSDict: _emptyNSDictionary)
    }

    func testEncodingTopLevelEmptyClass() {
        let empty = EmptyClass()
        _testRoundTrip(of: empty, expectedNSDict: _emptyNSDictionary)
    }

    // MARK: - Encoding Top-Level Single-Value Types
    func testEncodingTopLevelSingleValueEnum() {
        let s1 = Switch.off
        _testEncodeNSDictFailure(of: s1)
        _testRoundTrip(of: TopLevelWrapper(s1))

        let s2 = Switch.on
        _testEncodeNSDictFailure(of: s2)
        _testRoundTrip(of: TopLevelWrapper(s2))
    }

    func testEncodingTopLevelSingleValueStruct() {
        let t = Timestamp(3141592653)
        _testEncodeNSDictFailure(of: t)
        _testRoundTrip(of: TopLevelWrapper(t))
    }

    func testEncodingTopLevelSingleValueClass() {
        let c = Counter()
        _testEncodeNSDictFailure(of: c)
        _testRoundTrip(of: TopLevelWrapper(c))
    }

    // MARK: - Encoding Top-Level Structured Types
    func testEncodingTopLevelStructuredStruct() {
        // Address is a struct type with multiple fields.
        let address = Address.testValue
        _testRoundTrip(of: address)
    }

    func testEncodingTopLevelStructuredClass() {
        // Person is a class with multiple fields.
        let person = Person.testValue
        _testRoundTrip(of: person)
    }

    func testEncodingTopLevelStructuredSingleStruct() {
        // Numbers is a struct which encodes as an array through a single value container.
        let numbers = Numbers.testValue
        _testRoundTrip(of: numbers)
    }

    func testEncodingTopLevelStructuredSingleClass() {
        // Mapping is a class which encodes as a dictionary through a single value container.
        let mapping = Mapping.testValue
        _testRoundTrip(of: mapping)
    }

    func testEncodingTopLevelDeepStructuredType() {
        // Company is a type with fields which are Codable themselves.
        let company = Company.testValue
        _testRoundTrip(of: company)
    }

    func testEncodingClassWhichSharesEncoderWithSuper() {
        // Employee is a type which shares its encoder & decoder with its superclass, Person.
        let employee = Employee.testValue
        _testRoundTrip(of: employee)
    }

    func testEncodingTopLevelNullableType() {
        // EnhancedBool is a type which encodes either as a Bool or as nil.
        _testEncodeNSDictFailure(of: EnhancedBool.true)
        _testEncodeNSDictFailure(of: EnhancedBool.false)
        _testEncodeNSDictFailure(of: EnhancedBool.fileNotFound)

        _testRoundTrip(of: TopLevelWrapper(EnhancedBool.true))
        _testRoundTrip(of: TopLevelWrapper(EnhancedBool.false))
        _testRoundTrip(of: TopLevelWrapper(EnhancedBool.fileNotFound))
    }

    func testEncodingMultipleNestedContainersWithTheSameTopLevelKey() {
        struct Model : Codable, Equatable {
            let first: String
            let second: String

            init(from coder: Decoder) throws {
                let container = try coder.container(keyedBy: TopLevelCodingKeys.self)

                let firstNestedContainer = try container.nestedContainer(keyedBy: FirstNestedCodingKeys.self, forKey: .top)
                self.first = try firstNestedContainer.decode(String.self, forKey: .first)

                let secondNestedContainer = try container.nestedContainer(keyedBy: SecondNestedCodingKeys.self, forKey: .top)
                self.second = try secondNestedContainer.decode(String.self, forKey: .second)
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: TopLevelCodingKeys.self)

                var firstNestedContainer = container.nestedContainer(keyedBy: FirstNestedCodingKeys.self, forKey: .top)
                try firstNestedContainer.encode(self.first, forKey: .first)

                var secondNestedContainer = container.nestedContainer(keyedBy: SecondNestedCodingKeys.self, forKey: .top)
                try secondNestedContainer.encode(self.second, forKey: .second)
            }

            init(first: String, second: String) {
                self.first = first
                self.second = second
            }

            static var testValue: Model {
                return Model(first: "Johnny Appleseed",
                             second: "appleseed@apple.com")
            }
            enum TopLevelCodingKeys : String, CodingKey {
                case top
            }

            enum FirstNestedCodingKeys : String, CodingKey {
                case first
            }
            enum SecondNestedCodingKeys : String, CodingKey {
                case second
            }
        }

        let model = Model.testValue
        let expectedDict: NSDictionary = [
            "top": [
                "first": "Johnny Appleseed",
                "second": "appleseed@apple.com"
            ]
        ]
        _testRoundTrip(of: model, expectedNSDict: expectedDict)
    }

    // MARK: - Encoder Features
    func testNestedContainerCodingPaths() {
        var payload: Data! = nil
        let encoder = JSONEncoder()
        do {
            payload = try encoder.encode(NestedContainersTestType())
        } catch let error as NSError {
            XCTAssertNil(payload, "Caught error during encoding nested container types: \(error)")
        }
    }

    func testSuperEncoderCodingPaths() {
        var payload: Data! = nil
        let encoder = JSONEncoder()
        do {
            payload = try encoder.encode(NestedContainersTestType(testSuperEncoder: true))
        } catch let error as NSError {
            XCTAssertNil(payload, "Caught error during encoding nested container types: \(error)")
        }
    }

    func testInterceptData() {
        let data = try! JSONSerialization.data(withJSONObject: [], options: [])
        let topLevel = TopLevelWrapper(data)
        let dict: NSDictionary = ["value": data]
        _testRoundTrip(of: topLevel, expectedNSDict: dict)
    }

    func testInterceptDateEncodeAsDate() {
        let date = Date(timeIntervalSinceReferenceDate: 0)
        let topLevel = TopLevelWrapper(date)
        let dict: NSDictionary = ["value": date]
        _testRoundTrip(of: topLevel, expectedNSDict: dict)
    }

    func testInterceptDateEncodeAsString() {
        let date = Date(timeIntervalSinceReferenceDate: 0)
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.setLocalizedDateFormatFromTemplate("MMMMd")
        let encoder = NSDictionaryEncoder.init(dateFormatter: dateFormatter)
        let formattedDateString = dateFormatter.string(from: date)

        struct DateContainer: Codable {
            var date: Date
        }

        let dateContainer = DateContainer(date: date)
        var dict: NSDictionary? = nil
        do {
            dict = try encoder.encode(dateContainer)
        } catch {}

        XCTAssertEqual(dict, ["date": formattedDateString], "Date formatting failed")
    }

    // MARK: - Type coercion
    func testTypeCoercion() {
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [Int].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [Int8].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [Int16].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [Int32].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [Int64].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [UInt].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [UInt8].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [UInt16].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [UInt32].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [UInt64].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [Float].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [Double].self)
        _testRoundTripTypeCoercionFailure(of: [0, 1] as [Int], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0, 1] as [Int8], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0, 1] as [Int16], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0, 1] as [Int32], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0, 1] as [Int64], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0, 1] as [UInt], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0, 1] as [UInt8], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0, 1] as [UInt16], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0, 1] as [UInt32], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0, 1] as [UInt64], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0.0, 1.0] as [Float], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0.0, 1.0] as [Double], as: [Bool].self)
    }

    func testDecodingConcreteTypeParameter() {
        let encoder = PropertyListEncoder()
        guard let plist = try? encoder.encode(Employee.testValue) else {
            XCTFail("Unable to encode Employee.")
            return
        }

        let decoder = PropertyListDecoder()
        guard let decoded = try? decoder.decode(Employee.self as Person.Type, from: plist) else {
            XCTFail("Failed to decode Employee as Person from plist.")
            return
        }

        XCTAssertTrue(type(of: decoded) is Employee.Type, "Expected decoded value to be of type Employee; got \(type(of: decoded)) instead.")
    }

    // MARK: - Encoder State
    func testEncoderStateThrowOnEncode() {
        struct Wrapper<T : Encodable> : Encodable {
            let value: T
            init(_ value: T) { self.value = value }

            func encode(to encoder: Encoder) throws {
                // This approximates a subclass calling into its superclass, where the superclass encodes a value that might throw.
                // The key here is that getting the superEncoder creates a referencing encoder.
                var container = encoder.unkeyedContainer()
                let superEncoder = container.superEncoder()

                // Pushing a nested container on leaves the referencing encoder with multiple containers.
                var nestedContainer = superEncoder.unkeyedContainer()
                try nestedContainer.encode(value)
            }
        }

        struct Throwing : Encodable {
            func encode(to encoder: Encoder) throws {
                enum EncodingError : Error { case foo }
                throw EncodingError.foo
            }
        }

        // The structure that would be encoded here looks like
        //
        //   <array>
        //     <array>
        //       <array>
        //         [throwing]
        //       </array>
        //     </array>
        //   </array>
        //
        // The wrapper asks for an unkeyed container ([^]), gets a super encoder, and creates a nested container into that ([[^]]).
        // We then encode an array into that ([[[^]]]), which happens to be a value that causes us to throw an error.
        //
        // The issue at hand reproduces when you have a referencing encoder (superEncoder() creates one) that has a container on the stack (unkeyedContainer() adds one) that encodes a value going through box_() (Array does that) that encodes something which throws (Throwing does that).
        // When reproducing, this will cause a test failure via fatalError().
        let _: NSObject? = try? NSDictionaryEncoder().encode(Wrapper([Throwing()]))
    }

    // MARK: - Decoder State
    func testDecoderStateThrowOnDecode() {
        let array: NSArray = try! NSDictionaryEncoder().encode([1,2,3])
        let _ = try! NSDictionaryDecoder().decode(EitherDecodable<[String], [Int]>.self, from: array)
    }

    static var allTests = [
        ("testEncodingTopLevelEmptyStruct", testEncodingTopLevelEmptyStruct,
         "testEncodingTopLevelEmptyClass", testEncodingTopLevelEmptyClass,
         "testEncodingTopLevelSingleValueEnum", testEncodingTopLevelSingleValueEnum,
         "testEncodingTopLevelSingleValueStruct", testEncodingTopLevelSingleValueStruct,
         "testEncodingTopLevelSingleValueClass", testEncodingTopLevelSingleValueClass,
         "testEncodingTopLevelStructuredStruct", testEncodingTopLevelStructuredStruct,
         "testEncodingTopLevelStructuredClass", testEncodingTopLevelStructuredClass,
         "testEncodingTopLevelStructuredSingleStruct", testEncodingTopLevelStructuredSingleStruct,
         "testEncodingTopLevelStructuredSingleClass", testEncodingTopLevelStructuredSingleClass,
         "testEncodingTopLevelDeepStructuredType", testEncodingTopLevelDeepStructuredType,
         "testEncodingClassWhichSharesEncoderWithSuper", testEncodingClassWhichSharesEncoderWithSuper,
         "testEncodingTopLevelNullableType", testEncodingTopLevelNullableType,
         "testEncodingMultipleNestedContainersWithTheSameTopLevelKey", testEncodingMultipleNestedContainersWithTheSameTopLevelKey,
         "testNestedContainerCodingPaths", testNestedContainerCodingPaths,
         "testSuperEncoderCodingPaths", testSuperEncoderCodingPaths,
         "testInterceptData", testInterceptData,
         "testInterceptDateEncodeAsDate", testInterceptDateEncodeAsDate,
         "testInterceptDateEncodeAsString", testInterceptDateEncodeAsString,
         "testTypeCoercion", testTypeCoercion,
         "testDecodingConcreteTypeParameter", testDecodingConcreteTypeParameter,
         "testEncoderStateThrowOnEncode", testEncoderStateThrowOnEncode,
         "testDecoderStateThrowOnDecode", testDecoderStateThrowOnDecode
        ),
    ]
}

// MARK: - Helper Functions
private func _testRoundTrip<T>(of value: T, expectedNSDict dict: NSObject? = nil) where T : Codable, T : Equatable {
    var payload: NSObject! = nil
    do {
        let encoder = NSDictionaryEncoder()
        payload = try encoder.encode(value)
    } catch {
        XCTFail("Failed to encode \(T.self) to NSObject: \(error)")
    }

    if let expectedNSDict = dict {
        XCTAssertEqual(expectedNSDict, payload, "Produced NSObject not identical to expected NSObject.")
    }

    do {
        let decoded = try NSDictionaryDecoder().decode(T.self, from: payload)
        XCTAssertEqual(decoded, value, "\(T.self) did not round-trip to an equal value.")
    } catch {
        XCTFail("Failed to decode \(T.self) from NSObject: \(error)")
    }
}

private func _testRoundTripTypeCoercionFailure<T,U>(of value: T, as type: U.Type) where T : Codable, U : Codable {
    do {
        let data = try PropertyListEncoder().encode(value)
        let _ = try PropertyListDecoder().decode(U.self, from: data)
        XCTFail("Coercion from \(T.self) to \(U.self) was expected to fail.")
    } catch {}
}

private func _testEncodeNSDictFailure<T : Encodable>(of value: T) {
    do {
        let encoder = NSDictionaryEncoder()
        let _: NSDictionary = try encoder.encode(value)
        XCTFail("Encode of top-level \(T.self) was expected to fail.")
    } catch {}
}

func assertEqualPaths(_ lhs: [CodingKey], _ rhs: [CodingKey], _ prefix: String) {
    if lhs.count != rhs.count {
        XCTFail("\(prefix) [CodingKey].count mismatch: \(lhs.count) != \(rhs.count)")
        return
    }

    for (key1, key2) in zip(lhs, rhs) {
        switch (key1.intValue, key2.intValue) {
        case (.none, .none): break
        case (.some(let i1), .none):
            XCTFail("\(prefix) CodingKey.intValue mismatch: \(type(of: key1))(\(i1)) != nil")
            return
        case (.none, .some(let i2)):
            XCTFail("\(prefix) CodingKey.intValue mismatch: nil != \(type(of: key2))(\(i2))")
            return
        case (.some(let i1), .some(let i2)):
            guard i1 == i2 else {
                XCTFail("\(prefix) CodingKey.intValue mismatch: \(type(of: key1))(\(i1)) != \(type(of: key2))(\(i2))")
                return
            }
        }

        XCTAssertEqual(key1.stringValue, key2.stringValue, "\(prefix) CodingKey.stringValue mismatch: \(type(of: key1))('\(key1.stringValue)') != \(type(of: key2))('\(key2.stringValue)')")
    }
}

fileprivate let _emptyNSDictionary: NSDictionary = [:]

// MARK: - Helper Types
/// Wraps a type T so that it can be encoded at the top level of a payload.
fileprivate struct TopLevelWrapper<T> : Codable, Equatable where T : Codable, T : Equatable {
    let value: T

    init(_ value: T) {
        self.value = value
    }

    static func ==(_ lhs: TopLevelWrapper<T>, _ rhs: TopLevelWrapper<T>) -> Bool {
        return lhs.value == rhs.value
    }
}

/// A key type which can take on any string or integer value.
/// This needs to mirror _NSDictKey.
fileprivate struct _TestKey : CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }
}

fileprivate enum EitherDecodable<T : Decodable, U : Decodable> : Decodable {
    case t(T)
    case u(U)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let t = try? container.decode(T.self) {
            self = .t(t)
        } else if let u = try? container.decode(U.self) {
            self = .u(u)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Data was neither \(T.self) nor \(U.self).")
        }
    }
}

// MARK: - Test Types

// MARK: - Empty Types
fileprivate struct EmptyStruct : Codable, Equatable {
    static func ==(_ lhs: EmptyStruct, _ rhs: EmptyStruct) -> Bool {
        return true
    }
}

fileprivate class EmptyClass : Codable, Equatable {
    static func ==(_ lhs: EmptyClass, _ rhs: EmptyClass) -> Bool {
        return true
    }
}

// MARK: - Single-Value Types
/// A simple on-off switch type that encodes as a single Bool value.
fileprivate enum Switch : Codable {
    case off
    case on

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        switch try container.decode(Bool.self) {
        case false: self = .off
        case true:  self = .on
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .off: try container.encode(false)
        case .on:  try container.encode(true)
        }
    }
}

/// A simple timestamp type that encodes as a single Double value.
fileprivate struct Timestamp : Codable, Equatable {
    let value: Double

    init(_ value: Double) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(Double.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.value)
    }

    static func ==(_ lhs: Timestamp, _ rhs: Timestamp) -> Bool {
        return lhs.value == rhs.value
    }
}

/// A simple referential counter type that encodes as a single Int value.
fileprivate final class Counter : Codable, Equatable {
    var count: Int = 0

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        count = try container.decode(Int.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.count)
    }

    static func ==(_ lhs: Counter, _ rhs: Counter) -> Bool {
        return lhs === rhs || lhs.count == rhs.count
    }
}

// MARK: - Structured Types
/// A simple address type that encodes as a dictionary of values.
fileprivate struct Address : Codable, Equatable {
    let street: String
    let city: String
    let state: String
    let zipCode: Int
    let country: String

    init(street: String, city: String, state: String, zipCode: Int, country: String) {
        self.street = street
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
    }

    static func ==(_ lhs: Address, _ rhs: Address) -> Bool {
        return lhs.street == rhs.street &&
            lhs.city == rhs.city &&
            lhs.state == rhs.state &&
            lhs.zipCode == rhs.zipCode &&
            lhs.country == rhs.country
    }

    static var testValue: Address {
        return Address(street: "1 Infinite Loop",
                       city: "Cupertino",
                       state: "CA",
                       zipCode: 95014,
                       country: "United States")
    }
}

/// A simple person class that encodes as a dictionary of values.
fileprivate class Person : Codable, Equatable {
    let name: String
    let email: String
    let website: URL?

    init(name: String, email: String, website: URL? = nil) {
        self.name = name
        self.email = email
        self.website = website
    }

    func isEqual(_ other: Person) -> Bool {
        return self.name == other.name &&
            self.email == other.email &&
            self.website == other.website
    }

    static func ==(_ lhs: Person, _ rhs: Person) -> Bool {
        return lhs.isEqual(rhs)
    }

    class var testValue: Person {
        return Person(name: "Johnny Appleseed", email: "appleseed@apple.com")
    }
}

/// A class which shares its encoder and decoder with its superclass.
fileprivate class Employee : Person {
    let id: Int

    init(name: String, email: String, website: URL? = nil, id: Int) {
        self.id = id
        super.init(name: name, email: email, website: website)
    }

    enum CodingKeys : String, CodingKey {
        case id
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        try super.init(from: decoder)
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try super.encode(to: encoder)
    }

    override func isEqual(_ other: Person) -> Bool {
        if let employee = other as? Employee {
            guard self.id == employee.id else { return false }
        }

        return super.isEqual(other)
    }

    override class var testValue: Employee {
        return Employee(name: "Johnny Appleseed", email: "appleseed@apple.com", id: 42)
    }
}

/// A simple company struct which encodes as a dictionary of nested values.
fileprivate struct Company : Codable, Equatable {
    let address: Address
    var employees: [Employee]

    init(address: Address, employees: [Employee]) {
        self.address = address
        self.employees = employees
    }

    static func ==(_ lhs: Company, _ rhs: Company) -> Bool {
        return lhs.address == rhs.address && lhs.employees == rhs.employees
    }

    static var testValue: Company {
        return Company(address: Address.testValue, employees: [Employee.testValue])
    }
}

/// An enum type which decodes from Bool?.
fileprivate enum EnhancedBool : Codable {
    case `true`
    case `false`
    case fileNotFound

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .fileNotFound
        } else {
            let value = try container.decode(Bool.self)
            self = value ? .true : .false
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .true: try container.encode(true)
        case .false: try container.encode(false)
        case .fileNotFound: try container.encodeNil()
        }
    }
}

/// A type which encodes as an array directly through a single value container.
struct Numbers : Codable, Equatable {
    let values = [4, 8, 15, 16, 23, 42]

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodedValues = try container.decode([Int].self)
        guard decodedValues == values else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "The Numbers are wrong!"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }

    static func ==(_ lhs: Numbers, _ rhs: Numbers) -> Bool {
        return lhs.values == rhs.values
    }

    static var testValue: Numbers {
        return Numbers()
    }
}

/// A type which encodes as a dictionary directly through a single value container.
fileprivate final class Mapping : Codable, Equatable {
    let values: [String : URL]

    init(values: [String : URL]) {
        self.values = values
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        values = try container.decode([String : URL].self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }

    static func ==(_ lhs: Mapping, _ rhs: Mapping) -> Bool {
        return lhs === rhs || lhs.values == rhs.values
    }

    static var testValue: Mapping {
        return Mapping(values: ["Example": URL(string: "http://example.com")!,
                                "localhost": URL(string: "http://127.0.0.1")!])
    }
}

struct NestedContainersTestType : Encodable {
    let testSuperEncoder: Bool

    init(testSuperEncoder: Bool = false) {
        self.testSuperEncoder = testSuperEncoder
    }

    enum TopLevelCodingKeys : Int, CodingKey {
        case a
        case b
        case c
    }

    enum IntermediateCodingKeys : Int, CodingKey {
        case one
        case two
    }

    func encode(to encoder: Encoder) throws {
        if self.testSuperEncoder {
            var topLevelContainer = encoder.container(keyedBy: TopLevelCodingKeys.self)
            assertEqualPaths(encoder.codingPath, [], "Top-level Encoder's codingPath changed.")
            assertEqualPaths(topLevelContainer.codingPath, [], "New first-level keyed container has non-empty codingPath.")

            let superEncoder = topLevelContainer.superEncoder(forKey: .a)
            assertEqualPaths(encoder.codingPath, [], "Top-level Encoder's codingPath changed.")
            assertEqualPaths(topLevelContainer.codingPath, [], "First-level keyed container's codingPath changed.")
            assertEqualPaths(superEncoder.codingPath, [TopLevelCodingKeys.a], "New superEncoder had unexpected codingPath.")
            _testNestedContainers(in: superEncoder, baseCodingPath: [TopLevelCodingKeys.a])
        } else {
            _testNestedContainers(in: encoder, baseCodingPath: [])
        }
    }

    func _testNestedContainers(in encoder: Encoder, baseCodingPath: [CodingKey]) {
        assertEqualPaths(encoder.codingPath, baseCodingPath, "New encoder has non-empty codingPath.")

        // codingPath should not change upon fetching a non-nested container.
        var firstLevelContainer = encoder.container(keyedBy: TopLevelCodingKeys.self)
        assertEqualPaths(encoder.codingPath, baseCodingPath, "Top-level Encoder's codingPath changed.")
        assertEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "New first-level keyed container has non-empty codingPath.")

        // Nested Keyed Container
        do {
            // Nested container for key should have a new key pushed on.
            var secondLevelContainer = firstLevelContainer.nestedContainer(keyedBy: IntermediateCodingKeys.self, forKey: .a)
            assertEqualPaths(encoder.codingPath, baseCodingPath, "Top-level Encoder's codingPath changed.")
            assertEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "First-level keyed container's codingPath changed.")
            assertEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.a], "New second-level keyed container had unexpected codingPath.")

            // Inserting a keyed container should not change existing coding paths.
            let thirdLevelContainerKeyed = secondLevelContainer.nestedContainer(keyedBy: IntermediateCodingKeys.self, forKey: .one)
            assertEqualPaths(encoder.codingPath, baseCodingPath, "Top-level Encoder's codingPath changed.")
            assertEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "First-level keyed container's codingPath changed.")
            assertEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.a], "Second-level keyed container's codingPath changed.")
            assertEqualPaths(thirdLevelContainerKeyed.codingPath, baseCodingPath + [TopLevelCodingKeys.a, IntermediateCodingKeys.one], "New third-level keyed container had unexpected codingPath.")

            // Inserting an unkeyed container should not change existing coding paths.
            let thirdLevelContainerUnkeyed = secondLevelContainer.nestedUnkeyedContainer(forKey: .two)
            assertEqualPaths(encoder.codingPath, baseCodingPath + [], "Top-level Encoder's codingPath changed.")
            assertEqualPaths(firstLevelContainer.codingPath, baseCodingPath + [], "First-level keyed container's codingPath changed.")
            assertEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.a], "Second-level keyed container's codingPath changed.")
            assertEqualPaths(thirdLevelContainerUnkeyed.codingPath, baseCodingPath + [TopLevelCodingKeys.a, IntermediateCodingKeys.two], "New third-level unkeyed container had unexpected codingPath.")
        }

        // Nested Unkeyed Container
        do {
            // Nested container for key should have a new key pushed on.
            var secondLevelContainer = firstLevelContainer.nestedUnkeyedContainer(forKey: .b)
            assertEqualPaths(encoder.codingPath, baseCodingPath, "Top-level Encoder's codingPath changed.")
            assertEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "First-level keyed container's codingPath changed.")
            assertEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.b], "New second-level keyed container had unexpected codingPath.")

            // Appending a keyed container should not change existing coding paths.
            let thirdLevelContainerKeyed = secondLevelContainer.nestedContainer(keyedBy: IntermediateCodingKeys.self)
            assertEqualPaths(encoder.codingPath, baseCodingPath, "Top-level Encoder's codingPath changed.")
            assertEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "First-level keyed container's codingPath changed.")
            assertEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.b], "Second-level unkeyed container's codingPath changed.")
            assertEqualPaths(thirdLevelContainerKeyed.codingPath, baseCodingPath + [TopLevelCodingKeys.b, _TestKey(index: 0)], "New third-level keyed container had unexpected codingPath.")

            // Appending an unkeyed container should not change existing coding paths.
            let thirdLevelContainerUnkeyed = secondLevelContainer.nestedUnkeyedContainer()
            assertEqualPaths(encoder.codingPath, baseCodingPath, "Top-level Encoder's codingPath changed.")
            assertEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "First-level keyed container's codingPath changed.")
            assertEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.b], "Second-level unkeyed container's codingPath changed.")
            assertEqualPaths(thirdLevelContainerUnkeyed.codingPath, baseCodingPath + [TopLevelCodingKeys.b, _TestKey(index: 1)], "New third-level unkeyed container had unexpected codingPath.")
        }
    }
}
