//
//  RewardFormController.swift
//  Habitica
//
//  Created by Phillip on 23.08.17.
//  Copyright © 2017 HabitRPG Inc. All rights reserved.
//

import UIKit
import XLForm
import Habitica_Models

class RewardFormController: XLFormViewController {
    
    let managedObjectContext = HRPGManager.shared().getManagedObjectContext()
    
    var editReward = false
    var reward: TaskProtocol?
    
    lazy var tags: [Tag] = {
        let fetchRequest = NSFetchRequest<Tag>()
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: "Tag", in: HRPGManager.shared().getManagedObjectContext())
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        fetchRequest.fetchBatchSize = 20
        let tags = try? HRPGManager.shared().getManagedObjectContext().fetch(fetchRequest)
        return tags ?? [Tag]()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeForm()
        if editReward {
            fillEditForm()
        }
    }
    
    private func initializeForm() {
        let formDescriptor = XLFormDescriptor(title: NSLocalizedString("New Reward", comment: ""))
        formDescriptor.assignFirstResponderOnShow = true

        let rewardSection = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("Reward", comment: ""))
        formDescriptor.addFormSection(rewardSection)
        
        let textRow = XLFormRowDescriptor(tag: "text", rowType: XLFormRowDescriptorTypeText, title: NSLocalizedString("Text", comment: ""))
        textRow.isRequired = true
        rewardSection.addFormRow(textRow)
        
        let notesRow = XLFormRowDescriptor(tag: "notes", rowType: XLFormRowDescriptorTypeTextView, title: NSLocalizedString("Notes", comment: ""))
        rewardSection.addFormRow(notesRow)
        
        let valueRow = XLFormRowDescriptor(tag: "value", rowType: XLFormRowDescriptorTypeInteger, title: NSLocalizedString("Value", comment: ""))
        valueRow.isRequired = true
        rewardSection.addFormRow(valueRow)
        
        let tagsSection = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("Tags", comment: ""))
        formDescriptor.addFormSection(tagsSection)
        for tag in self.tags {
            tagsSection.addFormRow(XLFormRowDescriptor(tag: "tag.\(tag.id)", rowType: XLFormRowDescriptorTypeBooleanCheck, title: tag.name))
        }
        
        self.form = formDescriptor
    }
    
    private func fillEditForm() {
        self.navigationItem.title = NSLocalizedString("Edit Reward", comment: "")
        self.form.formRow(withTag: "text")?.value = self.reward?.text?.unicodeEmoji
        self.form.formRow(withTag: "notes")?.value = self.reward?.notes?.unicodeEmoji
        self.form.formRow(withTag: "value")?.value = self.reward?.value
        
        if let rewardTags = self.reward?.tags {
            for tag in rewardTags {
                self.form.formRow(withTag: "tag.\(tag.id)")?.value = true
            }
        }
        self.tableView.reloadData()
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if "unwindSaveSegue" == identifier, let validationErrors = self.formValidationErrors() as? [Error] {
            if validationErrors.count > 0 {
                showFormValidationError(validationErrors.first)
                return false
            }
        }
        
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }
    
    internal override func showFormValidationError(_ error: Error!) {
        let alertView = HabiticaAlertController(title: NSLocalizedString("Validation Error", comment: ""), message: error.localizedDescription)
        alertView.addOkAction()
        alertView.show()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "unwindSaveSegue" {
            let formValues = self.form.formValues()
            reward?.text = formValues["text"] as? String ?? ""
            reward?.notes = formValues["notes"] as? String ?? ""
            reward?.value = formValues["value"] as? Float ?? 0
        }
    }
}
