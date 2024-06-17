//
//  QuAmplitudeMatrix.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 3/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation
import Accelerate
import Dispatch

public struct QuAmplitudeMatrix {
    public fileprivate(set) var rows: Int
    public fileprivate(set) var columns: Int
    
    public let isCompressed: Bool
    
    fileprivate var _sparseContents: SparseArray? = nil
    fileprivate var _linearContents: [QuAmplitude]? = nil
    
    internal var contents: SparseArray {
        if let sparse = self._sparseContents {
            return sparse
        }
        else {
            return SparseArray(_linearContents!)
        }
    }
    
    internal init(rows: Int, columns: Int, contents: SparseArray) {
        self.rows = rows
        self.columns = columns
        self.isCompressed = true
        self._sparseContents = contents
    }
    
    public init(rows: Int, columns: Int, repeatedValue: QuAmplitude, compressed: Bool = true) {
        self.rows = rows
        self.columns = columns
        self.isCompressed = compressed
        if compressed {
            _sparseContents = SparseArray(count: rows * columns, defaultValue: repeatedValue)
        }
        else {
            _linearContents = [QuAmplitude](repeating: repeatedValue, count: rows * columns)
        }
    }
    
    fileprivate init(rows: Int, columns: Int, rawContents: [QuAmplitude], compressed: Bool = true) {
        self.rows = rows
        self.columns = columns
        self.isCompressed = compressed
        if compressed {
            _sparseContents = SparseArray(rawContents)
        }
        else {
            _linearContents = rawContents
        }
    }
    
    public init(_ contents: [[QuAmplitude]]) {
        let m = contents.count
        let n = contents[0].count
        
        self.init(rows: m, columns: n, repeatedValue: 0.0, compressed: true)
        
        for (i, row) in contents.enumerated() {
            self._sparseContents![i*n..<i*n+Swift.min(m, row.count)] = row
        }
        
        if self._sparseContents!.shouldRecompress() {
            self._sparseContents!.recompress()
        }
    }
    
    public func uncompressed() -> QuAmplitudeMatrix {
        if isCompressed {
            return QuAmplitudeMatrix(rows: self.rows, columns: self.columns, rawContents: _sparseContents!.denseRepresentation(), compressed: false)
        }
        else {
            return self
        }
    }
    
    public func compressed() -> QuAmplitudeMatrix {
        if isCompressed {
            return self
        }
        else {
            return QuAmplitudeMatrix(rows: self.rows, columns: self.columns, contents: SparseArray(_linearContents!))
        }
    }
    
    public static func identity(size:Int) -> QuAmplitudeMatrix {
        var matrix = QuAmplitudeMatrix(rows: size, columns: size, repeatedValue: 0.0)
        for i in 0..<size {
            matrix[i, i] = 1.0
        }
        
        return matrix
    }
    
    public subscript(rawIndex index:Int) -> QuAmplitude {
        get {
            if isCompressed {
                return _sparseContents![index]
            }
            else {
                return _linearContents![index]
            }
        }
        set {
            if isCompressed {
                _sparseContents![index] = newValue
            }
            else {
                _linearContents![index] = newValue
            }

        }
    }
    
    public subscript(row: Int, column: Int) -> QuAmplitude {
        get {
            assert(indexIsValidForRow(row, column: column))
            if isCompressed {
                return _sparseContents![(row * columns) + column]
            }
            else {
                return _linearContents![(row * columns) + column]
            }
        }
        
        set {
            assert(indexIsValidForRow(row, column: column))
            if isCompressed {
                _sparseContents![(row * columns) + column] = newValue
            }
            else {
                _linearContents![(row * columns) + column] = newValue
            }
        }
    }
    
    public subscript(row row: Int) -> [QuAmplitude] {
        get {
            assert(row < rows)
            let startIndex = row * columns
            let endIndex = row * columns + columns
            if isCompressed {
                return _sparseContents![startIndex..<endIndex]
            }
            else {
                return Array(_linearContents![startIndex..<endIndex])
            }
        }
        
        set {
            assert(row < rows)
            assert(newValue.count == columns)
            let startIndex = row * columns
            let endIndex = row * columns + columns
            if isCompressed {
                _sparseContents![startIndex..<endIndex] = newValue
            }
            else {
                _linearContents!.replaceSubrange(startIndex..<endIndex, with: newValue)
            }
        }
    }
    
    public subscript(column column: Int) -> [QuAmplitude] {
        get {
            var result = [QuAmplitude](repeating: 0.0, count: rows)
            
            for i in 0..<rows {
                let index = i * columns + column
                result[i] = isCompressed ? _sparseContents![index] : _linearContents![index]
            }
            return result
        }
        
        set {
            assert(column < columns)
            assert(newValue.count == rows)
            for i in 0..<rows {
                let index = i * columns + column
                if isCompressed {
                    _sparseContents![index] = newValue[i]
                }
                else {
                    _linearContents![index] = newValue[i]
                }
            }
        }
    }
    
    fileprivate func sparseRow(_ row: Int) -> SparseArray {
        assert(row < rows)
        var result = SparseArray(count: self.columns, defaultValue: self.contents.defaultValue)
        for j in 0..<columns {
            let index = row * columns + j
            result[j] = self.contents[index]
        }
        
        return result
    }
    
    fileprivate func sparseColumn(_ column: Int) -> SparseArray {
        var result = SparseArray(count: self.rows, defaultValue: self.contents.defaultValue)
        for i in 0..<rows {
            let index = i * columns + column
            result[i] = self.contents[index]
        }
        return result
    }
    
    fileprivate func flatArray() -> [QuAmplitude] {
        if isCompressed {
            return self._sparseContents!.denseRepresentation()
        }
        else {
            return self._linearContents!
        }
    }
    
    @inline(__always) fileprivate func indexIsValidForRow(_ row: Int, column: Int) -> Bool {
        return row >= 0 && row < rows && column >= 0 && column < columns
    }
}

// MARK: - Printable

extension QuAmplitudeMatrix: CustomStringConvertible {
    public var description: String {
        var description = ""
        
        for i in 0..<rows {
            let contents = (0..<columns).map{"\(self[i, $0])"}.joined(separator: "\t")
            
            switch (i, rows) {
            case (0, 1):
                description += "(\t\(contents)\t)"
            case (0, _):
                description += "⎛\t\(contents)\t⎞"
            case (rows - 1, _):
                description += "⎝\t\(contents)\t⎠"
            default:
                description += "⎜\t\(contents)\t⎥"
            }
            
            description += "\n"
        }
        
        return description
    }
}

// MARK: - SequenceType

extension QuAmplitudeMatrix: Sequence {
    public func makeIterator() -> AnyIterator<[QuAmplitude]> {
        let endIndex = rows * columns
        var nextRowStartIndex = 0
        
        return AnyIterator {
            if nextRowStartIndex == endIndex {
                return nil
            }
            
            let currentRowStartIndex = nextRowStartIndex
            nextRowStartIndex += self.columns
            
            return self.contents[currentRowStartIndex..<nextRowStartIndex]
        }
    }
}

extension QuAmplitudeMatrix: Equatable {}
public func == (lhs: QuAmplitudeMatrix, rhs: QuAmplitudeMatrix) -> Bool {
    return lhs.rows == rhs.rows && lhs.columns == rhs.columns && lhs.contents == rhs.contents
}

public protocol QuAmplitudeMatrixConvertible {
    func matrixRepresentation() -> QuAmplitudeMatrix
}

public func transpose(_ matrix:QuAmplitudeMatrix) -> QuAmplitudeMatrix {
    var result = QuAmplitudeMatrix(rows: matrix.columns, columns: matrix.rows, contents: matrix.contents)
    for i in 0..<matrix.rows {
        for j in 0..<matrix.columns {
            result[j, i] = matrix[i, j]
        }
    }
    
    return result
}

public func *(left:QuAmplitudeMatrix, right:QuAmplitudeMatrix) throws -> QuAmplitudeMatrix {
    guard left.columns == right.rows else {
        throw NSError(domain: "Arithmetic Exception", code: 100, userInfo: [NSLocalizedDescriptionKey: "Matrix shapes are not compatible for multiplication"])
    }
    
    let count = left.rows*right.columns
    
    if left.isCompressed && right.isCompressed {
        let sparseMultCriteria = (left.contents.defaultValue*right.contents.defaultValue == 0.0) && (left.contents.contents.count <= Int(0.1*Double(left.contents.count)) || right.contents.contents.count <= Int(0.1*Double(right.contents.count)))
        
        if sparseMultCriteria == true {
            var contents = SparseArray(count: count, defaultValue: 0.0)
            
            var columns = [SparseArray]()
            for j in 0..<right.columns {
                columns.append(right.sparseColumn(j))
            }
            
            let q = DispatchQueue(label: "es.everywaretech.quantumcomputing", attributes: DispatchQueue.Attributes.concurrent)
            DispatchQueue.concurrentPerform(iterations: left.rows, execute: { (i) in
                let row = left.sparseRow(i)
                guard left.contents.defaultValue != 0.0 || row.contents.count > 0 else {
                    return
                }
                
                for j in 0..<right.columns {
                    let col = columns[j]
                    
                    guard right.contents.defaultValue != 0.0 || col.contents.count > 0 else {
                        continue
                    }
                    
                    let (sumContents, otherContents):([Int:QuAmplitude], SparseArray)
                    if left.contents.defaultValue != right.contents.defaultValue {
                        (sumContents, otherContents) = left.contents.defaultValue == 0.0 ? (row.contents, col) : (col.contents, row)
                    }
                    else {
                        (sumContents, otherContents) = row.contents.count < col.contents.count ? (row.contents, col) : (col.contents, row)
                    }
                    
                    let k = i*right.columns + j
                    
                    q.async(flags: .barrier, execute: { 
                        contents[k] = sumContents.reduce(QuAmplitude(0.0, 0.0), { (result, values) in
                            return result + (values.1 * otherContents[values.0])
                        })
                    })
                }
            })
            
            q.sync(flags: .barrier, execute: {})
            
            if contents.shouldRecompress() {
                contents.recompress()
            }
            
            return QuAmplitudeMatrix(rows: left.rows, columns: right.columns, contents: contents)
        }
    }
    
    let leftPart = left.flatArray()
    let rightPart = right.flatArray()
    
    var resultPart = [QuAmplitude](repeating: 0.0, count: count)
    var alpha = 1.0
    var beta = 0.0
    let m = Int32(left.rows)
    let k = Int32(left.columns)
    let n = Int32(right.columns)
    
    cblas_zgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, m, n, k, &alpha, leftPart, k, rightPart, n, &beta, &resultPart, n)
    
    return QuAmplitudeMatrix(rows: left.rows, columns: right.columns, rawContents: resultPart, compressed: false)
}

internal func rawMatrixMult(a:[QuAmplitude], b:[QuAmplitude], leftRows m:Int32, leftColumns k:Int32, rightColumns n:Int32) -> [QuAmplitude] {
    var resultPart = [QuAmplitude](repeating: 0.0, count: Int(m*n))
    var alpha = 1.0
    var beta = 0.0
    
    cblas_zgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, m, n, k, &alpha, a, k, b, n, &beta, &resultPart, n)
    
    return resultPart
}

public func pow(_ matrix:QuAmplitudeMatrix, exponent:UInt) throws -> QuAmplitudeMatrix {
    guard matrix.rows == matrix.columns else {
        throw NSError(domain: "Arithmetic Exception", code: 101, userInfo: [NSLocalizedDescriptionKey: "You can only pow square matrices"])
    }
    
    if exponent == 1 {
        return matrix
    }
    else if exponent == 0 {
        return QuAmplitudeMatrix.identity(size: matrix.rows)
    }
    
    var x = matrix.flatArray()
    var y = QuAmplitudeMatrix.identity(size: matrix.rows).flatArray()
    let m = Int32(matrix.rows)
    let k = Int32(matrix.columns)
    let n = Int32(matrix.columns)
    
    var exp = exponent
    while exp > 1 {
        if exponent % 2 == 0 {
            x = rawMatrixMult(a: x, b: x, leftRows: m, leftColumns: k, rightColumns: n)
            exp = exp / 2
        }
        else {
            y = rawMatrixMult(a: x, b: y, leftRows: m, leftColumns: k, rightColumns: n)
            x = rawMatrixMult(a: x, b: x, leftRows: m, leftColumns: k, rightColumns: n)
            exp = (exp - 1) / 2
        }
    }
    
    let result = rawMatrixMult(a: x, b: y, leftRows: m, leftColumns: k, rightColumns: n)
    let contents = SparseArray(result)
    
    return QuAmplitudeMatrix(rows: matrix.rows, columns: matrix.columns, contents: contents)
}

public func tensorProduct(_ m1:QuAmplitudeMatrix, _ m2:QuAmplitudeMatrix) -> QuAmplitudeMatrix {
    let m = m1.rows
    let n = m1.columns
    let p = m2.rows
    let q = m2.columns
    var result = QuAmplitudeMatrix(rows: m*p, columns: n*q, repeatedValue: QuAmplitude(0.0, 0.0))
    for r in 0..<m1.rows {
        for s in 0..<m1.columns {
            for v in 0..<m2.rows {
                for w in 0..<m2.columns {
                    let value = m1[r,s]*m2[v,w]
                    result[(p*r)+v,(q*s)+w] = value
                }
            }
        }
    }
    
    return result
}

