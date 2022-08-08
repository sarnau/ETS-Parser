//
//  AppDelegate.swift
//  KNX_Monitor
//
//  Created by Markus Fritze on 27.09.21.
//

import Cocoa
import SwiftKeychainWrapper
import SwiftPrettyPrint

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Pretty.sharedOption = Pretty.Option(indentSize: 4)

        do {
            // The filename and path (currently ~/Library/CloudStorage/OneDrive-Personal need to be adjusted!
            let filename = "Home.knxproj"
//			KeychainWrapper.standard.set("<<PASSWORD>>", forKey: "knxProjectPassword")
            if let password: String = KeychainWrapper.standard.string(forKey: "knxProjectPassword") {
                let libraryDirectoryURL = try FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let cloudUrl = libraryDirectoryURL.appendingPathComponent("CloudStorage/OneDrive-Personal")
                let fileUrl = cloudUrl.appendingPathComponent(filename)
                let knxProject = try ETSLoadProject(url: fileUrl, password: password)
                Pretty.prettyPrint(knxProject)
            }
            NSApp.terminate(self)
        } catch {
            print("\(error)")
        }
    }
}
