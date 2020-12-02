# Swift NSFoundation Coder

A package for encoding `Encodable` Swift objects into NSFoundation containers and decoding NSFoundation containers into `Decodable` Swift objects. 

The package is based on the Swift standard library `PropertyListEncoder`.

## Basic Usage

Encoding with default settings, i.e. dates as `NSDate`:
```swift
import NSFoundationCoder
import Foundation

struct Person: Codable {
    var name: String
    var birthDate: Date
}

let encoder = NSFoundationEncoder.init()
let person = Person(name: "John", birthDate: Date.init())

do {
    let personAsDict: NSDictionary = try encoder.encode(person)
} catch {
    print("Failed to encode")
}
```

Encoding with custom date formatter:
```swift
// ...

let formatter = DateFormatter()
formatter.locale = Locale(identifier: "en_US")
let encoder = NSFoundationEncoder.init(dateFormatter: formatter)

// ...
```

Decoding:
```swift
// ...

let decoder = NSFoundationDecoder.init()
let personAsDict: NSDictionary = [
    "name": "Jane",
    "birthDate": NSDate.init()
]

do {
    let person: Person = try decoder.decode(Person.self, from: personAsDict)
} catch {
    print("Failed to decode")
}
```
