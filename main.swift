//
//  main.swift
//  Musicord
//
//  Created by Chiphyr on 28/12/2019.
//  Copyright © 2019 Elitis. All rights reserved.
//

import Foundation
import ScriptingBridge
import SwordRPC

print("Musicord by Chiphyr\nNotice: Presences may take a while to update. It could take as long as 15 seconds after one/two messages are logged saying the presence has been sent for it to appear in Discord.\n")

@objc protocol iTunesApplication {
    @objc optional func currentTrack() -> AnyObject
    @objc optional var properties: Dictionary<String, Any> { get }
    @objc optional func playerPosition() -> Double
}

class PresenceManager {
    var appName: String
    var appID: String
    var rpc: SwordRPC
    var times: Int = 0
    var previousPos: Double = 0
    
    func continueLoop(repeats: Bool) {
        if repeats {
            sleep(15)
            self.updatePresence(repeats: true)
        }
    }
    
    func updatePresence(repeats: Bool = true) {
        if let iTunesApp: AnyObject = SBApplication(bundleIdentifier: self.appName) {
            let track = iTunesApp.currentTrack!().properties as Dictionary<String, Any>
            
            if (track.count != 0) {
                let now = Date().timeIntervalSince1970
                let playerPos = iTunesApp.playerPosition()
                let start = now - playerPos
                
                if self.previousPos == playerPos {
                    var presence = RichPresence()
                    presence.details           = "⏸"
                    presence.assets.largeImage = "itunes"
                    presence.assets.largeText  = "github.com/elitisgroup/Musicord"
                    
                    self.rpc.setPresence(presence)
                    return self.continueLoop(repeats: repeats)
                }
                self.previousPos = playerPos
                
                var presence = RichPresence()
                presence.details           = track["name"] as! String
                presence.state             = "by " + (track["artist"] as! String)
                presence.timestamps.start  = Date(timeIntervalSince1970: start)
                presence.assets.largeImage = "itunes"
                presence.assets.largeText  = "github.com/elitisgroup/Musicord"
                
                self.times += 1
                print("[INFO] [\(self.times)] Sending " + (track["name"] as! String) + " by " + (track["artist"] as! String) + " to Discord")
                self.rpc.setPresence(presence)
            } else {
                print("[INFO] Nothing is playing.")
            }
        } else {
            print("App with name \(self.appName) could not be interfaced with. Possibly you didn't give permission?")
        }
        
        self.continueLoop(repeats: repeats)
    }
    
    init(appName: String, appID: String = "660599896080121888") {
        self.rpc = SwordRPC(appId: appID)
        self.appID = appID
        self.appName = appName;
        self.rpc.connect()
        self.rpc.onConnect { _ in
            print("[INFO] Connected to Discord")
        }
        
        self.updatePresence(repeats: true)
    }
}

let osVersion = ProcessInfo.processInfo.operatingSystemVersion
print("[DEBUG] OS version detected to be \(osVersion.majorVersion).\(osVersion.minorVersion)")
var appName = "com.apple.iTunes"
if osVersion.minorVersion >= 15 {
    appName = "com.apple.Music"
}
let presenceMan = PresenceManager(appName: appName, appID: "660599896080121888")
