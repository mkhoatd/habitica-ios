//
//  HabiticaAnalytics.swift
//  Shared
//
//  Created by Phillip Thelen on 25.09.20.
//  Copyright © 2020 HabitRPG Inc. All rights reserved.
//

import Foundation
import Amplitude_iOS

public class HabiticaAnalytics {
    public static let shared = HabiticaAnalytics()
    
    public func setUserID(_ userID: String?) {
    }
    
    public func logNavigationEvent(_ pageName: String) {
        let properties = [
            "eventAction": "navigate",
            "eventCategory": "navigation",
            "hitType": "pageview",
            "page": pageName,
        ]
    }
    
    public func log(_ eventName: String, withEventProperties properties: [AnyHashable: Any]) {
    }
}
