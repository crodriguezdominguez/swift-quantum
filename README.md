# Swift Quantum

[![Swift Package Manager compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fcrodriguezdominguez%2Fswift-quantum%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/crodriguezdominguez/swift-quantum)

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fcrodriguezdominguez%2Fswift-quantum%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/crodriguezdominguez/swift-quantum)

A Swift package to support quantum computing simulations and experiments. Some of its most relevant characteristics are:

- Simple, Swift-based API.
- High performance efficiency, based on sparse arrays to decrease memory use.
- Flexibility: It is possible to define custom quantum circuits and gates, which can be composed to create complex circuits or gates.
- I/O support: Circuits can be de/serialized from/to JSON documents.

Swift Quantum module has minimal dependencies on other projects, except for [Swift Numerics](https://github.com/apple/swift-numerics).

Several use examples are available at `Tests/SwiftQuantumTests`.

## Using Swift Quantum in your project

To use Swift Quantum in a SwiftPM project:

1. Add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/crodriguezdominguez/swift-quantum", from: "1.0.0"),
```

2. Add `SwiftQuantum` as a dependency for your target:

```swift
.target(name: "MyTarget", dependencies: [
  .product(name: "SwiftQuantum", package: "swift-quantum"),
  "AnotherModule"
]),
```

3. Add `import SwiftQuantum` in your source code.

## Source stability

The Swift Quantum package is source stable; version numbers follow [Semantic Versioning](https://semver.org).
