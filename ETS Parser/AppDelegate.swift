//
//  AppDelegate.swift
//  ETS Parser
//
//  Created by Markus Fritze on 27.09.21.
//

import Cocoa
import CryptoSwift
import SwiftKeychainWrapper
import SwiftPrettyPrint

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        Pretty.sharedOption = Pretty.Option(indentSize: 4)

        do {
            //            KeychainWrapper.standard.set("<<PASSWORD>>", forKey: "knxProjectPassword")
            if let password: String = KeychainWrapper.standard.string(forKey: "knxProjectPassword") {
                let knxProject = try ETSLoadProject(url: URL(fileURLWithPath: filename), password: password)
                Pretty.prettyPrint(knxProject)
            }
            NSApp.terminate(self)
        } catch {
            print("\(error)")
        }
        return true
    }
}
