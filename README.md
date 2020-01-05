# UIViewBuilder

Alternative SwiftUI using pure UIKit. Support from iOS9.
This is WIP project. All API isn't fixed.

Let's try these functions in Example app.
```swift
HostingController {
  VStack {
    if isHello {
      Label(text: "hello")
    } else {
      Label(text: "good night")
    }
    Label(text: "world")
  }
}

HostingController {
  List {
    ForEach(data: [0..<1000]) {
      Label(text: "\($0)")
    }
  }
}
```
