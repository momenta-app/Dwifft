//
//  LCS.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/14/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

fileprivate extension Array where Element: Equatable {
    // Remove first collection element that is equal to the given `object`:
    mutating func remove(_ object: Element) {
        if let index = index(of: object) {
            self.remove(at: index)
        }
    }
}

public struct Diff<T> where T:Equatable, T:Hashable {
    public let results: [DiffStep<T>]
    public var insertions: [DiffStep<T>] {
        return results.filter({ $0.isInsertion }).sorted { $0.idx < $1.idx }
    }
    public var deletions: [DiffStep<T>] {
        return results.filter({ !$0.isInsertion }).sorted { $0.idx > $1.idx }
    }
    
    /// Get the three types of operations in order to convert one array into another. This is an alternative, more costly, but more detailed variant of just using insertions and deletions.
    public var operations: (moves: [DiffStep<T>], insertions: [DiffStep<T>], deletions: [DiffStep<T>]){
        var insertions = self.insertions
        var deletions = self.deletions
        var moves = [DiffStep<T>]()
        
        var insertionsByType = Dictionary<T, DiffStep<T>>()
        for insertion in insertions {
            insertionsByType[insertion.value] = insertion
        }
        
        var deletionsToRemove = [DiffStep<T>]()
        for deletion in deletions {
            if let insertion = insertionsByType[deletion.value] {
                moves.append(DiffStep.move(from: deletion.idx, to: insertion.idx, insertion.value))
                insertionsByType.removeValue(forKey: insertion.value)
                insertions.remove(insertion)
                deletionsToRemove.append(deletion)
            }
        }
        
        for deletionToRemove in deletionsToRemove {
            deletions.remove(deletionToRemove)
        }
        
        moves = moves.sorted(by: { $0.idx < $1.idx })
        
        return (moves: moves, insertions: insertions, deletions: deletions)
    }
    
    public func reversed() -> Diff<T> {
        let reversedResults = self.results.reversed().map { (result: DiffStep<T>) -> DiffStep<T> in
            switch result {
            case .insert(let i, let j):
                return .delete(i, j)
            case .delete(let i, let j):
                return .insert(i, j)
            case .move(let from, let to, let j):
                return .move(from: to, to: from, j)
            }
        }
        return Diff<T>(results: reversedResults)
    }
}

public func +<T> (left: Diff<T>, right: DiffStep<T>) -> Diff<T> {
    return Diff<T>(results: left.results + [right])
}

/// These get returned from calls to Array.diff(). They represent insertions or deletions that need to happen to transform array a into array b.
public enum DiffStep<T> : CustomDebugStringConvertible, Equatable where T:Equatable, T:Hashable{
    case insert(Int, T)
    case delete(Int, T)
    case move(from: Int, to: Int, T)
    var isInsertion: Bool {
        switch(self) {
        case .insert:
            return true
        case .delete:
            return false
        case .move:
            return false
        }
    }
    public var debugDescription: String {
        switch(self) {
        case .insert(let i, let j):
            return "+\(j)@\(i)"
        case .delete(let i, let j):
            return "-\(j)@\(i)"
        case .move(let from, let to, let j):
            return "-\(j)@\(from)+\(j)@\(to)"
        }
    }
    public var idx: Int {
        switch(self) {
        case .insert(let i, _):
            return i
        case .delete(let i, _):
            return i
        case .move(_, let to, _):
            return to
        }
    }
    public var value: T {
        switch(self) {
        case .insert(let j):
            return j.1
        case .delete(let j):
            return j.1
        case .move(let j):
            return j.2
        }
    }
    
    public var from: Int {
        switch(self) {
        case .insert, .delete:
            return idx
        case .move(let from, _, _):
            return from
        }
    }
    
    public var to: Int {
        switch(self) {
        case .insert, .delete:
            return idx
        case .move(_, let to, _):
            return to
        }
    }
}


public func ==<T> (left : DiffStep<T>, right : DiffStep<T>) -> Bool {
    return left.idx == right.idx //&& left.value == right.value
}

public extension Array where Element: Equatable, Element: Hashable {
    
    /// Returns the sequence of ArrayDiffResults required to transform one array into another.
    public func diff(_ other: [Element]) -> Diff<Element> {
        let table = MemoizedSequenceComparison.buildTable(self, other, self.count, other.count)
        return Array.diffFromIndices(table, self, other, self.count, other.count)
    }
    
    /// Walks back through the generated table to generate the diff.
    fileprivate static func diffFromIndices(_ table: [[Int]], _ x: [Element], _ y: [Element], _ i: Int, _ j: Int) -> Diff<Element> {
        if i == 0 && j == 0 {
            return Diff<Element>(results: [])
        } else if i == 0 {
            return diffFromIndices(table, x, y, i, j-1) + DiffStep.insert(j-1, y[j-1])
        } else if j == 0 {
            return diffFromIndices(table, x, y, i - 1, j) + DiffStep.delete(i-1, x[i-1])
        } else if table[i][j] == table[i][j-1] {
            return diffFromIndices(table, x, y, i, j-1) + DiffStep.insert(j-1, y[j-1])
        } else if table[i][j] == table[i-1][j] {
            return diffFromIndices(table, x, y, i - 1, j) + DiffStep.delete(i-1, x[i-1])
        } else {
            return diffFromIndices(table, x, y, i-1, j-1)
        }
    }
    
    /// Applies a generated diff to an array. The following should always be true:
    /// Given x: [T], y: [T], x.apply(x.diff(y)) == y
    public func apply(_ diff: Diff<Element>) -> Array<Element> {
        var copy = self
        for result in diff.deletions {
            copy.remove(at: result.idx)
        }
        for result in diff.insertions {
            copy.insert(result.value, at: result.idx)
        }
        return copy
    }
    
}

public extension Array where Element: Equatable {
    
    /// Returns the longest common subsequence between two arrays.
    public func LCS(_ other: [Element]) -> [Element] {
        let table = MemoizedSequenceComparison.buildTable(self, other, self.count, other.count)
        return Array.lcsFromIndices(table, self, other, self.count, other.count)
    }
    
    /// Walks back through the generated table to generate the LCS.
    fileprivate static func lcsFromIndices(_ table: [[Int]], _ x: [Element], _ y: [Element], _ i: Int, _ j: Int) -> [Element] {
        if i == 0 || j == 0 {
            return []
        } else if x[i-1] == y[j-1] {
            return lcsFromIndices(table, x, y, i - 1, j - 1) + [x[i - 1]]
        } else if table[i-1][j] > table[i][j-1] {
            return lcsFromIndices(table, x, y, i - 1, j)
        } else {
            return lcsFromIndices(table, x, y, i, j - 1)
        }
    }
    
}

internal struct MemoizedSequenceComparison<T: Equatable> {
    static func buildTable(_ x: [T], _ y: [T], _ n: Int, _ m: Int) -> [[Int]] {
        var table = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        for i in 0...n {
            for j in 0...m {
                if (i == 0 || j == 0) {
                    table[i][j] = 0
                }
                else if x[i-1] == y[j-1] {
                    table[i][j] = table[i-1][j-1] + 1
                } else {
                    table[i][j] = max(table[i-1][j], table[i][j-1])
                }
            }
        }
        return table
    }
}
