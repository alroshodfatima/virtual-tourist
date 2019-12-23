//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Fatimah on 06/04/1441 AH.
//  Copyright © 1441 Fatimah. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: Outlets & Variables
    @IBOutlet weak var mapView: MKMapView!
    
    var context: NSManagedObjectContext {
        return DataController.shared.viewContext
    }
    var fetchedResultsController: NSFetchedResultsController<Pin>?
    var long: Double?
    var lat: Double?
    var mapAnnotation: MKPointAnnotation? = nil
    
    
    // MARK: Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        navigationItem.rightBarButtonItem = editButtonItem
        loadData()
        showSavedPins()
    }
    
    // MARK: mapView Functions
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let annotation = view.annotation else {
            return
        }
        
        mapView.deselectAnnotation(annotation, animated: true)
        self.lat = annotation.coordinate.latitude
        self.long = annotation.coordinate.longitude
        
        let pin = fetchedResultsController?.fetchedObjects?.first(where: {
            $0.latitude == annotation.coordinate.latitude && $0.longitude == annotation.coordinate.longitude
        })
        performSegue(withIdentifier: "findLocationOnMap", sender: pin)
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let photoVC = segue.destination as! PhotoAlbumViewController
        let selectedPin = sender as? Pin
        photoVC.pin = selectedPin
        
    }
    
    // MARK: Custom functions
    func loadData() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController?.delegate = self
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            showFailure(message: error.localizedDescription)
        }
    }
    
    func savePin(longitude: Double, latitude: Double) {
        let pin = Pin(context: context)
        pin.longitude = longitude
        pin.latitude = latitude
        do {
            try context.save()
        } catch {
            showFailure(message: error.localizedDescription)
        }
    }
    
    func showSavedPins() {
        for pin in fetchedResultsController?.fetchedObjects ?? [] {
            let annotation = MKPointAnnotation()
            let lat = pin.latitude
            let lon = pin.longitude
            annotation.coordinate = CLLocationCoordinate2DMake(lat, lon)
            mapView.addAnnotation(annotation)
        }
        mapView.showAnnotations(mapView.annotations, animated: true)
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
    
    //MARK: Actions
    @IBAction func addPin(_ sender: UILongPressGestureRecognizer) {
        let location = sender.location(in: mapView)
        let locCoor = mapView.convert(location, toCoordinateFrom: mapView)
        
        if sender.state == .began {
            
            mapAnnotation = MKPointAnnotation()
            mapAnnotation!.coordinate = locCoor
            
            mapView.addAnnotation(mapAnnotation!)
            
        } else if sender.state == .changed {
            mapAnnotation!.coordinate = locCoor
        } else if sender.state == .ended {
            
            savePin(longitude: mapAnnotation!.coordinate.longitude, latitude: mapAnnotation!.coordinate.latitude)
        }
    }
}

extension MapViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        mapView.reloadInputViews()
    }
}
