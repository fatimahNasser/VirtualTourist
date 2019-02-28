//
//  MapViewController.swift
//  VirtualTourist2
//
//  Created by ToOoMa on 2019-02-19.
//  Copyright © 2019 Fatimah. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var dataStack = CoreDataStack.shared
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    var selected: MKAnnotation?
    var annotations: [MKAnnotation] = [MKAnnotation]()
    var pinData: Pin!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let addAnnotationRecognizer = UILongPressGestureRecognizer (target: self, action: #selector (MapViewController.addAnnotation(_:)))
        addAnnotationRecognizer.minimumPressDuration = 0.8
        mapView.addGestureRecognizer(addAnnotationRecognizer)
        fetchRequest()
        updateMapView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateMapView()
    }
    
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let defaults = UserDefaults.standard
        let region: [CLLocationDegrees] = [self.mapView.region.center.latitude, self.mapView.region.center.longitude, self.mapView.region.span.latitudeDelta, self.mapView.region.span.longitudeDelta]
        defaults.set(region, forKey: "MapView")
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reusedID = "pin"
        var pinAnnotation = mapView.dequeueReusableAnnotationView(withIdentifier: reusedID) as? MKPinAnnotationView
        
        if pinAnnotation == nil {
            pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reusedID)
            pinAnnotation!.animatesDrop = true
            pinAnnotation!.canShowCallout = false
            pinAnnotation!.pinTintColor = .blue
            
        } else {
            pinAnnotation!.annotation = annotation
        }
        return pinAnnotation
    }
    
    
    func mapView (_ mapView:MKMapView, didDeselect view: MKAnnotationView){
    }
    
    
    func mapView (_ mapView: MKMapView, didSelect view: MKAnnotationView){
        mapView.deselectAnnotation(view.annotation, animated: false)
        selected = view.annotation!
        for pin in fetchedResultsController.fetchedObjects ?? [] {
            if view.annotation?.coordinate.latitude == pin.latitude,
                view.annotation?.coordinate.longitude == pin.longitude {
                
                pinData = pin
                
                performSegue(withIdentifier: "dataList", sender: self)
            }
        }
    }
    
    
    @objc func addAnnotation(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == UIGestureRecognizer.State.began else {
            return
        }
        let pinPoint: CGPoint = gestureRecognizer.location(in: mapView)
        let pinCoordinate: CLLocationCoordinate2D = mapView.convert(pinPoint, toCoordinateFrom: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = pinCoordinate
        selected = annotation
        annotations.append(annotation)
        self.mapView.addAnnotation(annotation)
        
        let pin = Pin (context: (dataStack.persistentContainer.viewContext))
        pin.date = Date() as Date?
        pin.longitude = annotation.coordinate.longitude
        pin.latitude = annotation.coordinate.latitude
        pinData = pin
        try? CoreDataStack.shared.viewContext.save()
    }
    
    func updateMapView(){
        mapView.addAnnotations(annotations)
    }
    
    
    func fetchRequest() {
        let request: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor (key: "date", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController (fetchRequest: request, managedObjectContext: CoreDataStack.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            let pins = fetchedResultsController.fetchedObjects
            for pin in pins! {
                let annotation = MKPointAnnotation()
                annotation.coordinate.longitude = pin.longitude
                annotation.coordinate.latitude = pin.latitude
                mapView.addAnnotation(annotation)
                annotations.append(annotation)
            }
        } catch {
            fatalError("Could Not Perform FetchRequest: \(error.localizedDescription)")
            }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "dataList") {
            let photoCollectionController = segue.destination as? PhotoCollectionViewController
            photoCollectionController!.pin = self.selected
            photoCollectionController!.pinData = self.pinData
        }
    }
}


