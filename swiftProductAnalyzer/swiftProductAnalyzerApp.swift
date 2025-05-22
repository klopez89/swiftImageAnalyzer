//
//  swiftProductAnalyzerApp.swift
//  swiftProductAnalyzer
//
//  Created by Kevin Lopez on 5/22/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    FirebaseApp.configure()
  }
}

@main
struct swiftProductAnalyzerApp: App {
    // register app delegate for Firebase setup
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
