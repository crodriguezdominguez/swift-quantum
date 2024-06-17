//
//  complex.swift
//  complex
//
//  Created by Dan Kogai on 6/12/14.
//  Copyright (c) 2014 Dan Kogai. All rights reserved.
//
#if os(Linux)
    import Glibc
#else
    import Darwin
    import CoreGraphics
#endif

///
/// ArithmeticType: Minimum requirement for `T` of `Complex`.
///
/// * currently `Int`, `Double` and `Float`
/// * and `CGFloat` if not os(Linux)
public protocol ArithmeticType: SignedNumeric, Comparable, Hashable {
    // Initializers (predefined)
    init(_: Int)
    init(_: Double)
    init(_: Float)
    init(_: Self)
    // CGFloat if !os(Linux)
    #if !os(Linux)
    init(_: CGFloat)
    #endif
    // Operators (predefined)
    prefix static func + (_: Self)->Self
    prefix static func - (_: Self)->Self
    static func + (_: Self, _: Self)->Self
    static func - (_: Self, _: Self)->Self
    static func * (_: Self, _: Self)->Self
    static func / (_: Self, _: Self)->Self
    // used by Complex#description
    var sign:FloatingPointSign { get }
}
// protocol extension !!!
public extension ArithmeticType {
    /// abs(z)
    static func abs(_ x:Self)->Self { return x.sign == .minus ? -x : x }
    /// failable initializer to conver the type
    /// - parameter x: `U:ArithmeticType` where U might not be T
    /// - returns: Self(x)
    init<U:ArithmeticType>(_ x:U) {
        switch x {
        case let s as Self:     self.init(s)
        case let d as Double:   self.init(d)
        case let f as Float:    self.init(f)
        case let i as Int:      self.init(i)
        default:
            fatalError("init(\(x)) failed")
        }
    }
}

public extension Double {
    var i:Complex { return Complex(0.0, self) }
}

///
/// Complex of Integers or Floating-Point Numbers
///
public struct Complex : Equatable, CustomStringConvertible, Hashable {
    public var re:Double
    public var im:Double
    
    /// standard init(r, i)
    public init(_ r:Double, _ i:Double) {
        (re, im) = (r, i)
    }
    /// default init() == init(0, 0)
    public init() {
        (re, im) = (0, 0)
    }
    /// init(t:(r, i))
    public init(t:(Double, Double)) {
        (re, im) = t
    }
    
    /// `self * i`
    public var i:Complex { return Complex(-im, re) }
    /// real part of self. also a setter.
    public var real:Double { get{ return re } set(r){ re = r } }
    /// imaginary part of self. also a setter.
    public var imag:Double { get{ return im } set(i){ im = i } }
    /// norm of self
    public var norm:Double { return re*re + im*im }
    /// conjugate of self
    public var conj:Complex { return Complex(re, -im) }
    /// .description -- conforms to Printable
    public var description:String {
        let absIm = Swift.abs(im)
        let absRe = Swift.abs(re)
        
        if absIm =~ 0.0 {
            return "\(re)"
        }
        
        if absRe =~ 0.0 {
            return "\(im)i"
        }
        
        let sig = (im.sign == .minus) ? "-" : "+"
        return "\(re)\(sig)\(absIm)i"
    }
    /// .hashValue -- conforms to Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.description.hashValue)
    }
    
    /// (re:real, im:imag)
    public var tuple:(Double, Double) {
        get{ return (re, im) }
        set(t){ (re, im) = t }
    }
}
/// real part of z
public func real(_ z:Complex) -> Double { return z.re }
/// imaginary part of z
public func imag(_ z:Complex) -> Double { return z.im }
/// norm of z
public func norm(_ z:Complex) -> Double { return z.norm }
/// conjugate of z
public func conj(_ z:Complex) -> Complex { return Complex(z.re, -z.im) }

///
///  RealType:  Types acceptable for "CMath"
///
/// * currently, `Double` and `Float`
///   * and `CGFloat` if not `os(Linux)`
public protocol RealType : ArithmeticType, FloatingPoint {
    static var EPSILON:Self { get } // for =~
}
/// POP!
extension RealType {
    /// Default type to store RealType
    public typealias Real = Double
    //typealias PKG = Darwin
    // math functions - needs extension for each struct
    #if os(Linux)
    public static func cos(x:Self)->    Self { return Self(Glibc.cos(Real(x))) }
    public static func cosh(x:Self)->   Self { return Self(Glibc.cosh(Real(x))) }
    public static func exp(x:Self)->    Self { return Self(Glibc.exp(Real(x))) }
    public static func log(x:Self)->    Self { return Self(Glibc.log(Real(x))) }
    public static func sin(x:Self)->    Self { return Self(Glibc.sin(Real(x))) }
    public static func sinh(x:Self)->   Self { return Self(Glibc.sinh(Real(x))) }
    public static func sqrt(x:Self)->   Self { return Self(Glibc.sqrt(Real(x))) }
    public static func hypot(x:Self, _ y:Self)->Self { return Self(Glibc.hypot(Real(x), Real(y))) }
    public static func atan2(y:Self, _ x:Self)->Self { return Self(Glibc.atan2(Real(y), Real(x))) }
    public static func pow(x:Self, _ y:Self)->  Self { return Self(Glibc.pow(Real(x), Real(y))) }
    #else
    public static func cos(_ x:Self)->    Self { return Self(Darwin.cos(Real(x))) }
    public static func cosh(_ x:Self)->   Self { return Self(Darwin.cosh(Real(x))) }
    public static func exp(_ x:Self)->    Self { return Self(Darwin.exp(Real(x))) }
    public static func log(_ x:Self)->    Self { return Self(Darwin.log(Real(x))) }
    public static func sin(_ x:Self)->    Self { return Self(Darwin.sin(Real(x))) }
    public static func sinh(_ x:Self)->   Self { return Self(Darwin.sinh(Real(x))) }
    public static func sqrt(_ x:Self)->   Self { return Self(Darwin.sqrt(Real(x))) }
    public static func hypot(_ x:Self, _ y:Self)->Self { return Self(Darwin.hypot(Real(x), Real(y))) }
    public static func atan2(_ y:Self, _ x:Self)->Self { return Self(Darwin.atan2(Real(y), Real(x))) }
    public static func pow(_ x:Self, _ y:Self)->  Self { return Self(Darwin.pow(Real(x), Real(y))) }
    #endif
}

// Double is default since floating-point literals are Double by default
extension Double : RealType {
    public static var EPSILON = 0x1p-52
}

/// Complex of Floting Point Numbers
extension Complex {
    public init(abs:Double, arg:Double) {
        self.re = abs * Double.cos(arg)
        self.im = abs * Double.sin(arg)
    }
    
    /// absolute value of self in T:RealType
    public var abs:Double {
        get { return Double.sqrt(re*re + im*im) }
        set(r){ let f = r / abs; re = re * f; im = im * f }
    }
    /// argument of self in T:RealType
    public var arg:Double  {
        get { return Double.atan2(im, re) }
        set(t){ let m = abs; re = m * Double.cos(t); im = m * Double.sin(t) }
    }
    /// projection of self in Complex
    public var proj:Complex {
        if re.isFinite && im.isFinite {
            return self
        } else {
            return Complex(Double(1)/Double(0), (im.sign == .minus) ? -Double(0) : 0.0)
        }
    }
}

extension Complex : ExpressibleByFloatLiteral {
    public init(floatLiteral value: FloatLiteralType) {
        self.re = Double(value)
        self.im = Double(0.0)
    }
}

/// absolute value of z
public func abs(_ z:Complex) -> Double { return z.abs }
/// argument of z
public func arg(_ z:Complex) -> Double { return z.arg }
/// projection of z
public func proj(_ z:Complex) -> Complex { return z.proj }
// ==
public func ==(lhs:Complex, rhs:Complex) -> Bool {
    return (lhs.re == rhs.re) && (lhs.im == rhs.im)
}

// +, +=
public prefix func + (z:Complex) -> Complex {
    return z
}
public func + (lhs:Complex, rhs:Complex) -> Complex {
    return Complex(lhs.re + rhs.re, lhs.im + rhs.im)
}
public func + (lhs:Complex, rhs:Double) -> Complex {
    return lhs + Complex(rhs, 0.0)
}
public func + (lhs:Double, rhs:Complex) -> Complex {
    return Complex(lhs, 0.0) + rhs
}
public func += (lhs:inout Complex, rhs:Complex) {
    lhs = lhs + rhs
}
public func += (lhs:inout Complex, rhs:Double) {
    lhs.re = lhs.re + rhs
}
// -, -=
public prefix func - (z:Complex) -> Complex {
    return Complex(-z.re, -z.im)
}
public func - (lhs:Complex, rhs:Complex) -> Complex {
    return Complex(lhs.re - rhs.re, lhs.im - rhs.im)
}
public func - (lhs:Complex, rhs:Double) -> Complex {
    return lhs - Complex(rhs, 0.0)
}
public func - (lhs:Double, rhs:Complex) -> Complex {
    return Complex(lhs, 0.0) - rhs
}
public func -= (lhs:inout Complex, rhs:Complex) {
    lhs = lhs + rhs
}
public func -= (lhs:inout Complex, rhs:Double) {
    lhs.re = lhs.re + rhs
}
// *
public func * (lhs:Complex, rhs:Complex) -> Complex {
    return Complex(
        lhs.re * rhs.re - lhs.im * rhs.im,
        lhs.re * rhs.im + lhs.im * rhs.re
    )
}
public func * (lhs:Complex, rhs:Double) -> Complex {
    return Complex(lhs.re * rhs, lhs.im * rhs)
}
public func * (lhs:Double, rhs:Complex) -> Complex {
    return Complex(lhs * rhs.re, lhs * rhs.im)
}
// *=
public func *= (lhs:inout Complex, rhs:Complex) {
    lhs = lhs * rhs
}
public func *= (lhs:inout Complex, rhs:Double) {
    lhs = lhs * rhs
}
// /, /=
//
// cf. https://github.com/dankogai/swift-complex/issues/3
//
public func / (lhs:Complex, rhs:Complex) -> Complex {
    return (lhs * rhs.conj) / rhs.norm
}
public func / (lhs:Complex, rhs:Double) -> Complex {
    return Complex(lhs.re / rhs, lhs.im / rhs)
}
public func / (lhs:Double, rhs:Complex) -> Complex {
    return Complex(lhs, 0.0) / rhs
}
public func /= (lhs:inout Complex, rhs:Complex) {
    lhs = lhs / rhs
}
public func /= (lhs:inout Complex, rhs:Double) {
    lhs = lhs / rhs
}
/// - returns: e ** z in Complex
public func exp(_ z:Complex) -> Complex {
    let r = Double.exp(z.re)
    let a = z.im
    return Complex(r * Double.cos(a), r * Double.sin(a))
}
/// - returns: natural log of z in Complex
public func log(_ z:Complex) -> Complex {
    return Complex(Double.log(z.abs), z.arg)
}
/// - returns: log 10 of z in Complex
public func log10(_ z:Complex) -> Complex { return log(z) / M_LN10 }
public func log10(_ r:Double) -> Double { return Double.log(r) / M_LN10 }
/// - returns: lhs ** rhs in Complex
public func pow(_ lhs:Complex, _ rhs:Complex) -> Complex {
    return exp(log(lhs) * rhs)
}
/// - returns: lhs ** rhs in Complex
public func pow(_ lhs:Complex, _ rhs:Int) -> Complex {
    if rhs == 1 { return lhs }
    var r = Complex(1, 0)
    if rhs == 0 { return r }
    if lhs == 0.0 { return Complex(1.0/0.0, 0.0) }
    var ux = abs(rhs), b = lhs
    while (ux > 0) {
        if ux & 1 == 1 { r *= b }
        ux >>= 1; b *= b
    }
    return rhs < 0 ? 1.0 / r : r
}
/// - returns: lhs ** rhs in Complex
public func pow(_ lhs:Complex, _ rhs:Double) -> Complex {
    if lhs == 1.0 || rhs == 0.0 {
        return Complex(1.0, 0.0) // x ** 0 == 1 for any x; 1 ** y == 1 for any y
    }
    if lhs == 0.0 { return Complex(Double.pow(lhs.re, rhs), 0.0) } // 0 ** y for any y
    // integer
    let ix = Int(rhs)
    if Double(ix) == rhs { return pow(lhs, ix) }
    // integer/2
    let fx = rhs - Double(ix)
    return fx*2 == 1.0 ? pow(lhs, ix) * sqrt(lhs)
        : -fx*2 == 1.0 ? pow(lhs, ix) / sqrt(lhs)
        : pow(lhs, Complex(rhs, 0.0))
}
/// - returns: lhs ** rhs in Complex
public func pow(_ lhs:Double, _ rhs:Complex) -> Complex {
    return pow(Complex(lhs, 0.0), rhs)
}
/// - returns: square root of z in Complex
public func sqrt(_ z:Complex) -> Complex {
    // return z ** 0.5
    let d = Double.hypot(z.re, z.im)
    let r = Double.sqrt((z.re + d)/2.0)
    if z.im < 0.0 {
        return Complex(r, -Double.sqrt((-z.re + d)/2.0))
    } else {
        return Complex(r,  Double.sqrt((-z.re + d)/2.0))
    }
}
/// - returns: cosine of z in Complex
public func cos(_ z:Complex) -> Complex {
    //return (exp(z.i) + exp(-z.i)) / T(2)
    return Complex(Double.cos(z.re)*Double.cosh(z.im), -Double.sin(z.re)*Double.sinh(z.im))
}
/// - returns: sine of z in Complex
public func sin(_ z:Complex) -> Complex {
    // return -(exp(z.i) - exp(-z.i)).i / T(2)
    return Complex(Double.sin(z.re)*Double.cosh(z.im), +Double.cos(z.re)*Double.sinh(z.im))
}
/// - returns: tangent of z in Complex
public func tan(_ z:Complex) -> Complex {
    return sin(z) / cos(z)
}
/// - returns: arc tangent of z in Complex
public func atan(_ z:Complex) -> Complex {
    let lp = log(1.0 - z.i), lm = log(1.0 + z.i)
    return (lp - lm).i / 2.0
}
/// - returns: arc sine of z in Complex
public func asin(_ z:Complex) -> Complex {
    return -log(z.i + sqrt(1.0 - z*z)).i
}
/// - returns: arc cosine of z in Complex
public func acos(_ z:Complex) -> Complex {
    return log(z - sqrt(1.0 - z*z).i).i
}
/// - returns: hyperbolic sine of z in Complex
public func sinh(_ z:Complex) -> Complex {
    // return (exp(z) - exp(-z)) / T(2)
    return -sin(z.i).i;
}
/// - returns: hyperbolic cosine of z in Complex
public func cosh(_ z:Complex) -> Complex {
    // return (exp(z) + exp(-z)) / T(2)
    return cos(z.i);
}
/// - returns: hyperbolic tangent of z in Complex
public func tanh(_ z:Complex) -> Complex {
    // let ez = exp(z), e_z = exp(-z)
    // return (ez - e_z) / (ez + e_z)
    return sinh(z) / cosh(z)
}
/// - returns: inverse hyperbolic sine of z in Complex
public func asinh(_ z:Complex) -> Complex {
    return log(z + sqrt(z*z + 1.0))
}
/// - returns: inverse hyperbolic cosine of z in Complex
public func acosh(_ z:Complex) -> Complex {
    return log(z + sqrt(z*z - 1.0))
}
/// - returns: inverse hyperbolic tangent of z in Complex
public func atanh(_ z:Complex) -> Complex {
    let tp = 1.0 + z, tm = 1.0 - z
    return log(tp / tm) / 2.0
}

/// CGFloat if !os(Linux)
#if !os(Linux)
extension Complex {
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
public func % (lhs:Complex, rhs:Complex) -> Complex {
    return lhs - (lhs / rhs) * rhs
}
public func % (lhs:Complex, rhs:Double) -> Complex {
    return lhs - (lhs / rhs) * rhs
}
public func % (lhs:Double, rhs:Complex) -> Complex {
    return Complex(lhs, 0.0) % rhs
}
public func %= (lhs:inout Complex, rhs:Complex) {
    lhs = lhs % rhs
}
public func %= (lhs:inout Complex, rhs:Double) {
    lhs = lhs % rhs
}
