//
//  OpenInTerminal.swift
//
//  Created by Daniel Bonates on 8/16/16.
//  Copyright © 2016 Daniel Bonates. All rights reserved.
//

import AppKit

var sharedPlugin: OpenInTerminal?

class OpenInTerminal: NSObject {

    var bundle: NSBundle
    lazy var center = NSNotificationCenter.defaultCenter()

    // MARK: - Initialization

    class func pluginDidLoad(bundle: NSBundle) {
        let allowedLoaders = bundle.objectForInfoDictionaryKey("me.delisa.XcodePluginBase.AllowedLoaders") as! Array<String>
        if allowedLoaders.contains(NSBundle.mainBundle().bundleIdentifier ?? "") {
            sharedPlugin = OpenInTerminal(bundle: bundle)
        }
    }

    init(bundle: NSBundle) {
        self.bundle = bundle

        super.init()
        // NSApp may be nil if the plugin is loaded from the xcodebuild command line tool
        if (NSApp != nil && NSApp.mainMenu == nil) {
            center.addObserver(self, selector: #selector(self.applicationDidFinishLaunching), name: NSApplicationDidFinishLaunchingNotification, object: nil)
        } else {
            initializeAndLog()
        }
    }

    private func initializeAndLog() {
        let name = bundle.objectForInfoDictionaryKey("CFBundleName")
        let version = bundle.objectForInfoDictionaryKey("CFBundleShortVersionString")
        let status = initialize() ? "loaded successfully" : "failed to load"
        NSLog("🔌 Plugin \(name) \(version) \(status)")
    }

    func applicationDidFinishLaunching() {
        center.removeObserver(self, name: NSApplicationDidFinishLaunchingNotification, object: nil)
        initializeAndLog()
    }

    // MARK: - Implementation

    func initialize() -> Bool {
        guard let mainMenu = NSApp.mainMenu else { return false }
        guard let item = mainMenu.itemWithTitle("Edit") else { return false }
        guard let submenu = item.submenu else { return false }
        
        
        let actionMenuItem = NSMenuItem(title:"Open in Terminal", action:#selector(self.doMenuAction), keyEquivalent:"")
        actionMenuItem.target = self
        
        submenu.addItem(NSMenuItem.separatorItem())
        submenu.addItem(actionMenuItem)
        
        return true
    }
    
    func doMenuAction() {
        
        guard let anyClass = NSClassFromString("IDEWorkspaceWindowController") as? NSObject.Type,
            let windowControllers = anyClass.valueForKey("workspaceWindowControllers") as? [NSObject] ,
            let window = NSApp.keyWindow ?? NSApp.windows.first else {
                Swift.print("Failed to establish workspace path")
                return
        }
        
        
        var workspace: NSObject?
        for controller in windowControllers {
            if controller.valueForKey("window")?.isEqual(window) == true {
                workspace = controller.valueForKey("_workspace") as? NSObject
            }
        }
        
        guard let workspacePath = workspace?.valueForKeyPath("representingFilePath._pathString") as? NSString else {
            Swift.print("Failed to establish workspace path")
            return
        }
        
        let task = NSTask()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "open -a /Applications/Utilities/Terminal.app \(workspacePath.stringByDeletingLastPathComponent)"]
        //let pipe = NSPipe()
        //task.standardOutput = pipe
        //task.standardError = pipe
        task.launch()
        task.waitUntilExit()
        //let data = pipe.fileHandleForReading.readDataToEndOfFile()
        //let output: String = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
        //showAlert("Terminal Opened", text: output)
        
        
    }
    
    func showAlert(question: String, text: String) -> Bool {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = question
        myPopup.informativeText = text
        myPopup.alertStyle = .InformationalAlertStyle
        myPopup.addButtonWithTitle("OK")
        let res = myPopup.runModal()
        if res == NSAlertFirstButtonReturn {
            return true
        }
        return false
    }
}

