# Swift NSDict Encoder
An encoder for serializing Swift objects to NSDictionaries. Created from the Swift standard library `PropertyListEncoder` by removing the binary conversion components and adding support for converting dates to strings using a custom `DateFormatter`.

## Usage
With dates as `NSDate` objects:

```swift
import Foundation

struct UserDetails {
  var name: String
  var birthDate: Date
}

let profile = UserDetails(name: "Frank", birthDay: Date())

let dictEncoder = NSDictionaryEncoder.init()
let profileDict: NSDictionary = try dictEncoder.encode(profile)
```
Dates as formatted strings:
```swift
// ...
let formatter = DateFormatter()
formatter.locale = Locale(identifier: "en_US")
formatter.dateFormat = "yyyy-MM-dd"
formatter.timeZone = TimeZone.current

let dictEncoder = NSDictionaryEncoder.init(dateFormatter: formatter)
let profileDict: NSDictionary = try dictEncoder.encode(profile)
```
