//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Fatimah on 06/04/1441 AH.
//  Copyright © 1441 Fatimah. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: Outlets & Variables
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var pin: Pin?
    var context: NSManagedObjectContext {
        return DataController.shared.viewContext
    }
    var fetchedResultsController: NSFetchedResultsController<Photo>?
    
    // MARK: Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let space:CGFloat = 2.0
        let widthDimension = (view.frame.size.width - (2 * space)) / 4.0
        let heightDimension = (view.frame.size.height - (2 * space)) / 4.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: widthDimension, height: heightDimension)
        
        loadData()
        
        if fetchedResultsController?.fetchedObjects?.count == 0 {
            fetchPhotosURL()
        }
        
        let coordinates = CLLocationCoordinate2D(latitude: pin!.latitude, longitude: pin!.longitude)
        
        let region = MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        self.mapView.addAnnotation(annotation)
        
        DispatchQueue.main.async{
            self.mapView.alpha = 1.0
            self.mapView.setRegion(region, animated: true)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
        collectionView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    // MARK: Custom functions
    func fetchPhotosURL() {
        
        ClientAPI.shared.getPhotos(latitude: pin!.latitude.description, longitude: pin!.longitude.description) { (photosURL, error) in
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
            photoInstance.pin = pin
            do {
                try context.save()
            } catch {
                showFailure(message: error.localizedDescription)
            }
        }
    }
    
    func loadData() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin!)
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
    
    func showFailure(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "OK", style: .default) { (action) in
        }
        alert.addAction(dismissAction)
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: Actions
    @IBAction func resetPhotoCollectionButton(_ sender: Any) {
        for photos in (fetchedResultsController?.fetchedObjects)! {
            context.delete(photos)
        }
        do {
            try context.save()
        } catch {
            showFailure(message: error.localizedDescription)
        }
        fetchPhotosURL()
        collectionView.reloadData()
    }
    
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController?.fetchedObjects?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        cell.imageView.image = nil
        
        let item = fetchedResultsController?.object(at: indexPath)
        if let imageData = item?.image {
            DispatchQueue.main.async {
                cell.activityIndicator.stopAnimating()
                cell.imageView.image = UIImage(data: imageData)
            }
        } else {
            if let imageUrl = item?.url {
                cell.activityIndicator.startAnimating()
                ClientAPI.shared.getPhotoByURL(urlString: imageUrl) { (data, error) in
                    if error != nil {
                        DispatchQueue.main.async {
                            cell.activityIndicator.stopAnimating()
                            self.showFailure(message: error!.localizedDescription)
                        }
                        return
                    }
                    if let data = data {
                        DispatchQueue.main.async {
                            cell.imageView.image = UIImage(data: data)
                            cell.activityIndicator.stopAnimating()
                        }
                        item?.image = data
                        do {
                            try self.context.save()
                        } catch {
                            self.showFailure(message: error.localizedDescription)
                        }
                    } else {
                        self.showFailure(message: "Sorry, there is a problem with the fetched photo.")
                    }
                }
            } else {
                showFailure(message: "Sorry, there is a problem with the URL.")
            }
        }
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController?.object(at: indexPath)
        context.delete(photoToDelete!)
        do {
            try context.save()
        } catch {
            showFailure(message: error.localizedDescription)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying: UICollectionViewCell, forItemAt: IndexPath) {
        
        if collectionView.cellForItem(at: forItemAt) == nil {
            return
        }
        
        let photo = fetchedResultsController?.object(at: forItemAt)
        if let imageUrl = photo?.url {
            ClientAPI.shared.cancelDownload(imageUrl)
        }
    }
    
}

extension PhotoAlbumViewController:NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            collectionView.insertItems(at: [newIndexPath!])
            break
        case .delete:
            collectionView.deleteItems(at: [indexPath!])
            break
        case .update:
            collectionView.reloadItems(at: [indexPath!])
        case .move:
            collectionView.moveItem(at: indexPath!, to: newIndexPath!)
        }
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.reloadData()
    }
    
}
