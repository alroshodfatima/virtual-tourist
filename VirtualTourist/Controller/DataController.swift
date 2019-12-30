//
//  DataController.swift
//  VirtualTourist
//
//  Created by Fatimah on 06/04/1441 AH.
//  Copyright © 1441 Fatimah. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    let persistentContainer:NSPersistentContainer
    static let shared = DataController()
    
    var viewContext:NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    var pin: Pin?
    var photo: Photo?
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "VirtualTourist")
    }
    
    func configureContexts() {
        viewContext.automaticallyMergesChangesFromParent = true
        
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.autoSaveViewContext()
            self.configureContexts()
            completion?()
        }
    }
}

extension DataController {
    func autoSaveViewContext(interval:TimeInterval = 30) {
        
        guard interval > 0 else {
            return
        }
        
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
}
