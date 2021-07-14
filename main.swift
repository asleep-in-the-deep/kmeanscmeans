//
//  main.swift
//  СMeans
//
//  Created by Arina on 10.03.2021.
//

import Foundation
import Accelerate
import simd

class CMeans {
    let numClusters: Int
    var vectors: [simd_float2]
    var centersArray: [simd_float2] = []
    
    let fuzzyParameter: Float
    let stopParameter: Float
    
    let randNums: [Int]
    
    var iterationNum: Int = 1
    
    init(clusters: Int, array: [simd_float2], fuzzy: Float, stop: Float, randNums: [Int]) {
        self.numClusters = clusters
        self.vectors = array
        self.fuzzyParameter = fuzzy
        self.stopParameter = stop
        self.randNums = randNums
        calculateResult()
    }
    
    func createCenters() -> [simd_float2] {
        var centerNum: Int = 0
        
        var center: simd_float2
        
        while centerNum < randNums.count {
            let randNum = randNums[centerNum]
            center = vectors[randNum-1]
            
            self.centersArray.append(center)
            self.vectors.remove(at: randNum-1)
            centerNum += 1
        }
        return centersArray
    }
    
    func definePoints(centers: [simd_float2]) -> [simd_float2 : [Float]] {
        var coefficientDictionary = [simd_float2 : [Float]]()
        
        for point in vectors {
            var coefficient: Float = 0
            
            for center in centers {
                let distance = simd_distance(point, center)
                
                coefficient = 1 / pow(distance, 2 / (fuzzyParameter - 1))
                
                var currentPoint = coefficientDictionary[point] ?? []
                currentPoint.append(coefficient)
                coefficientDictionary.updateValue(
                    currentPoint,
                    forKey: point
                )
            }
        }
        let normalizedDictionary = normalizeCoefficients(clusters: coefficientDictionary)
        
        return normalizedDictionary
    }
    
    func normalizeCoefficients(clusters: [simd_float2 : [Float]]) -> [simd_float2 : [Float]] {
        var newDictionary = clusters
        
        for (vector, coefficients) in clusters {
            var parameter: Float = 0
            var sum: Float = 0
            var newPoint: [Float] = []
            
            for coefficient in coefficients {
                sum += coefficient
            }
            
            for coefficient in coefficients {
                parameter = coefficient
                parameter = parameter / sum
                newPoint.append(parameter)
            }
            
            newDictionary.updateValue(newPoint, forKey: vector)
        }
        
        return newDictionary
    }
    
    func recalculateCenters(forClusters clusters: [simd_float2 : [Float]], centers: [simd_float2]) -> [simd_float2] {
        var newCenters: [simd_float2] = []
        
        for center in centers {
            var sumX: Float = 0
            var sumY: Float = 0
            
            var newX: Float = 0
            var newY: Float = 0
            
            var coeffSum: Float = 0
            
            for (_, coefficients) in clusters {
                for item in coefficients {
                    sumX += pow(item, fuzzyParameter) * center.x
                    sumY += pow(item, fuzzyParameter) * center.y
                    coeffSum += pow(item, fuzzyParameter)
                }
            }
            
            newX = sumX / coeffSum
            newY = sumY / coeffSum
            
            newCenters.append(simd_float2(newX, newY))
        }
        
        return newCenters
    }
    
    
    func calculateResult() {
        let firstCenters = createCenters()
        
        var newCenters: [simd_float2] = []
        var clusters: [simd_float2 : [Float]] = [:]
        
        var resultParameter: Float = Float.greatestFiniteMagnitude
        
        print("Итерация \(iterationNum)")
        print("Центры")
        for center in firstCenters {
            print("\t\(center.x), \(center.y)")
        }
        
        repeat {
            if iterationNum == 1 {
                clusters = definePoints(centers: firstCenters)
                newCenters = firstCenters
            } else {
                clusters = definePoints(centers: newCenters)
            }
            
            var clusterIndex: Int = 0
            var pastArray: [Float] = []
            
            while clusterIndex < numClusters {
                for (_, cluster) in clusters {
                    pastArray.append(cluster[clusterIndex])
                }
                clusterIndex += 1
            }
            
            newCenters = recalculateCenters(forClusters: clusters, centers: newCenters)
            
            iterationNum += 1
            
            print("\nИтерация \(iterationNum)")
            print("Центры")
            
            for center in newCenters {
                print("\t\(center.x), \(center.y)")
            }

            clusterIndex = 0
            
            while clusterIndex < numClusters {
                for cluster in clusters {
                    let coefficient = cluster.value[clusterIndex]
                    let pastCoefficient = pastArray[clusterIndex]
                    
                    resultParameter = abs(coefficient - pastCoefficient)
                }
                clusterIndex += 1
            }
            
        } while resultParameter > stopParameter
        
    }
}

class KMeans {
    let numClusters: Int
    var vectors: [simd_float2]
    
    var iterationNum: Int = 1
    
    let randNums: [Int]
    
    init(clusters: Int, array: [simd_float2], randNums: [Int]) {
        self.numClusters = clusters
        self.vectors = array
        self.randNums = randNums
        calculateResult()
    }
    
    func createCenters() -> [simd_float2] {
        var centerNum: Int = 0
        
        var center: simd_float2
        var centersArray: [simd_float2] = []
        
        while centerNum < randNums.count {
            let randNum = randNums[centerNum]
            center = vectors[randNum-1]
            centersArray.append(center)
            
            self.vectors.remove(at: randNum-1)
            centerNum += 1
        }
        return centersArray
    }
    
    func definePoints(centers: [simd_float2]) -> [Int : [simd_float2]] {
        var clusterDictionary = [Int : [simd_float2]]()
        
        for point in vectors {
            var centerIndex = 0
            var nearestDist: Float = Float.greatestFiniteMagnitude
            
            for (index, center) in centers.enumerated() {
                let distance = simd_distance(point, center)
                
                if distance < nearestDist {
                    centerIndex = index
                    nearestDist = distance
                }
            }
            
            var currentPoint = clusterDictionary[centerIndex] ?? []
            currentPoint.append(point)
            clusterDictionary.updateValue(currentPoint, forKey: centerIndex)
        }
       
        return clusterDictionary
    }
    
    func recalculateCenters(forClusters clusters: [Int : [simd_float2]]) -> [simd_float2] {
        var newCenters: [simd_float2] = []
        
        for (_, value) in clusters {
            var sumX: Float = 0
            var sumY: Float = 0
            
            for item in value {
                sumX += item.x
                sumY += item.y
            }
            sumX = sumX / abs(Float(value.count))
            sumY = sumY / abs(Float(value.count))
            
            newCenters.append(simd_float2(sumX, sumY))
        }
        
        return newCenters
    }
    
    func calculateResult() {
        let firstCenters = createCenters()
        
        var newCenters: [simd_float2] = []
        var pastCenters: [simd_float2] = []
        var clusters: [Int : [simd_float2]] = [:]
    
        print("Итерация \(iterationNum)")
        print("Центры")
        for element in firstCenters {
            print("\t\(element.x), \(element.y)")
        }
        
        repeat {
            if iterationNum == 1 {
                clusters = definePoints(centers: firstCenters)
                print("Создано \(clusters.count) кластера")
            } else {
                clusters = definePoints(centers: newCenters)
                pastCenters = newCenters
            }
            
            newCenters = recalculateCenters(forClusters: clusters)
            
            iterationNum += 1
            
            print("\nИтерация \(iterationNum)")
            print("Центры")
            for element in newCenters {
                print("\t\(element.x), \(element.y)")
            }
        } while newCenters != pastCenters
    
    }
}



func welcoming() {
    var array: [simd_float2] = []
    let elementNums = 100

    for _ in 0...elementNums {
        array.append(simd_float2(Float.random(in: -1000...1000), Float.random(in: -1000...1000)))
    }
    
    let clusters = 3
    var randNums: [Int] = []
    
    var clusterNum = 0
    while clusterNum < clusters {
        randNums.append(Int.random(in: 0..<elementNums))
        clusterNum += 1
    }
    
    print("Алгоритм K-Means\n")
    //KMeans(clusters: clusters, array: array, randNums: randNums)
    
    print("\nАлгоритм C-Means\n")
    CMeans(clusters: clusters, array: array, fuzzy: 10, stop: 0.1, randNums: randNums)
}

welcoming()




