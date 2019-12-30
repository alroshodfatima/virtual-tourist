//
//  PhotoAlbumTableViewController.swift
//  VirtualTourist
//
//  Created by Fatimah on 02/05/1441 AH.
//  Copyright © 1441 Fatimah. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class PhotoAlbumTableViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var context: NSManagedObjectContext {
        return DataController.shared.viewContext
    }
    var fetchedResultsController: NSFetchedResultsController<Photo>?
    
    // MARK: Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadData()
        
        if fetchedResultsController?.fetchedObjects?.count == 0 {
            fetchPhotosURL()
        }
    }
    
    func loadData() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", DataController.shared.pin!)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "url", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController?.delegate = self
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: Custom functions
    func fetchPhotosURL() {
        
        ClientAPI.shared.getPhotos(latitude: DataController.shared.pin!.latitude.description, longitude: DataController.shared.pin!.longitude.description) { (photosURL, error) in
            if error != nil {
                self.showFailure(message: error!.localizedDescription)
                return
            }
            if photosURL.count != 0 {
                self.addPhotosUrlForPin(photosURL)
            } else {
                self.showFailure(message: "Please try again")
            }
        }
    }
    
    func addPhotosUrlForPin(_ photosURL: [String]) {
        for photoURL in photosURL {
            let photoInstance = Photo(context: context)
            photoInstance.url = photoURL
            photoInstance.pin = DataController.shared.pin
            do {
                try context.save()
            } catch {
                showFailure(message: error.localizedDescription)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let selectedPhoto = sender as? Photo
        DataController.shared.photo = selectedPhoto
    }
}

extension PhotoAlbumTableViewController: UITableViewDataSource, UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController?.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoTableViewCell")!
        cell.imageView?.image = image(UIImage(data: (fetchedResultsController?.object(at: indexPath).image)!)!, withSize: CGSize(width: 70, height: 70))
        cell.setNeedsLayout()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let photo = fetchedResultsController?.object(at: indexPath)
        performSegue(withIdentifier: "showNote", sender: photo)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func image( _ image:UIImage, withSize newSize:CGSize) -> UIImage {
        
        UIGraphicsBeginImageContext(newSize)
        image.draw(in: CGRect(x: 0,y: 0,width: newSize.width,height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!.withRenderingMode(.automatic)
    }
}

extension PhotoAlbumTableViewController:NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
            break
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            break
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
}
