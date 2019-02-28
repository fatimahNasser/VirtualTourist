//
//  FlickrAPI.swift
//  VirtualTourist2
//
//  Created by ToOoMa on 2019-02-19.
//  Copyright © 2019 Fatimah. All rights reserved.
//

import Foundation


class FlickrAPI {
    var finalUrl:String = "No URl Yet"
    
    func searchByLatLon(lat: Double, lon: Double, completion: @escaping (String?, String?) -> Void){
        let methodParameters = [
            FlickrConstants.FlickrParameterKeys.Method: FlickrConstants.FlickrParameterValues.SearchMethod,
            FlickrConstants.FlickrParameterKeys.APIKey: FlickrConstants.FlickrParameterValues.APIKey,
            FlickrConstants.FlickrParameterKeys.BoundingBox: bboxString(lat: lat,lon: lon),
            FlickrConstants.FlickrParameterKeys.SafeSearch: FlickrConstants.FlickrParameterValues.UseSafeSearch,
            FlickrConstants.FlickrParameterKeys.Extras: FlickrConstants.FlickrParameterValues.MediumURL,
            FlickrConstants.FlickrParameterKeys.Format: FlickrConstants.FlickrParameterValues.ResponseFormat,
            FlickrConstants.FlickrParameterKeys.NoJSONCallback: FlickrConstants.FlickrParameterValues.DisableJSONCallback
        ]
        
        let pageLimit = min(1, 10)
        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
        
        var methodParametersWithPageNumber = methodParameters
        methodParametersWithPageNumber[FlickrConstants.FlickrParameterKeys.Page] = String(randomPage)
        
        // create session and request
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParameters as [String : AnyObject]))
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(_ error: String) {
                print(error)
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                completion(nil, "No data was found")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:AnyObject]
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            
            guard let photosDictionary = parsedResult[FlickrConstants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                displayError("Cannot find key '\(FlickrConstants.FlickrResponseKeys.Photos)' in \(String(describing: parsedResult))")
                return
            }
            
            guard let photosArray = photosDictionary[FlickrConstants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                displayError("Cannot find key '\(FlickrConstants.FlickrResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
            
            if photosArray.count == 0 {
                displayError("No Photos Found. Search Again.")
                return
            } else {
                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                
                let imageUrlString = (photoDictionary[FlickrConstants.FlickrResponseKeys.MediumURL] as? String)!
                if imageUrlString != "" {
                    self.finalUrl = imageUrlString
                }
                else{
                    print("No Key found for location image")
                }
            }
            
            DispatchQueue.main.async {
                completion(self.finalUrl, error as! String?)
            }
        }
        
        // start the task!
        task.resume()
        
        
    }
    
    
    private func bboxString(lat: Double, lon: Double) -> String {
        // ensure bbox is bounded by minimum and maximums
        let latitude = lat
        let longitude = lon
        let minimumLon = max(longitude - FlickrConstants.Flickr.SearchBBoxHalfWidth, FlickrConstants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - FlickrConstants.Flickr.SearchBBoxHalfHeight, FlickrConstants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + FlickrConstants.Flickr.SearchBBoxHalfWidth, FlickrConstants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + FlickrConstants.Flickr.SearchBBoxHalfHeight, FlickrConstants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        
    }
    
    
    //
    
    
    // MARK: Helper for Creating a URL from Parameters
    
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = FlickrConstants.Flickr.APIScheme
        components.host = FlickrConstants.Flickr.APIHost
        components.path = FlickrConstants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    class func sharedInstance() -> FlickrAPI {
        struct Singleton {
            static var sharedInstance = FlickrAPI()
        }
        return Singleton.sharedInstance
    }
    
    
    
}

