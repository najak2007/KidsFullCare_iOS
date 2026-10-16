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

        locationManager.requestWhenInUseAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true              // Background 업데이트 활성화
        locationManager.pausesLocationUpdatesAutomatically = false

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        realm = RealmManager.shared.realm

    }
    
    func requestWhenInUseAuthorization(locationDidChangeAuthorization: @escaping (CLAuthorizationStatus) -> Void) {
        locationManager.requestWhenInUseAuthorization()
        self.locationDidChangeAuthorization = locationDidChangeAuthorization

        self.locationDidChangeAuthorization?(locationManager.authorizationStatus)
    }
}

extension MapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
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
