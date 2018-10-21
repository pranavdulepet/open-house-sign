//original
//  ViewController.swift
//  place_open_house_sign
//
//  Created by Pranav on 10/20/18.
//  Copyright © 2018 Pranav. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

class Destination: NSObject {
    
    let name: String
    let location: CLLocationCoordinate2D
    let zoom: Float
    
    init(name: String, location: CLLocationCoordinate2D, zoom: Float) {
        self.name = name
        self.location = location
        self.zoom = zoom
    }
    
}

class ViewController: UIViewController {
    
    var mapView: GMSMapView?
    
    var currentDestination: Destination?
    
    var destinations = Array<Destination>()
    
    @IBOutlet weak var addressSearch: UITextField!
    @IBOutlet weak var tblPlaces: UITableView!
    var resultsArray:[Dictionary<String, AnyObject>] = Array()
    var homeLatitude: Double = 37.764336
    var homeLongitude: Double = -121.907431
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addressSearch.addTarget(self, action: #selector(searchPlaceFromGoogle(_:)), for: .editingChanged)
        
        updateMap()
        
        // used for initial testing purpose only. Will be dynamically populated
        //initDestinations()
        
        // for testing purpose only
        //addIntersection(latitude: homeLatitude, longitude: homeLongitude)
   
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(nextButton))
    }
    
    @objc func nextButton() {
        
        if currentDestination == nil {
            currentDestination = destinations.first
        } else {
            if let index = destinations.index(of: currentDestination!), index < destinations.count - 1 {
                currentDestination = destinations[index + 1]
            }
        }
        
        setMapCamera()
    }

    @objc func searchPlaceFromGoogle(_ textField:UITextField) {
        
        if let searchQuery = textField.text {
            var strGoogleApi = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=\(searchQuery)&key=AIzaSyBdTPVqXGRr63fJ82-uKDirFIO-lFBenx0"
            strGoogleApi = strGoogleApi.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            
            var urlRequest = URLRequest(url: URL(string: strGoogleApi)!)
            urlRequest.httpMethod = "GET"
            let task = URLSession.shared.dataTask(with: urlRequest) { (data, resopnse, error) in
                if error == nil {
                    
                    if let responseData = data {
                        let jsonDict = try? JSONSerialization.jsonObject(with: responseData, options: .mutableContainers)
                        
                        if let dict = jsonDict as? Dictionary<String, AnyObject>{
                            
                            if let results = dict["results"] as? [Dictionary<String, AnyObject>] {
                                //print("json == \(results)")
                                if (results.count > 0) {
                                    self.resultsArray.removeAll()
                                    for dct in results {
                                        self.resultsArray.append(dct)
                                    }
                                
                                    let place = self.resultsArray[0]
                                    if let locationGeometry = place["geometry"] as? Dictionary<String, AnyObject> {
                                        if let location = locationGeometry["location"] as? Dictionary<String, AnyObject> {
                                            if let latitude = location["lat"] as? Double {
                                                if let longitude = location["lng"] as? Double {
                                                    //print("latitude == \(latitude)")
                                                    //print("longitude == \(longitude)")
                                                    self.homeLatitude = latitude
                                                    self.homeLongitude = longitude
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                    }
                } else {
                    //we have error connection google api
                }
            }
            task.resume()
            self.destinations.removeAll()
            self.currentDestination = nil
            updateMap()
            print(destinations.count)
            addIntersection(latitude: homeLatitude, longitude: homeLongitude)
            addIntersections(latitude: homeLatitude, longitude: homeLongitude)
        }
    }

    
    private func addIntersection(latitude: Double, longitude: Double) {
        
        var strGeoNamesFindNearestIntersectionApi = "http://api.geonames.org/findNearestIntersectionOSMJSON?lat=\(latitude)&lng=\(longitude)&username=sdulepet"
        strGeoNamesFindNearestIntersectionApi = strGeoNamesFindNearestIntersectionApi.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        var urlRequest = URLRequest(url: URL(string: strGeoNamesFindNearestIntersectionApi)!)
        urlRequest.httpMethod = "GET"
    
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if error == nil {
                
                if let responseData = data {
                    let jsonDict = try? JSONSerialization.jsonObject(with: responseData, options: .mutableContainers)
                    
                    if let dict = jsonDict as? Dictionary<String, AnyObject>{
                        
                        if let intersection = dict["intersection"] {
                            
                            if (intersection.count > 0) {
                                if let latitude = intersection["lat"] as? String {
                                    if let longitude = intersection["lng"] as? String {
                                        //print("Intersection latitude == \(latitude)")
                                        //print("Intersection longitude == \(longitude)")
                             
                                        // add dynamically to destinations
                                        self.addDestination(name: "Sign 1", latitude: (latitude as NSString).doubleValue, longitude: (longitude as NSString).doubleValue, zoom: 16)
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                //we have error connection geonames api
            }
        }
        task.resume()
        
    }
    
    private func addIntersections(latitude: Double, longitude: Double) {
        
        var strGeoNamesFindNearbyStreetsApi = "http://api.geonames.org/findNearbyStreetsOSMJSON?lat=\(latitude)&lng=\(longitude)&username=sdulepet"
        strGeoNamesFindNearbyStreetsApi = strGeoNamesFindNearbyStreetsApi.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        var urlRequest = URLRequest(url: URL(string: strGeoNamesFindNearbyStreetsApi)!)
        urlRequest.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if error == nil {
                
                if let responseData = data {
                    let jsonDict = try? JSONSerialization.jsonObject(with: responseData, options: .mutableContainers)
                    
                    if let jsondict = jsonDict as? Dictionary<String, AnyObject>{
                        
                        if let streetSegment = jsondict as? Dictionary<String, AnyObject>{
                            
                            var index = 2;
                            for (key, value) in jsondict {
                                for (key, value) in streetSegment {
                                    
                                    if let streetArray:[ [String : Any] ] = value as? [ [String : Any] ] {
                                        for dict in streetArray {
                                            for (key, value) in dict {
                                                if (key == "line") {
                                                    
                                                    let listItems = "\(value)".split(separator: ",")
                                                    let firstListItems = "\(listItems[0])".split(separator: " ")
                                                    //print("\(firstListItems)")
                                                    //print("\(firstListItems[0])")
                                                    //print("\(firstListItems[1])")
                                                    let longitude = firstListItems[0]
                                                    let latitude = firstListItems[1]
                                                    self.addDestination(name: "Sign " + String(index), latitude: (latitude as NSString).doubleValue, longitude: (longitude as NSString).doubleValue, zoom: 16)
                                                    index =  index + 1
                                                
                                                }
                                            }
                                            
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                //we have error connection geonames api
            }
        }
        task.resume()
        
    }
    
    private func updateMap() {
        
        let camera = GMSCameraPosition.camera(withLatitude: self.homeLatitude, longitude: self.homeLongitude, zoom: 12)
        mapView = GMSMapView.map(withFrame: CGRect .zero, camera: camera)
        view = mapView
        
        let currentLocation = CLLocationCoordinate2DMake(self.homeLatitude, self.homeLongitude)
        let marker = GMSMarker(position: currentLocation)
        marker.title = "Home"
        marker.map = mapView
    }
    
    private func setMapCamera() {
        
        CATransaction.begin()
        CATransaction.setValue(1, forKey: kCATransactionAnimationDuration)
        mapView?.animate(to: GMSCameraPosition.camera(withTarget: currentDestination!.location, zoom: currentDestination!.zoom))
        CATransaction.commit()
        
        let marker = GMSMarker(position: currentDestination!.location)
        marker.title = currentDestination?.name
        marker.map = mapView
    }
    
    private func addDestination(name: String, latitude: Double, longitude: Double, zoom: Float) {
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let destination = Destination(name: name, location: location, zoom: zoom)
        self.destinations.append(destination)
    }

    // used for testing
    private func initDestinations() {
        
        self.addDestination(name: "Dougherty Valley High School", latitude: 37.769406, longitude: -121.902379, zoom: 15)
        
        self.addDestination(name: "Windmere Ranch Middle School", latitude: 37.752670, longitude: -121.906024, zoom: 15)
        
        self.addDestination(name: "Live Oak Elementery School", latitude: 37.754656, longitude: -121.894472, zoom: 15)
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
