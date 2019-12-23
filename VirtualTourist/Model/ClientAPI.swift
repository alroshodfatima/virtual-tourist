//
//  ClientAPI.swift
//  VirtualTourist
//
//  Created by Fatimah on 08/04/1441 AH.
//  Copyright © 1441 Fatimah. All rights reserved.
//

import Foundation
import CoreData

class ClientAPI {
    
    static let shared = ClientAPI()
    
    private var tasks: [String: URLSessionDataTask] = [:]
    
    struct Auth {
        static var apiKey = "4bd1856d77e50c2b5727a70d649b0d16"
        static var apiSecret = "ef9017d9be0b986e"
    }
    
    struct Flickr {
        static let apiScheme = "https"
        static let apiHost = "api.flickr.com"
        static let apiPath = "/services/rest/"
    }
    
    struct FlickrAPIValue {
        static let base = "https://www.flickr.com/services/rest/"
        static var method = "flickr.photos.search"
        static var format = "json"
        static var noJsonCallback = "1"
        static var lat = "0.0"
        static var lon = "0.0"
        static var perPage = "10"
    }
    
    enum FlickrAPIKey: String {
        case method
        case api_key
        case format
        case nojsoncallback
        case lat
        case lon
        case per_page //10
        case page
    }
    
    
    func getPhotos(latitude: String, longitude: String, completionHandler: @escaping ([String], Error?) -> Void) {
        
        taskForGETRequest(latitude: latitude, longitude: longitude, responseType: PhotoResponse.self) { (photos, error) in
            if error != nil {
                DispatchQueue.main.async {
                    completionHandler([], error)
                }
                return
            }
            guard let photos = photos else {
                DispatchQueue.main.async {
                    completionHandler([], error)
                }
                return
            }
            
            DispatchQueue.main.async {
                completionHandler(self.createPhotoURL(photos: photos.photos.photo),nil)
            }
        }
        
    }
    
    func taskForGETRequest<ResponseType: Decodable>(latitude: String, longitude: String, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) {
        
        var page: Int {
            let randomInt = Int.random(in: 1..<5)
            return randomInt
        }
        
        
        let parameters = [
            FlickrAPIKey.method.rawValue: FlickrAPIValue.method
            , FlickrAPIKey.api_key.rawValue: Auth.apiKey
            , FlickrAPIKey.format.rawValue: FlickrAPIValue.format
            , FlickrAPIKey.nojsoncallback.rawValue: FlickrAPIValue.noJsonCallback
            , FlickrAPIKey.lat.rawValue : latitude
            , FlickrAPIKey.lon.rawValue: longitude
            , FlickrAPIKey.per_page.rawValue: FlickrAPIValue.perPage
            , FlickrAPIKey.page.rawValue: "\(page)"
            ] as [String : String]
        
        let url = buildURL(items: parameters)
        let request = NSMutableURLRequest(url:url)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) { data, response, error in
            if error != nil {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }
    
    func taskForGETPhotoRequest(url: URL, completion: @escaping (Data?, Error?) -> Void) -> URLSessionDataTask {
        
        let request = URLRequest(url: url)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if error != nil {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(data, nil)
            }
        }
        task.resume()
        
        return task
    }
    
    func getPhotoByURL(urlString: String, completion: @escaping (Data?, Error?) -> Void) {
        
        let task = taskForGETPhotoRequest(url: URL(string: urlString)!) { (data, error) in
            completion(data, error)
            self.tasks.removeValue(forKey: urlString)
        }
        if tasks[urlString] == nil {
            tasks[urlString] = task
        }
    }
    
    func buildURL(items: [String: String]) -> URL {
        
        var components = URLComponents()
        components.scheme = Flickr.apiScheme
        components.host = Flickr.apiHost
        components.path = Flickr.apiPath
        components.queryItems = [URLQueryItem]()
        
        for (name, value) in items {
            let queryItem = URLQueryItem(name: name, value: value)
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    func createPhotoURL(photos: [PhotoObject]) -> [String]{
        var returnedURLs: [String] = []
        var builtURL: String
        for photo in photos {
            builtURL = "https://farm" + photo.farm.description + ".staticflickr.com/" + photo.server + "/" + photo.id + "_" + photo.secret + "_m.jpg"
            returnedURLs.append(builtURL)
        }
        return returnedURLs
    }
    
    func cancelDownload(_ imageUrl: String) {
        tasks[imageUrl]?.cancel()
    }
}
