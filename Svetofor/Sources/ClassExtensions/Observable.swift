//
//  Observable.swift
//  RealTimeFastStyleTransfer
//
//  Created by Dmytro Hrebeniuk on 8/6/17.
//  Copyright © 2017 Dmytro Hrebeniuk. All rights reserved.
//

import Foundation

class ObservableCompletion<T: Equatable>: Hashable {
    
    static func == (lhs: ObservableCompletion<T>, rhs: ObservableCompletion<T>) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    fileprivate let handler: (T) -> Void
    fileprivate weak var observable: Observable<T>?
    
    init(handler: @escaping (T) -> Void, observable: Observable<T>?) {
        self.handler = handler
        self.observable = observable
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    deinit {
        observable?.unSubscribe(observer: self)
    }
}

class Observable<T: Equatable> {
    
    private var observes = [ObservableCompletion<T>]()
    
    var value: T {
        didSet {
            let value = self.value
            for observe in observes {
                observe.handler(value)
            }
        }
    }
    
    init(value: T) {
        self.value = value
    }
    
    func subscribe(callOnSubscribe: Bool = false, handler: @escaping (T) -> Void) -> ObservableCompletion<T> {
        let observer = ObservableCompletion<T>(handler: handler, observable: self)
        self.observes.append(observer)
        
        if callOnSubscribe {
            observer.handler(value)
        }
        
        return observer
    }
    
    func unSubscribe(observer: ObservableCompletion<T>) {
        _ = self.observes.first { observer == $0 }.flatMap {
            self.observes.firstIndex(of: $0).flatMap { self.observes.remove(at: $0) }
        }
    }
}
