//
//  Delta.swift
//  Momenta
//
//  Created by Alexander Griekspoor on 22/07/16.
//  Copyright © 2016 Momenta BV. All rights reserved.

import Foundation
import Dwifft

public struct Delta<T> where T:Equatable, T:Identifiable {
    let before : [T]
    let after : [T]
    let diff : Diff<String>
    
    var insertions = [IndexPath]()
    var deletions  = [IndexPath]()
    var moves = [(from: IndexPath, to: IndexPath)]()
    var updates = [IndexPath]()
    
    init () {
        fatalError("Use init(before:after:) instead.")
    }
    
    init (before: [T], after: [T], sectionIndex: Int = 0) {
        self.before = before
        self.after = after
        
        let beforeUUIDs = before.map { $0.uuid }
        let afterUUIDs = after.map { $0.uuid }
        diff = beforeUUIDs.diff(afterUUIDs)
        
        let operations = diff.operations
        
        var indicesToIgnore = Set<Int>()
        insertions = operations.insertions.map {
            indicesToIgnore.insert($0.idx)
            return IndexPath(item: $0.idx, section: sectionIndex)
        }
        
        deletions = operations.deletions.map {
            return IndexPath(item: $0.idx, section: sectionIndex)
        }
        
        moves = operations.moves.map {
            if before[$0.from] != after[$0.to] {
                updates.append(IndexPath(item: $0.idx, section: sectionIndex))
            }
            indicesToIgnore.insert($0.idx)
            return (from: IndexPath(item: $0.from, section: sectionIndex),  to: IndexPath(item: $0.to, section: sectionIndex))
        }
                
        for (idx, item) in after.enumerated() {
            if indicesToIgnore.contains(idx) { continue }
            let oldIndex = beforeUUIDs.index(of: item.uuid)! // TODO: use a dictionary instead
            if before[oldIndex] != item {
                updates.append(IndexPath(item: idx, section: sectionIndex))
            }
        }
    }
}

    

