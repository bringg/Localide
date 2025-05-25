//
//  LocalideMapApp.swift
//  Localide
//
//  Created by David Elsonbaty on 5/28/16.
//  Copyright © 2016 David Elsonbaty. All rights reserved.
//

import UIKit
import CoreLocation

@objc public enum LocalideMapApp: Int, CaseIterable {
    case appleMaps = 10
    case citymapper = 20
    case googleMaps = 30
    case navigon = 40
    case transitApp = 50
    case waze = 60
    case yandexNavigator = 70
    case copilot = 80

    public var appName: String {
        switch self {
        case .appleMaps:
            return "Apple Maps"
        case .citymapper:
            return "Citymapper"
        case .googleMaps:
            return "Google Maps"
        case .navigon:
            return "Navigon"
        case .transitApp:
            return "Transit App"
        case .waze:
            return "Waze"
        case .yandexNavigator:
            return "Yandex Navigator"
        case .copilot:
            return "CoPilot"
        }
    }

    static let AllMapApps: [LocalideMapApp] = LocalideMapApp.allCases
}

public enum LocalideUrlStringAppleMaps: String {
    case prefixesOld = "http://maps.apple.com/"
    case prefixesNew = "maps://"
}

// MARK: - Public Helpers
public extension LocalideMapApp {
    /**
     Checks whether it is possible to launch the app. (Installed & Added to QuerySchemes)
     - returns: Whether it is possible to launch the app.
     */
    func canOpenApp() -> Bool {
        guard let url = URL(string: LocalideMapApp.prefixes[self]!) else { return false }
        return LocalideMapApp.canOpenUrl(url)
    }
    
    func canNavigateByAddress() -> Bool {
        guard let _ = LocalideMapApp.addressUrlFormats[self] else {
            return false
        }
        
        return true
    }
    
    /**
     Launch app
     - returns: Whether the launch of the application was successful
     */
    func launchApp(byCoordinates:Bool = true, completionHandler: ((Bool) -> Void)? = nil) {
        
        if byCoordinates {
            LocalideMapApp.launchAppWithUrlString(LocalideMapApp.urlFormats[self]!, completionHandler: completionHandler)
        }else{
            // not all map apps can launch by address so fallback to normal url formats
            if let format = LocalideMapApp.addressUrlFormats[self] {
                LocalideMapApp.launchAppWithUrlString(format, completionHandler: completionHandler)
            }else{
                LocalideMapApp.launchAppWithUrlString(LocalideMapApp.urlFormats[self]!, completionHandler: completionHandler)
            }
        }
        
    }
    /**
     Launch app with directions to location
     - parameter location: Latitude & Longitude of the directions's TO location
     */
    func launchAppWithDirections(toLocation location: CLLocationCoordinate2D, completionHandler: ((Bool) -> Void)? = nil) {
        LocalideMapApp.launchAppWithUrlString(urlStringForDirections(toLocation: location), completionHandler: completionHandler)
    }
    
    
    func launchAppWithDirections(toAddress address: String, completionHandler: ((Bool) -> Void)? = nil) {
        let urlstring = urlStringForDirections(toAddress: address)
        if urlstring.isEmpty {
            completionHandler?(false)
            return
        }
        LocalideMapApp.launchAppWithUrlString(urlstring, completionHandler: completionHandler)
    }

    static func launchAppWithUrlString(_ urlString: String, completionHandler: ((Bool) -> Void)? = nil) {
        guard let launchUrl = URL(string: urlString) , canOpenUrl(launchUrl) else {
            completionHandler?(false)
            return
        }
        Localide.sharedManager.applicationProtocol.localideOpen(launchUrl, options: [:], completionHandler: completionHandler)
    }
    
    static func setupForAppleMapsFix(shouldUseAppleMapsHttpUrlScheme: Bool) {
        if shouldUseAppleMapsHttpUrlScheme {
            LocalideMapApp.prefixes[.appleMaps] = LocalideUrlStringAppleMaps.prefixesOld.rawValue
            LocalideMapApp.urlFormats[.appleMaps] = "http://maps.apple.com/?daddr=%f,%f"
            LocalideMapApp.addressUrlFormats[.appleMaps] = "http://maps.apple.com/?daddr=%@"
        } else {
            LocalideMapApp.prefixes[.appleMaps] = LocalideUrlStringAppleMaps.prefixesNew.rawValue
            LocalideMapApp.urlFormats[.appleMaps] = "maps://?daddr=%f,%f"
            LocalideMapApp.addressUrlFormats[.appleMaps] = "maps://?daddr=%@"
        }
    }

    static var prefixes: [LocalideMapApp: String] = [
        LocalideMapApp.appleMaps : "maps://",
        LocalideMapApp.citymapper : "citymapper://",
        LocalideMapApp.googleMaps : "comgooglemaps://",
        LocalideMapApp.navigon : "navigon://",
        LocalideMapApp.transitApp : "transit://",
        LocalideMapApp.waze : "waze://",
        LocalideMapApp.yandexNavigator : "yandexnavi://",
        LocalideMapApp.copilot : "copilot://"
    ]
}


// MARK: - Private Helpers
private extension LocalideMapApp {
    func urlStringForDirections(toLocation location: CLLocationCoordinate2D) -> String {
        return String(format: LocalideMapApp.urlFormats[self]!, arguments: [location.latitude, location.longitude])
    }
    
    func urlStringForDirections(toAddress address: String) -> String {
        
        guard let format = LocalideMapApp.addressUrlFormats[self] else {
            return ""
        }
        
        return String(format: format, arguments: [address])
    }
}

// MARK: - Private Static Helpers
private extension LocalideMapApp {

    static var urlFormats: [LocalideMapApp: String] = [
        LocalideMapApp.appleMaps : "http://maps.apple.com/?daddr=%f,%f",
        LocalideMapApp.citymapper : "citymapper://endcoord=%f,%f",
        LocalideMapApp.googleMaps : "comgooglemaps://?daddr=%f,%f",
        LocalideMapApp.navigon : "navigon://coordinate/Destination/%f/%f",
        LocalideMapApp.transitApp : "transit://routes?q=%f,%f",
        LocalideMapApp.waze : "waze://?ll=%f,%f",
        LocalideMapApp.yandexNavigator : "yandexnavi://build_route_on_map?lat_to=%f&lon_to=%f"
    ]
    
    static var addressUrlFormats: [LocalideMapApp: String] = [
        LocalideMapApp.appleMaps : "http://maps.apple.com/?daddr=%@",
        LocalideMapApp.citymapper : "citymapper://endaddress=%@",
        LocalideMapApp.googleMaps : "comgooglemaps://?daddr=%@&directionsmode=driving",
        LocalideMapApp.transitApp : "transit://directions?to=%@",
        LocalideMapApp.waze : "waze://?q=%@"
        //LocalideMapApp.navigon : "navigon://coordinate/Destination/%f/%f",
        //LocalideMapApp.yandexNavigator : "yandexnavi://build_route_on_map?lat_to=%f&lon_to=%f"
    ]

    static func canOpenUrl(_ url: URL) -> Bool {
        return Localide.sharedManager.applicationProtocol.canOpenURL(url)
    }
}
