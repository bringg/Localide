//
//  LocalideTests.swift
//  LocalideTests
//
//  Created by David Elsonbaty on 5/30/16.
//  Copyright © 2016 David Elsonbaty. All rights reserved.
//

import XCTest
import CoreLocation
@testable import Localide

final class LocalideTests: XCTestCase {
    fileprivate let applicationProtocolTest = UIApplicationProtocolTest()
    let locationZero = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Localide.sharedManager.applicationProtocol = applicationProtocolTest
        Localide.sharedManager.resetUserPreferences()
        resetViewHierarchy()
    }

    func testAvailableMapApps() {
        XCTAssertEqual(Localide.sharedManager.availableMapApps, LocalideMapApp.AllMapApps)
    }

    func testLaunchNativeAppleMapsApp() {
        let location = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let completionExpectation = expectation(description: "Completion called")
        applicationProtocolTest.localideOpenUrlCalled = { url, options, completion in
            XCTAssertEqual(url.absoluteString, "http://maps.apple.com/?daddr=0.000000,0.000000")
            completion?(true)
        }
        Localide.sharedManager.launchNativeAppleMapsAppForDirections(toLocation: location) { success in
            XCTAssertTrue(success)
            completionExpectation.fulfill()
        }
        wait(for: [completionExpectation], timeout: 0.1)
        XCTAssertEqual(applicationProtocolTest.lastOpenedUrl, testDidLaunchApplication(.appleMaps))
    }

    func testPromptForDirectionsNoOptions() {
        Localide.sharedManager.subsetOfApps = []
        let completionExpectation = expectation(description: "Completion called")
        applicationProtocolTest.localideOpenUrlCalled = { url, options, completion in
            completion?(true)
            completionExpectation.fulfill()
        }
        Localide.sharedManager.promptForDirections(toLocation: locationZero, presentingViewController: UIViewController(), customUrlsPerApp: [:]) { (usedApp, fromMemory, openedLinkSuccessfully) in
            XCTAssertEqual(LocalideMapApp.appleMaps, usedApp)
            XCTAssertFalse(fromMemory)
            XCTAssertTrue(openedLinkSuccessfully)
            XCTAssertEqual(self.applicationProtocolTest.lastOpenedUrl, self.testDidLaunchApplication(usedApp))
        }
        wait(for: [completionExpectation], timeout: 0.1)
        XCTAssertNil(currentAlertActions())
        XCTAssertEqual(applicationProtocolTest.lastOpenedUrl, testDidLaunchApplication(.appleMaps))
    }

    func testPromptForDirectionsOneOption() {
        Localide.sharedManager.subsetOfApps = [.googleMaps]
        let completionExpectation = expectation(description: "Completion called")
        applicationProtocolTest.localideOpenUrlCalled = { url, options, completion in
            completion?(true)
            completionExpectation.fulfill()
        }
        Localide.sharedManager.promptForDirections(toLocation: locationZero, presentingViewController: UIViewController(), customUrlsPerApp: [:]) { (usedApp, fromMemory, openedLinkSuccessfully) in
            XCTAssertEqual(LocalideMapApp.googleMaps, usedApp)
            XCTAssertFalse(fromMemory)
            XCTAssertTrue(openedLinkSuccessfully)
            XCTAssertEqual(self.applicationProtocolTest.lastOpenedUrl, self.testDidLaunchApplication(usedApp))
        }
        wait(for: [completionExpectation], timeout: 0.1)
        XCTAssertNil(currentAlertActions())
        XCTAssertEqual(applicationProtocolTest.lastOpenedUrl, testDidLaunchApplication(.googleMaps))
    }

    func testPromptForDirectionsMutipleOptions() {
        resetViewHierarchy()

        var lastSelectedApp: LocalideMapApp?
        Localide.sharedManager.promptForDirections(
            toLocation: locationZero,
            presentingViewController: presentingViewController,
            customUrlsPerApp: [:]
        ) { usedApp, fromMemory, openedLinkSuccessfully in
            XCTAssertEqual(lastSelectedApp, usedApp)
            XCTAssertFalse(fromMemory)
            XCTAssertTrue(openedLinkSuccessfully)
            XCTAssertEqual(self.applicationProtocolTest.lastOpenedUrl, self.testDidLaunchApplication(usedApp))
        }

        let actions = currentAlertActions()!
        for action in actions {
            let applicationOpenUrlCalled = expectation(description: "Application - open url")
            applicationProtocolTest.localideOpenUrlCalled = { url, options, completionHandler in
                applicationOpenUrlCalled.fulfill()
                completionHandler?(true)
            }
            lastSelectedApp = action.mockMapApp
            action.mockHandler!(action)
            wait(for: [applicationOpenUrlCalled], timeout: 1)
        }

        resetViewHierarchy()
    }

//    func testPromptForDirectionsWithMemory() throws {
//        Localide.sharedManager.resetUserPreferences()
//        resetViewHierarchy()
//
//        applicationProtocolTest.localideOpenUrlCalled = { url, options, completion in
//            completion?(true)
//        }
//        var lastSelectedApp: LocalideMapApp?
//        Localide.sharedManager.promptForDirections(
//            toLocation: locationZero,
//            rememberPreference: true,
//            presentingViewController: presentingViewController,
//            customUrlsPerApp: [:]
//        ) { usedApp, fromMemory, openedLinkSuccessfully in
//            XCTAssertEqual(lastSelectedApp, usedApp)
//            XCTAssertFalse(fromMemory)
//            XCTAssertTrue(openedLinkSuccessfully)
//            XCTAssertEqual(self.applicationProtocolTest.lastOpenedUrl, self.testDidLaunchApplication(usedApp))
//        }
//
//        let actions = try XCTUnwrap(currentAlertActions())
//        for action in actions {
//            lastSelectedApp = action.mockMapApp
//            action.mockHandler!(action)
//        }
//
//        resetViewHierarchy()
//
//        let appFromMemory: LocalideMapApp = actions.last!.mockMapApp!
//        Localide.sharedManager.promptForDirections(
//            toLocation: locationZero,
//            rememberPreference: true,
//            presentingViewController: presentingViewController,
//            customUrlsPerApp: [:]
//        ) { usedApp, fromMemory, openedLinkSuccessfully in
//            XCTAssertEqual(appFromMemory, usedApp)
//            XCTAssertTrue(fromMemory)
//            XCTAssertTrue(openedLinkSuccessfully)
//            XCTAssertEqual(self.applicationProtocolTest.lastOpenedUrl, self.testDidLaunchApplication(usedApp))
//        }
//
//        XCTAssertNil(currentAlertActions())
//        XCTAssertEqual(applicationProtocolTest.lastOpenedUrl, testDidLaunchApplication(appFromMemory))
//    }

//    func testPromptForDirectionsWithMemoryAndChangeOfAvailability() throws {
//        Localide.sharedManager.resetUserPreferences()
//        resetViewHierarchy()
//
//        var lastSelectedApp: LocalideMapApp?
//    
//        applicationProtocolTest.localideOpenUrlCalled = { url, options, completion in
//            completion?(true)
//        }
//        let promptForDirections1Expectation = expectation(description: "promptForDirections1Expectation")
//        Localide.sharedManager.promptForDirections(
//            toLocation: locationZero,
//            rememberPreference: true,
//            presentingViewController: presentingViewController,
//            customUrlsPerApp: [:]
//        ) { usedApp, fromMemory, openedLinkSuccessfully in
//            XCTAssertEqual(lastSelectedApp, usedApp)
//            XCTAssertFalse(fromMemory)
//            XCTAssertTrue(openedLinkSuccessfully)
//            XCTAssertEqual(self.applicationProtocolTest.lastOpenedUrl, self.testDidLaunchApplication(usedApp))
//            promptForDirections1Expectation.fulfill()
//        }
//
//        wait(for: [promptForDirections1Expectation], timeout: 0.1)
//
//        let actions = try XCTUnwrap(currentAlertActions())
//        XCTAssertNotNil(actions)
//        for action in actions {
//            lastSelectedApp = action.mockMapApp
//            action.mockHandler!(action)
//        }
//
//        resetViewHierarchy()
//        Localide.sharedManager.subsetOfApps = [.googleMaps, .waze]
//        let promptForDirections2Expectation = expectation(description: "promptForDirections2Expectation")
//        Localide.sharedManager.promptForDirections(
//            toLocation: locationZero,
//            rememberPreference: true,
//            presentingViewController: presentingViewController,
//            customUrlsPerApp: [:]
//        ) { usedApp, fromMemory, openedLinkSuccessfully in
//            XCTAssertEqual(lastSelectedApp, usedApp)
//            XCTAssertFalse(fromMemory)
//            XCTAssertTrue(openedLinkSuccessfully)
//            XCTAssertEqual(self.applicationProtocolTest.lastOpenedUrl, self.testDidLaunchApplication(usedApp))
//            promptForDirections2Expectation.fulfill()
//        }
//
//        let actions2 = currentAlertActions()!
//        for action in actions2 {
//            lastSelectedApp = action.mockMapApp
//            action.mockHandler!(action)
//        }
//
//        XCTAssertTrue(actions2.count == 2)
//
//        wait(for: [promptForDirections2Expectation])
//    }

    // MARK: Private Helpers
    func resetViewHierarchy() {
        UIApplication.shared.keyWindow?.rootViewController = UIViewController()
    }

    func currentAlertActions() -> [LocalideAlertAction]? {
        guard let alertController = UIApplication.topViewController() as? UIAlertController else { return nil }
        let actions = alertController.actions
        let localideActions = actions.filter { alertAction -> Bool in
            return (alertAction as? LocalideAlertAction) != nil
        }
        return localideActions as? [LocalideAlertAction]
    }

    func testDidLaunchApplication(_ app: LocalideMapApp, toLocation location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)) -> String {
        return String(format: LocalideMapAppTestHelper.urlFormats[app]!, arguments: [location.latitude, location.longitude])
    }

    private var presentingViewController: UIViewController {
        return (UIApplication.shared.keyWindow?.rootViewController!)!
    }
}

// MARK: - Private Helpers
private class LocalideMapAppTestHelper {
    static let prefixes: [LocalideMapApp: String] = [
        LocalideMapApp.appleMaps : "http://maps.apple.com/",
        LocalideMapApp.citymapper : "citymapper://",
        LocalideMapApp.googleMaps : "comgooglemaps://",
        LocalideMapApp.navigon : "navigon://",
        LocalideMapApp.transitApp : "transit://",
        LocalideMapApp.waze : "waze://",
        LocalideMapApp.yandexNavigator : "yandexnavi://"
    ]
    static let urlFormats: [LocalideMapApp: String] = [
        LocalideMapApp.appleMaps : "http://maps.apple.com/?daddr=%f,%f",
        LocalideMapApp.citymapper : "citymapper://endcoord=%f,%f",
        LocalideMapApp.googleMaps : "comgooglemaps://?daddr=%f,%f",
        LocalideMapApp.navigon : "navigon://coordinate/Destination/%f/%f",
        LocalideMapApp.transitApp : "transit://routes?q=%f,%f",
        LocalideMapApp.waze : "waze://?ll=%f,%f",
        LocalideMapApp.yandexNavigator : "yandexnavi://build_route_on_map?lat_to=%f&lon_to=%f",
        LocalideMapApp.copilot : "copilot://"
    ]
}

private class UIApplicationProtocolTest: UIApplicationProtocol {
    var lastOpenedUrl: String = ""
    func canOpenURL(_ url: URL) -> Bool {
        return true
    }
    
    var localideOpenUrlCalled: ((URL, [UIApplication.OpenExternalURLOptionsKey : Any], ((Bool) -> Void)?) -> Void)?
    func localideOpen(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey : Any], completionHandler completion: ((Bool) -> Void)?) {
        lastOpenedUrl = url.absoluteString
        guard let localideOpenUrlCalled else {
            XCTFail("localideOpenUrlCalled should be set")
            return
        }
        localideOpenUrlCalled(url, options, completion)
    }
}

extension UIApplication {
    class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
//        if let nav = base as? UINavigationController {
//            return topViewController(base: nav.visibleViewController)
//        }
//        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
//            return topViewController(base: selected)
//        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
