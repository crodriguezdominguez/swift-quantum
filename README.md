# Swift Quantum

A Swift package to support quantum computing simulations and experiments. Some of its most relevant characteristics are:

- Simple, Swift-based API.
- High performance efficiency, based on sparse arrays to decrease memory use.
- Flexibility: It is possible to define custom quantum circuits and gates, which can be composed to create complex circuits or gates.
- I/O support: Circuits can be de/serialized from/to JSON documents.

Swift Quantum modules have minimal dependencies on other projects, except for [Swift Numerics] (https://github.com/apple/swift-numerics).

The current module assumes only the availability of the Swift and C standard libraries and the runtime support provided by compiler-rt.

Use examples are available at `Tests/SwiftQuantumTests`.

## Using Swift Quantum in your project

To use Swift Numerics in a SwiftPM project:

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
