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
        
        
        
        do {
            realm = try RealmManager.shared.realm
        } catch {
            
        }
    }
    
    func requestWhenInUseAuthorization(locationDidChangeAuthorization: @escaping (CLAuthorizationStatus) -> Void) {
        locationManager.requestWhenInUseAuthorization()
        self.locationDidChangeAuthorization = locationDidChangeAuthorization

        self.locationDidChangeAuthorization?(locationManager.authorizationStatus)
    }
}
