//
//  MapViewModel.swift
//  KidsFullCare
//
//  Created by najak on 10/13/26.
//

import Foundation
import MapKit
import CoreLocation
import ActivityKit
import Combine
import RealmSwift
import SwiftUI

class MapViewModel: NSObject, ObservableObject {
    static let shared = MapViewModel()
    
    let mapView = MKMapView()
    var region: MKCoordinateRegion?
    
    let locationManager = CLLocationManager()
    private var realm: Realm?
    
    @Published var userLatitude: Double = 0
    @Published var userLongitude: Double = 0
    
    @Published var errorMessage: String?
    @Published var locationInfoDatas: [LocationInfoData] = []
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isNearByLocation: Bool = false
    
    var searchLocationPlace: UserPlaceInfoData? = nil
    var selectedLocationHandler: ((SearchLocationDataInfo, CLLocationCoordinate2D) -> Void)? = nil
    var locationDidChangeAuthorization: ((CLAuthorizationStatus) -> Void)? = nil
    
    @Environment(\.scenePhase) var scenePhase
    
    override init() {
        super.init()
        realm = RealmManager.shared.realm
    }
    
    func requestWhenInUseAuthorization(locationDidChangeAuthorization: @escaping (CLAuthorizationStatus) -> Void) {
        locationManager.requestWhenInUseAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true              // Background 업데이트 활성화
        locationManager.pausesLocationUpdatesAutomatically = false

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        self.locationDidChangeAuthorization = locationDidChangeAuthorization

        self.locationDidChangeAuthorization?(locationManager.authorizationStatus)
    }
    
    func convertAddressToGPS(documentID: String, address: String, studentInfoDic: [String: Any], completion: @escaping((Double, Double) -> Void)) {
        let geocoder = CLGeocoder()

        geocoder.geocodeAddressString(address.cleanAddress) { (placemarks: [CLPlacemark]?, error: Error?) in
            if let error = error {
#if DEBUG
                print("Geocoding 에러 발생: \(error.localizedDescription)")
#endif
                return completion(0, 0)
            }

            guard
                let location = placemarks?.first?.location
            else {
                return
            }

            let coordinate = location.coordinate
#if DEBUG
            print("변환 성공! 위도: \(coordinate.latitude), 경도: \(coordinate.longitude)")
#endif
            return completion(coordinate.latitude, coordinate.longitude)
        }
        completion(0, 0)
    }
    
    func updateLocationInfoData(studentInfoDic: [String: Any], latitude: Double, longitude: Double) {
        guard let _realm = realm,
              let locationId = studentInfoDic["UID"] as? String,
              let address = studentInfoDic["address"] as? String,
              let documentID = studentInfoDic["KEY"] as? String,
              let name = studentInfoDic["name"] as? String
        else {
            return
        }
        
        let results = _realm.objects(LocationInfoData.self)
        let locationList = Array(results)
        
        do {
            try _realm.write {
                guard let locationInfoData = locationList.filter( {$0.id == locationId} ).first
                else {
                    let _locationInfoData = LocationInfoData()
                    _locationInfoData.id = locationId
                    _locationInfoData.latitude = latitude
                    _locationInfoData.longitude = longitude
                    _locationInfoData.address = address
                    _locationInfoData.alias = documentID
                    _locationInfoData.name = name
                    _realm.add(_locationInfoData)
                    return
                }
                locationInfoData.address = address
                locationInfoData.latitude = latitude
                locationInfoData.longitude = longitude
                locationInfoData.alias = documentID
                locationInfoData.name = name
            }
        } catch {
            
        }
    }
    
    func getNearByLocationCheck(latitude: Double, longitude: Double) -> LocationInfoData? {
        guard let realm = realm
        else {
            return nil
        }
        
        let results = realm.objects(LocationInfoData.self)
        let locationLists = Array(results)
        
        if locationLists.count > 0 {
            for locationInfoData in locationLists {
                let distance: Double = getDistance(currentLatitude: latitude, currentLongitude: longitude, locationLatitude: locationInfoData.latitude, locationLongitude: locationInfoData.longitude)
                if distance < Config.NEARBY_DISTANCE {
                    return locationInfoData
                }
            }
        }
        return nil
    }
    
    func getNearByLocation(latitude: Double, longitude: Double) -> LocationInfoCheck? {
        guard let _realm = realm
        else {
            return nil
        }
        
        let results = _realm.objects(LocationInfoData.self)
        let locationLists = Array(results)
        
        if locationLists.count > 0 {
            for locationInfoData in locationLists {
                let distance: Double = getDistance(currentLatitude: latitude,
                                                   currentLongitude: longitude,
                                                   locationLatitude: locationInfoData.latitude,
                                                   locationLongitude: locationInfoData.longitude)
                if locationInfoData.isNearBy == false {
                    if distance < Config.NEARBY_DISTANCE {
                        return LocationInfoCheck(locationInfoData: locationInfoData, locationState: .들어옴)
                    }
                } else {
                    if distance > Config.NEARBY_DISTANCE * 2 {
                        return LocationInfoCheck(locationInfoData: locationInfoData, locationState: .나감)
                    }
                }
            }
        }
        return nil
    }
    
    private func setLocationOfIsNearByInit(locationInfoData: LocationInfoData? = nil, isNearBy: Bool = false) {
        guard let _realm = realm
        else {
            return
        }
        let results = _realm.objects(LocationInfoData.self)
        
        let locationLists = Array(results)
        
        do {
            try _realm.write {
                for locationData in locationLists {
                    locationData.isNearBy = false
                }
                if let _locationInfoData = locationInfoData {
                    let locationArr = locationLists.filter
                }
            }
        } catch {
            
        }
    }
    
    private func getDistance(currentLatitude: Double, currentLongitude: Double, locationLatitude: Double, locationLongitude: Double) -> Double {
        let currentLocation = CLLocation(latitude: currentLatitude, longitude: currentLongitude)
        let location = CLLocation(latitude: locationLatitude, longitude: locationLongitude)
        
        return currentLocation.distance(from: location)
    }
}

extension MapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last
        else {
            return
        }
        
        guard let resultPlaceInfo = self.getNearByLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        else {
            return
        }
        
        if resultPlaceInfo.locationState == .들어옴 {
            
        } else if resultPlaceInfo.locationState == .나감 {
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("")
        print("===============================")
        print("[ViewController > didFailWithError() : 위치 정보 확인 에러]")
        print("[error : \(error)]")
        print("[localizedDescription : \(error.localizedDescription)]")
        print("===============================")
        print("")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
    }
}
