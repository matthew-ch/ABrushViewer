//
//  AppDelegate.swift
//  ABrushViewer
//
//  Created by Matthew.J on 2022/11/18.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first, url.isFileURL else {
            return
        }
        guard let vc = NSApplication.shared.windows.first?.contentViewController as? ViewController else {
            return
        }
        vc.loadAbrFile(url: url)
    }


}

