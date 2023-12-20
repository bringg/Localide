//
//  Localide.swift
//  Localide
//
//  Created by David Elsonbaty on 5/28/16.
//  Copyright © 2016 David Elsonbaty. All rights reserved.
//

import UIKit
import CoreLocation

public typealias LocalideUsageCompletion = (_ usedApp: LocalideMapApp, _ fromMemory: Bool, _ openedLinkSuccessfully: Bool) -> Void

internal protocol UIApplicationProtocol {
    func openURL(_ url: URL) -> Bool
    func canOpenURL(_ url: URL) -> Bool
}

extension UIApplication: UIApplicationProtocol {}

public final class Localide: NSObject {

    public static let sharedManager: Localide = Localide()
    internal var applicationProtocol: UIApplicationProtocol = UIApplication.shared

    public var actionSheetTitleText: String?
    public var actionSheetMesaageText: String?
    public var actionSheetDismissText: String?


    public var subsetOfApps: [LocalideMapApp]?

    // Unavailable initializer, use sharedManager.
    fileprivate override init() {
        super.init()
    }

    /**
     Currently available map apps to launch. It includes:
     - Apple Maps
     - Installed 3rd party apps which are supported by Localide and included in the QuerySchemes
    */
    public var availableMapApps: [LocalideMapApp] { Localide.installedMapApps() }

    /**
     Reset the previously set user's map app preference
     */
    public func resetUserPreferences() {
        UserDefaults.resetMapAppPreferences()
    }

    /**
     Launch Apple Maps with directions to location
     - parameter location: Latitude & Longitude of the directions's TO location
     - returns: Whether the launch of the application was successfull
     */
    public func launchNativeAppleMapsAppForDirections(toLocation location: CLLocationCoordinate2D) -> Bool {
        return LocalideMapApp.appleMaps.launchAppWithDirections(toLocation: location)
    }

    /**
     Prompt user for their preferred maps app, and launch it with directions to location
     - parameter location: Latitude & Longitude of the direction's to location
     - parameter rememberPreference: Whether to remember the user's preference for future uses or not. (note: preference is reset whenever the list of available apps change. ex. user installs a new map app.)
     - parameter completion: Called after attempting to launch app whether it being from previous preference or currently selected preference.
     */
    public func promptForDirections(
        toLocation location: CLLocationCoordinate2D,
        rememberPreference remember: Bool = false,
        presentingViewController: UIViewController,
        customUrlsPerApp: [LocalideMapApp: String],
        onCompletion completion: LocalideUsageCompletion?
    ) {
        var appChoices = self.availableMapApps
        if let subsetOfApps = self.subsetOfApps {
            appChoices = subsetOfApps.filter({ self.availableMapApps.contains($0) })
            if appChoices.count == 0 {
                appChoices = [.appleMaps]
            }
        }

        guard !remember || !UserDefaults.didSetPrefferedMapApp(fromChoices: appChoices) else {
            let preferredMapApp = UserDefaults.preferredMapApp(fromChoices: appChoices)!
            launchApp(preferredMapApp, customUrlsPerApp: customUrlsPerApp, coordinates: location, fromMemory: true, completion: completion)
            return
        }

        self.discoverUserPreferenceOfMapApps(withTitle: self.actionSheetTitleText ?? "Navigation", message: self.actionSheetMesaageText ?? "Which app would you like to use for directions?", apps: appChoices, presentingViewController: presentingViewController) { app in
            if remember {
                UserDefaults.setPreferredMapApp(app, fromMapAppChoices: appChoices)
            }
            self.launchApp(app, customUrlsPerApp: customUrlsPerApp, coordinates: location, fromMemory: false, completion: completion)
        }
    }

    public func promptForDirections(
        toAddress address: String,
        fallbackCoordinates: CLLocationCoordinate2D,
        rememberPreference remember: Bool = false,
        presentingViewController: UIViewController,
        customUrlsPerApp: [LocalideMapApp: String],
        onCompletion completion: LocalideUsageCompletion?
    ) {
        var appChoices = self.availableMapApps
        if let subsetOfApps = self.subsetOfApps {
            appChoices = subsetOfApps.filter({ self.availableMapApps.contains($0) })
            if appChoices.count == 0 {
                appChoices = [.appleMaps]
            }
        }

        // for navigation by address we need to escape the address (if we cant we will just replace spaces with +)
        let escapedAddress = address.stringByAddingPercentEncodingForRFC3986() ?? address.replacingOccurrences(of: " ", with: "+")

        // some map apps currently dont support navigation by address - in this case fallback to "by-location" navigation
        guard !remember || !UserDefaults.didSetPrefferedMapApp(fromChoices: appChoices) else {
            let preferredMapApp = UserDefaults.preferredMapApp(fromChoices: appChoices)!
            self.launchApp(
                preferredMapApp,
                customUrlsPerApp: customUrlsPerApp,
                escapedAddress: escapedAddress,
                fallbackCoordinates: fallbackCoordinates,
                fromMemory: true,
                completion: completion
            )
            return
        }

        self.discoverUserPreferenceOfMapApps(withTitle: self.actionSheetTitleText ?? "Navigation", message: self.actionSheetMesaageText ?? "Which app would you like to use for directions?", apps: appChoices, presentingViewController: presentingViewController) { app in
            if remember {
                UserDefaults.setPreferredMapApp(app, fromMapAppChoices: appChoices)
            }
            self.launchApp(
                app,
                customUrlsPerApp: customUrlsPerApp,
                escapedAddress: escapedAddress,
                fallbackCoordinates: fallbackCoordinates,
                fromMemory: false,
                completion: completion
            )
        }
    }

    private func launchApp(
        _ app: LocalideMapApp,
        customUrlsPerApp: [LocalideMapApp: String],
        escapedAddress: String,
        fallbackCoordinates: CLLocationCoordinate2D,
        fromMemory: Bool,
        completion: LocalideUsageCompletion?
    ) {
        if app == .copilot {
            var openStatus: Bool = false
            if let urlString = customUrlsPerApp[app] {
                openStatus = LocalideMapApp.launchAppWithUrlString(urlString)
            } else if let copilotWithoutParams = LocalideMapApp.prefixes[app] {
                openStatus = LocalideMapApp.launchAppWithUrlString(copilotWithoutParams)
            }
            completion?(app, fromMemory, openStatus)
        } else {
            if app.canNavigateByAddress() {
                launchApp(app, withDirectionsToAddress: escapedAddress, fromMemory: fromMemory, completion: completion)
            }else{
                launchApp(app, withDirectionsToLocation: fallbackCoordinates, fromMemory: fromMemory, completion: completion)
            }
        }
    }

    private func launchApp(
        _ app: LocalideMapApp,
        customUrlsPerApp: [LocalideMapApp: String],
        coordinates: CLLocationCoordinate2D,
        fromMemory: Bool,
        completion: LocalideUsageCompletion?
    ) {
        if app == .copilot {
            var openStatus: Bool = false
            if let urlString = customUrlsPerApp[app] {
                openStatus = LocalideMapApp.launchAppWithUrlString(urlString)
            } else if let copilotWithoutParams = LocalideMapApp.prefixes[app] {
                openStatus = LocalideMapApp.launchAppWithUrlString(copilotWithoutParams)
            }
            completion?(app, fromMemory, openStatus)
        } else {
            launchApp(app, withDirectionsToLocation: coordinates, fromMemory: fromMemory, completion: completion)
        }
    }
}

// MARK: - Private Helpers
extension Localide {

    fileprivate class func installedMapApps() -> [LocalideMapApp] {
        return LocalideMapApp.AllMapApps.compactMap({ mapApp in
            return mapApp.canOpenApp() ? mapApp : nil
        })
    }

    fileprivate func launchApp(_ app: LocalideMapApp, withDirectionsToLocation location: CLLocationCoordinate2D, fromMemory: Bool, completion: LocalideUsageCompletion?) {
        let didLaunchMapApp = app.launchAppWithDirections(toLocation: location)
        completion?(app, fromMemory, didLaunchMapApp)
    }

    fileprivate func launchApp(_ app: LocalideMapApp, withDirectionsToAddress address: String, fromMemory: Bool, completion: LocalideUsageCompletion?) {
        let didLaunchMapApp = app.launchAppWithDirections(toAddress: address)
        completion?(app, fromMemory, didLaunchMapApp)
    }

    fileprivate func discoverUserPreferenceOfMapApps(withTitle title: String, message: String, apps: [LocalideMapApp], presentingViewController: UIViewController, completion: @escaping (LocalideMapApp) -> Void) {
        guard apps.count > 1 else {
            if let app = apps.first {
                completion(app)
            }
            return
        }

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

        for app in apps {
            let alertAction = UIAlertAction.localideAction(withTitle: app.appName, style: .default, handler: { _ in completion(app) })
            alertAction.mockMapApp = app
            alertController.addAction(alertAction)
        }

        let cancelAction = UIAlertAction(title: self.actionSheetDismissText ?? "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        presentingViewController.present(alertController, animated: true)
    }
}

extension String {
    func stringByAddingPercentEncodingForRFC3986() -> String? {
        let unreserved = "-._~/?"
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: unreserved)
        return self.addingPercentEncoding(withAllowedCharacters: allowed)
    }
}
