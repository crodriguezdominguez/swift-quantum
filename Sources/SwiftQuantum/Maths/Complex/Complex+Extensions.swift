//
//  Complex+Extensions.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 13/7/24.
//  Copyright © 2024 Everyware Technologies. All rights reserved.
//

#if !os(Linux) && !os(Windows)
    import Darwin
    import CoreGraphics
#endif

import Foundation
import ComplexModule
import RealModule

public extension Double {
    var i:Complex<Double> { return Complex(0.0, self) }
}

public extension Complex {
    init(t:(RealType, RealType)) {
        self.init(t.0, t.1)
    }
    
    init(abs: RealType, arg: RealType) {
        self.init(abs * RealType.cos(arg), abs * RealType.sin(arg))
    }
    
    var im:RealType { get{ imaginary } set(i){ imaginary = i } }
    var re:RealType { get{ real } set(r){ real = r } }
    
    /// `self * i`
    var i:Complex { return Complex(-imaginary, real) }
    
    var norm:RealType { return self.lengthSquared }
    
    /// (re:real, im:imag)
    var tuple:(RealType, RealType) {
        get{ return (real, imaginary) }
        set(t){ (real, imaginary) = t }
    }
    
    /// absolute value of self in T:RealType
    var abs: RealType {
        get { return self.length }
        set(r){ let f = r / abs; re = re * f; im = im * f }
    }
    
    /// argument of self in T:RealType
    var arg: RealType  {
        get { return self.phase }
        set(t) {
            let m = abs
            real = m * RealType.cos(t)
            imaginary = m * RealType.sin(t)
        }
    }
}

public extension Complex where RealType == Double {
    var arithmeticDescription:String {
        let absIm = Swift.abs(imaginary)
        let absRe = Swift.abs(real)
        
        if absIm =~ 0.0 {
            return "\(real)"
        }
        
        if absRe =~ 0.0 {
            return "\(imaginary)i"
        }
        
        let sig = imaginary < 0 ? "-" : "+"
        return "\(real)\(sig)\(absIm)i"
    }
}

/// real part of z
public func real<T: Real>(_ z:Complex<T>) -> T { return z.real }
/// imaginary part of z
public func imag<T: Real>(_ z:Complex<T>) -> T { return z.imaginary }
/// norm of z
public func norm(_ z:Complex<Double>) -> Double { return z.norm }
/// conjugate of z
public func conj<T: Real>(_ z:Complex<T>) -> Complex<T> { return z.conjugate }

// Double is default since floating-point literals are Double by default
extension Double {
    public static let EPSILON = 0x1p-52
}

extension Complex : ExpressibleByFloatLiteral where RealType == Double {
    public init(floatLiteral value: FloatLiteralType) {
        self.init(value)
    }
}

/// absolute value of z
public func abs(_ z:Complex<Double>) -> Double { return z.abs }
/// argument of z
public func arg(_ z:Complex<Double>) -> Double { return z.arg }

public func +<T: Real>(lhs:Complex<T>, rhs:T) -> Complex<T> {
    return lhs + Complex(rhs)
}
public func +<T: Real>(lhs:T, rhs:Complex<T>) -> Complex<T> {
    return Complex(lhs) + rhs
}

public func +=(lhs:inout Complex<Double>, rhs:Double) {
    lhs.re = lhs.re + rhs
}

public prefix func -(z:Complex<Double>) -> Complex<Double> {
    return Complex(-z.re, -z.im)
}

public func -<T: Real>(lhs:Complex<T>, rhs:T) -> Complex<T> {
    return lhs - Complex(rhs)
}
public func -<T: Real>(lhs:T, rhs:Complex<T>) -> Complex<T> {
    return Complex(lhs) - rhs
}

public func -=(lhs:inout Complex<Double>, rhs:Double) {
    lhs.re = lhs.re + rhs
}
// *
public func *<T: Real>(lhs:Complex<T>, rhs:T) -> Complex<T> {
    return Complex(lhs.real * rhs, lhs.imaginary * rhs)
}
public func *<T: Real>(lhs:T, rhs:Complex<T>) -> Complex<T> {
    return Complex(lhs * rhs.real, lhs * rhs.imaginary)
}
public func *=<T: Real>(lhs:inout Complex<T>, rhs:T) {
    lhs = lhs * rhs
}

public func /(lhs:Complex<Double>, rhs:Double) -> Complex<Double> {
    return Complex(lhs.re / rhs, lhs.im / rhs)
}
public func /<T: Real>(lhs:T, rhs:Complex<T>) -> Complex<T> {
    return Complex(lhs) / rhs
}
public func /=(lhs:inout Complex<Double>, rhs:Double) {
    lhs = lhs / rhs
}

/// - returns: lhs ** rhs in Complex
public func pow<T: Real>(_ lhs:Complex<T>, _ rhs:Int) -> Complex<T> {
    return Complex.pow(lhs, Complex(rhs))
}
/// - returns: lhs ** rhs in Complex
public func pow<T: Real>(_ lhs:Complex<T>, _ rhs:T) -> Complex<T> {
    return Complex.pow(lhs, Complex(rhs))
}
/// - returns: lhs ** rhs in Complex
public func pow<T: Real>(_ lhs:T, _ rhs:Complex<T>) -> Complex<T> {
    return Complex.pow(Complex(lhs), rhs)
}


/// CGFloat if !os(Linux)
#if !os(Linux) && !os(Windows)
extension Complex where RealType == Double {
    /// - paramater p: CGPoint
    /// - returns: `Complex<CGFloat>`
    public init(_ p:CGPoint) {
        self.init(Double(p.x), Double(p.y))
    }
    public var asCGPoint:CGPoint {
        return CGPoint(x:CGFloat(re), y:CGFloat(im))
    }
}
#endif

/// % is defined only for Complex
public func %<T: Real>(lhs:Complex<T>, rhs:Complex<T>) -> Complex<T> {
    return lhs - (lhs / rhs) * rhs
}
public func %(lhs:Complex<Double>, rhs:Double) -> Complex<Double> {
    return lhs - (lhs / rhs) * rhs
}
public func %<T: Real>(lhs:T, rhs:Complex<T>) -> Complex<T> {
    return Complex(lhs) % rhs
}
public func %=<T: Real>(lhs:inout Complex<T>, rhs:Complex<T>) {
    lhs = lhs % rhs
}
public func %=(lhs:inout Complex<Double>, rhs:Double) {
    lhs = lhs % rhs
}

// **, **= // pow(lhs, rhs)
precedencegroup PowPrecedence {
    associativity: right
    higherThan: MultiplicationPrecedence
}
infix operator ** : PowPrecedence

precedencegroup PowAssignmentPrecedence {
    associativity: right
    higherThan: AssignmentPrecedence
}

infix operator **= : PowAssignmentPrecedence
public func **(lhs:Double, rhs:Double) -> Double {
    return Double.pow(lhs, rhs)
}
public func **<T: Real>(lhs:Complex<T>, rhs:Complex<T>) -> Complex<T> {
    return Complex.pow(lhs, rhs)
}
public func **<T: Real>(lhs:T, rhs:Complex<T>) -> Complex<T> {
    return pow(lhs, rhs)
}
public func **<T: Real>(lhs:Complex<T>, rhs:T) -> Complex<T> {
    return pow(lhs, rhs)
}
public func **=<T: Real>(lhs:inout T, rhs:T) {
    lhs = Complex.pow(Complex(lhs), Complex(rhs)).real
}
public func **=<T: Real>(lhs:inout Complex<T>, rhs:Complex<T>) {
    lhs = Complex.pow(lhs, rhs)
}
public func **=<T: Real>(lhs:inout Complex<T>, rhs:T) {
    lhs = pow(lhs, rhs)
}

precedencegroup SimilarityPrecedence {
    associativity: none
    higherThan: LogicalConjunctionPrecedence
}

// =~ // approximate comparisons
infix operator =~ : SimilarityPrecedence

public func =~(lhs:Double, rhs:Double) -> Bool {
    if lhs == rhs { return true }
    // if either side is zero, simply compare to epsilon
    if rhs == 0 { return abs(lhs) < Double.EPSILON }
    if lhs == 0 { return abs(rhs) < Double.EPSILON }
    // sign must match
    if (lhs.sign == .minus) != (rhs.sign == .minus) { return false }
    // delta / average < epsilon
    let num = lhs - rhs
    let den = lhs + rhs
    return abs(num/den) < 2.0*Double.EPSILON
}
public func =~(lhs:Complex<Double>, rhs:Complex<Double>) -> Bool {
    return lhs.abs =~ rhs.abs
}
public func =~(lhs:Complex<Double>, rhs:Double) -> Bool {
    return lhs.abs =~ abs(rhs)
}
public func =~(lhs:Double, rhs:Complex<Double>) -> Bool {
    return abs(lhs) =~ rhs.abs
}

// !~
infix operator !~ : SimilarityPrecedence
public func !~(lhs:Double, rhs:Double) -> Bool {
    return !(lhs =~ rhs)
}
public func !~(lhs:Complex<Double>, rhs:Complex<Double>) -> Bool {
    return !(lhs =~ rhs)
}
public func !~(lhs:Complex<Double>, rhs:Double) -> Bool {
    return !(lhs =~ rhs)
}
public func !~(lhs:Double, rhs:Complex<Double>) -> Bool {
    return !(lhs =~ rhs)
}
