//
//  LazyQueue.swift
//  Images
//
//  Created by Jakub Charvat on 23.11.2020.
//


struct LazyQueue<T> {
    private var queue   : [T]       = []
    var getNextItems    : () -> [T] = { [] }
    var noNextItems     : () -> ()  = { }
    
    init(_ sequence: [T], getNextItems: (() -> [T])? = nil, noNextItems: (() -> ())? = nil) {
        queue.append(contentsOf: sequence)
        if let gni = getNextItems {
            self.getNextItems = gni
        }
        if let nni = noNextItems {
            self.noNextItems = nni
        }
    }
    
    init (getNextItems: (() -> [T])? = nil, noNextItems: (() -> ())? = nil) {
        if let gni = getNextItems {
            self.getNextItems = gni
        }
        if let nni = noNextItems {
            self.noNextItems = nni
        }
    }
}


//MARK: - Dequeue First
extension LazyQueue {
    mutating func dequeueFirst() -> T? {
        if !canDequeue {
            queue.append(contentsOf: getNextItems())
            
            if !canDequeue {
                noNextItems()
                return nil
            }
        }
        
        return queue.removeFirst()
    }
    
    var canDequeue: Bool { !queue.isEmpty }
}


//MARK: - Enqueue
extension LazyQueue {
    mutating func enqueue(_ newElement: T) {
        queue.append(newElement)
    }
    
    mutating func enqueue(contentsOf sequence: [T]) {
        queue.append(contentsOf: sequence)
    }
}


//MARK: - Shove to First Place
extension LazyQueue {
    mutating func shoveToFirstPlace(_ item: T) {
        queue.insert(item, at: 0)
    }
}
