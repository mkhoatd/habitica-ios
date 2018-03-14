//
//  RealmFlags.swift
//  Habitica Database
//
//  Created by Phillip Thelen on 09.03.18.
//  Copyright © 2018 HabitRPG Inc. All rights reserved.
//

import Foundation
import RealmSwift
import Habitica_Models

@objc
class RealmFlags: Object, FlagsProtocol {
    @objc dynamic var armoireEmpty: Bool = false
    @objc dynamic var cronCount: Int = 0
    @objc dynamic var rebirthEnabled: Bool = false
    @objc dynamic var communityGuidelinesAccepted: Bool = false
    @objc dynamic var hasNewStuff: Bool = false
    @objc dynamic var armoireOpened: Bool = false
    @objc dynamic var chatRevoked: Bool = false
    @objc dynamic var classSelected: Bool = false
    
    @objc dynamic var id: String?
    override static func primaryKey() -> String {
        return "id"
    }
    
    convenience init(id: String?, flags: FlagsProtocol) {
        self.init()
        self.id = id
        armoireEmpty = flags.armoireEmpty
        cronCount = flags.cronCount
        rebirthEnabled = flags.rebirthEnabled
        communityGuidelinesAccepted = flags.communityGuidelinesAccepted
        hasNewStuff = flags.hasNewStuff
        armoireOpened = flags.armoireOpened
        chatRevoked = flags.chatRevoked
        classSelected = flags.classSelected
    }
}
