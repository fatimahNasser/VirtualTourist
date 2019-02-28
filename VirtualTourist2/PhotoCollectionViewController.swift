//
//  PhotoCollectionViewController.swift
//  VirtualTourist2
//
//  Created by ToOoMa on 2019-02-19.
//  Copyright © 2019 Fatimah. All rights reserved.
//

import UIKit
import CoreData
import MapKit
import Kingfisher

private let reuseIdentifier = "CollectionViewCell"

class PhotoCollectionViewController: UIViewController,MKMapViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photosCollection: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var dataStack = CoreDataStack.shared
    var numberOfPhotos: Int = 0
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var imageIDs = [String]()
    var pin: MKAnnotation?
    var pinData: Pin!
    var imageURLs = [String]()
    var images = [Image]()
    var fetchedResultsController: NSFetchedResultsController<Image>!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let width = floor(self.photosCollection.frame.size.width / 3)
        layout.itemSize = CGSize(width: width, height: width)
        photosCollection.collectionViewLayout = layout
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        photosCollection.delegate = self
        photosCollection.dataSource = self
        mapView.delegate = self
        flowLayout.estimatedItemSize = CGSize (width: 100, height: 100)
        
        updatePinData()
        fetch()
        if fetchedResultsController.fetchedObjects?.count == 0 {
            getFlickrPhotos()
        }
        
    }
    
    func fetch() {
        let fetchRequest: NSFetchRequest<Image> = Image.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let predicate = NSPredicate(format: "pin == %@", pinData)
        fetchRequest.predicate = predicate
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func updatePinData() {
    self.mapView.addAnnotation(pin!)
        self.mapView.region = MKCoordinateRegion (center: (pin?.coordinate)!, span: MKCoordinateSpan (latitudeDelta: 1, longitudeDelta: 1))
        photosCollection.reloadData()
    }

    func getFlickrPhotos() {
        
        let pictures = fetchedResultsController.fetchedObjects
        for picture in pictures! {
            CoreDataStack.shared.viewContext.delete(picture)
        }
        var n = 1
        while (n <= 10){
            FlickrAPI.sharedInstance().searchByLatLon(lat: (pin?.coordinate.latitude)!,lon: (pin?.coordinate.longitude)!){(response, error) in
                if error != nil {
                    let alert = UIAlertController(title: "Unable to load location photos", message: "No Photos Available", preferredStyle: .alert)
                    let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(action)
                    self.present(alert, animated:true)
                    return
                } else {
                    let picture = Image(context: CoreDataStack.shared.viewContext)
                    picture.id = Int16(n)
                    picture.imageID = response
                    picture.date = Date() as Date?
                    picture.pin = self.pinData
                }
            }
            n = n+1
        }
        try? CoreDataStack.shared.viewContext.save()
        

    }
    
    
    static func findPhoto(imageURL: URL) -> UIImage {
        let image = try! UIImage(data: Data(contentsOf: imageURL))
        return image!
    }
    
    
     func numberOfSections(in collectionView: UICollectionView) -> Int {
        return (fetchedResultsController.sections?.count) ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let locationPhoto = fetchedResultsController.object(at: indexPath)
        CoreDataStack.shared.viewContext.delete(locationPhoto)
        photosCollection.reloadData()
    }
    
     func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (fetchedResultsController.sections?[section].numberOfObjects) ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CollectionViewCell
        let pinPhoto = fetchedResultsController.object(at: indexPath)
        let source = ImageResource(downloadURL: URL(string: pinPhoto.imageID!)!)
        cell.imageView.kf.indicatorType = .activity
        cell.imageView?.kf.setImage(with: source)
        return cell
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        photosCollection.reloadData()
    }

    
    
    @IBAction func doneButton(_ sender: Any){
            self.dismiss(animated: true, completion: nil)
        }
    
    
    @IBAction func newPhotoCollectionButton(_ sender: Any) {
        
   //     memoryPhotos = [UIImage]()
        imageIDs = [String]()
        numberOfPhotos = 0
        imageURLs = [String]()
        
        let photoCollection = pinData?.images
        if photoCollection!.count != 0 {
            for image in photoCollection! {
                dataStack.persistentContainer.viewContext.delete(image as! NSManagedObject)
            }
        }
        
        
        photosCollection.reloadData()
        getFlickrPhotos()
    }
    
}
