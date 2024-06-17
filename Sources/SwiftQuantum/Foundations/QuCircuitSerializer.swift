//
//  QuCircuitSerializer.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 15/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation

public struct QuCircuitSerializer {
    //MARK: - Serialization
    
    public static func serialize(_ circuit:QuCircuit) -> String {
        var result = "{\"name\":\"\(circuit.transformerName)\", \"inputs\":\(circuit.numberOfInputs), \"outputs\":\(circuit.numberOfOutputs), \"timeline\":["
        let times = circuit.timeline.keys.sorted(by: <)
        for time in times {
            let entries = circuit.timeline[time]!
            for entry in entries {
                result += serialize(transformer: entry.transformer, time: time, indices: entry.indices)
            }
        }
        result = result.trimmingCharacters(in: CharacterSet(charactersIn: ","))
        
        result += "]"
        
        result += ", \"transformers\":["
        
        let transformers = circuit.allTransformers()
        for transformer in transformers {
            result += "{"
            result += "\"name\":\"\(transformer.transformerName)\","
            result += "\"inputs\":\(transformer.numberOfInputs),"
            result += "\"outputs\":\(transformer.numberOfOutputs),"
            result += "\"matrix\":\(jsonRepresentation(transformer.transformationMatrix))"
            result += "},"
        }
        
        result = result.trimmingCharacters(in: CharacterSet(charactersIn: ","))
        
        result += "]}"
        
        return result
    }
    
    fileprivate static func serializeWithoutTransformers(_ circuit:QuCircuit) -> String {
        var result = "{\"name\":\"\(circuit.transformerName)\", \"inputs\":\(circuit.numberOfInputs), \"outputs\":\(circuit.numberOfOutputs), \"timeline\":["
        let times = circuit.timeline.keys.sorted(by: <)
        for time in times {
            let entries = circuit.timeline[time]!
            for entry in entries {
                result += serialize(transformer: entry.transformer, time: time, indices: entry.indices)
            }
        }
        result = result.trimmingCharacters(in: CharacterSet(charactersIn: ","))
        
        result += "]}"
        
        return result
    }
    
    fileprivate static func serialize(transformer:QuBitTransformer, time:Int, indices:[Int]) -> String {
        var result = ""
        
        if let circuit = transformer as? QuCircuit {
            result += "{"
            result += "\"name\":\"\(transformer.transformerName)\","
            result += "\"inputs\":\(transformer.numberOfInputs),"
            result += "\"outputs\":\(transformer.numberOfOutputs),"
            result += "\"implementation\":\(serializeWithoutTransformers(circuit)),"
            result += "\"indices\":\(indices),"
            result += "\"time\":\(time)"
            result += "},"
        }
        else{
            result += "{"
            result += "\"name\":\"\(transformer.transformerName)\","
            result += "\"indices\":\(indices),"
            result += "\"time\":\(time)"
            result += "},"
        }
        
        return result
    }
    
    fileprivate static func jsonRepresentation(_ matrix:QuAmplitudeMatrix) -> String {
        var gridRepresentation = "["
        for complex in matrix.contents {
            let re = String(format: "%.19g", complex.re)
            let im = String(format: "%.19g", complex.im)
            gridRepresentation += "{\"re\":\(re),\"im\":\(im)},"
        }
        
        gridRepresentation = gridRepresentation.trimmingCharacters(in: CharacterSet(charactersIn: ","))
        
        gridRepresentation += "]"
        
        var result = "{"
        result += "\"rows\":\(matrix.rows),"
        result += "\"columns\":\(matrix.columns),"
        result += "\"contents\":\(gridRepresentation)"
        result += "}"
        
        return result
    }
    
    //MARK: - Deserialization
    
    public static func deserialize(_ circuitString:String) throws -> QuCircuit {
        let error = NSError(domain: "Quantum Circuit IO", code: 100, userInfo: [NSLocalizedDescriptionKey: "The circuit representation is invalid"])
        
        if let json = try JSONSerialization.jsonObject(with: circuitString.data(using: String.Encoding.utf8)!, options: .allowFragments) as? [String:AnyObject] {
            return try deserialize(json)
        }
        else{
            throw error
        }
    }
    
    fileprivate static func deserialize(_ contents:[String:AnyObject]) throws -> QuCircuit {
        let error = NSError(domain: "Quantum Circuit IO", code: 100, userInfo: [NSLocalizedDescriptionKey: "The circuit representation is invalid"])
        
        guard let jsonTransformers = contents["transformers"] as? [[String:AnyObject]] else {
            throw error
        }
        
        var transformers = [String:UniversalGate]()
        for jsonTransformer in jsonTransformers {
            guard let inputs = jsonTransformer["inputs"] as? Int, let outputs = jsonTransformer["outputs"] as? Int, let name = jsonTransformer["name"] as? String, let matrixJson = jsonTransformer["matrix"] as? [String:AnyObject] else {
                throw error
            }
            
            guard let matrixRows = matrixJson["rows"] as? Int, let matrixColumns = matrixJson["columns"] as? Int, let matrixContents = matrixJson["contents"] as? [[String:Double]] else {
                throw error
            }
            
            guard matrixContents.count == matrixRows*matrixColumns else {
                throw error
            }
            
            var matrix = QuAmplitudeMatrix(rows: matrixRows, columns: matrixColumns, repeatedValue: 0.0)
            for i in 0..<(matrixRows*matrixColumns) {
                guard let re = matrixContents[i]["re"], let im = matrixContents[i]["im"] else {
                    throw error
                }
                
                matrix[rawIndex: i] = QuAmplitude(re, im)
            }
            
            let transformer = UniversalGate(matrix: matrix, name: name, numberOfInputs: inputs, numberOfOutputs: outputs)
            transformers[name] = transformer
        }
        
        return try deserialize(contents, transformers: transformers)
    }
    
    fileprivate static func deserialize(_ json:[String:AnyObject], transformers:[String:UniversalGate]) throws -> QuCircuit {
        let error = NSError(domain: "Quantum Circuit IO", code: 100, userInfo: [NSLocalizedDescriptionKey: "The circuit representation is invalid"])
        
        guard let transformerName = json["name"] as? String,
            let numberOfInputs = json["inputs"] as? Int,
            let numberOfOutputs = json["outputs"] as? Int else {
                throw error
        }
        
        let circuit = QuCircuit(name: transformerName, numberOfInputs: numberOfInputs, numberOfOutputs: numberOfOutputs)
        
        guard let timeline = json["timeline"] as? [[String:AnyObject]] else {
            throw error
        }
        
        for entry in timeline {
            guard let name = entry["name"] as? String, let indices = entry["indices"] as? [Int], let time = entry["time"] as? Int else {
                throw error
            }
            
            let transformer:QuBitTransformer
            if entry["implementation"] != nil {
                transformer = try deserializeSubcircuit(entry, transformers: transformers)
            }
            else{
                guard let tr = transformers[name] else {
                    throw error
                }
                transformer = tr
            }
            
            do{
                try circuit.append(transformer: transformer, atTime: time, forInputAtIndices: indices)
            }catch{
                throw error
            }
        }
        
        return circuit
    }
    
    fileprivate static func deserializeSubcircuit(_ contents:[String:AnyObject], transformers:[String:UniversalGate]) throws -> QuCircuit {
        let error = NSError(domain: "Quantum Circuit IO", code: 100, userInfo: [NSLocalizedDescriptionKey: "The circuit representation is invalid"])
        
        guard let name = contents["name"] as? String,
            let numberOfInputs = contents["inputs"] as? Int,
            let numberOfOutputs = contents["outputs"] as? Int else {
                throw error
        }
        
        let circuit = QuCircuit(name: name, numberOfInputs: numberOfInputs, numberOfOutputs: numberOfOutputs)
        
        guard let json = contents["implementation"] as? [String:AnyObject] else {
            throw error
        }
        
        guard let timeline = json["timeline"] as? [[String:AnyObject]] else {
            throw error
        }
        
        for entry in timeline {
            guard let name = entry["name"] as? String, let indices = entry["indices"] as? [Int], let time = entry["time"] as? Int else {
                throw error
            }
            
            let transformer:QuBitTransformer
            if entry["implementation"] != nil {
                transformer = try deserializeSubcircuit(entry, transformers: transformers)
            }
            else{
                guard let tr = transformers[name] else {
                    throw error
                }
                transformer = tr
            }
            
            do{
                try circuit.append(transformer: transformer, atTime: time, forInputAtIndices: indices)
            }catch{
                throw error
            }
        }
        
        return circuit
    }
}
