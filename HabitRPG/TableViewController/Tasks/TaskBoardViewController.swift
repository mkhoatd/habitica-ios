//
//  TaskBoardViewController.swift
//  Habitica
//
//  Created by mkhoatd on 8/7/24.
//  Copyright © 2024 HabitRPG Inc. All rights reserved.
//

import Foundation
import UIKit
import Habitica_Models
import UniformTypeIdentifiers
import MobileCoreServices

class TaskBoardViewController: UIViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationController = segue.destination as? UINavigationController else {
                return
        }
        guard let formController = destinationController.topViewController as? TaskFormController else {
            return
        }
        guard let senderController = sender as? UIBarButtonItem else {
            return
        }
        switch senderController.title {
            case "Add habit":
                formController.taskType = .habit
            case "Add daily":
                formController.taskType = .daily
            case "Add todo":
                formController.taskType = .todo
            case "Add reward":
                formController.taskType = .reward
            default:
                return
        }
    }
}

