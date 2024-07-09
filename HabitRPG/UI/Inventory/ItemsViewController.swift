//
//  ItemsViewController.swift
//  Habitica
//
//  Created by Phillip Thelen on 12.04.18.
//  Copyright © 2018 HabitRPG Inc. All rights reserved.
//

import UIKit
import Habitica_Models
import ReactiveSwift
import SwiftUI

class ItemsViewController: BaseTableViewController {
    
    private let dataSource = ItemsViewDataSource()
    
    @IBOutlet var cancelButton: UIBarButtonItem!
    
    private var isHatching = false {
        didSet {
			if !isPresentedModally {
                navigationItem.rightBarButtonItem = isHatching ? cancelButton : nil
			}
            dataSource.isHatching = isHatching
        }
    }
    var itemType: String?
    
    private let inventoryRepository = InventoryRepository()
    private let socialRepository = SocialRepository()
    private let userRepository = UserRepository()
    private var isPresentedModally = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cancelButton.title = L10n.cancel
        
        dataSource.tableView = tableView
        dataSource.itemType = itemType
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 68
        
        if (navigationController as? TopHeaderViewController) != nil {
			navigationItem.rightBarButtonItem = nil
            isPresentedModally = false
        } else {
            isPresentedModally = true
        }
    }
    
    override func applyTheme(theme: Theme) {
        super.applyTheme(theme: theme)
        tableView.backgroundColor = theme.contentBackgroundColor
    }
    
    override func populateText() {
        navigationItem.title = L10n.Titles.items
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = dataSource.item(at: indexPath)
        if isHatching {
            self.isHatching = false
            if let egg = dataSource.hatchingItem as? EggProtocol, let potion = item as? HatchingPotionProtocol {
                inventoryRepository.hatchPet(egg: egg, potion: potion).skipNil().observeValues { _ in
                }
            } else if let egg = item as? EggProtocol, let potion = dataSource.hatchingItem as? HatchingPotionProtocol {
                inventoryRepository.hatchPet(egg: egg, potion: potion).skipNil().observeValues { _ in
                }
            }
        } else if let item = item {
            showActionSheet(item: item, withSource: tableView.cellForRow(at: indexPath))
        } else {
            HabiticaAnalytics.shared.log("Items CTA tap", withEventProperties: [
                "eventCategory": "behaviour",
                "hitType": "event",
                "area": "empty",
                "type": dataSource.tableView(tableView, titleForHeaderInSection: indexPath.section) ?? ""])
            if indexPath.section < 3 {
                RouterHandler.shared.handle(.market)
            } else if indexPath.section == 3 {
                RouterHandler.shared.handle(.subscription)
            } else  if indexPath.section == 4 {
                RouterHandler.shared.handle(.questShop)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == (dataSource.numberOfSections(in: tableView) - 1) {
            return 170
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == (dataSource.numberOfSections(in: tableView) - 1) {
            let view = Bundle.main.loadNibNamed("ShopAdFooter", owner: self, options: nil)?.last as? UIView
            let iconView = (view?.viewWithTag(23) as? UIImageView)
            let titleLabel = (view?.viewWithTag(21) as? UILabel)
            let descriptionLabel = (view?.viewWithTag(22) as? UILabel)
            titleLabel?.textColor = ThemeService.shared.theme.primaryTextColor
            descriptionLabel?.textColor = ThemeService.shared.theme.secondaryTextColor
            let text: String
            if itemType == "quests" {
                if dataSource.visibleSections.first?.items.isEmpty == true {
                    return nil
                }
                iconView?.image = Asset.Empty.quests.image
                titleLabel?.text = L10n.Items.footerQuestsTitle
                text = L10n.Items.footerQuestsDescriptions
            } else {
                iconView?.image = Asset.shop.image
                titleLabel?.text = L10n.Items.footerTitle
                text = L10n.Items.footerDescription
            }
            let attributedText = NSMutableAttributedString(string: text)
            for shopName in [L10n.Locations.market, L10n.Locations.questShop] {
                let range = attributedText.mutableString.range(of: shopName, options: .caseInsensitive)
                if range.location != NSNotFound {
                    attributedText.addAttributes([NSAttributedString.Key.foregroundColor: ThemeService.shared.theme.tintColor], range: range)
                }
            }
            descriptionLabel?.attributedText = attributedText
            
            view?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openMarket)))
            return view
        } else {
            return nil
        }
    }
    
    @objc
    func openMarket() {
        HabiticaAnalytics.shared.log("Items CTA tap", withEventProperties: ["eventCategory": "behaviour",
                                                                            "hitType": "event",
                                                                            "area": "bottom"])
        RouterHandler.shared.handle(.market)
    }

    private func showActionSheet(item: ItemProtocol, withSource sourceView: UIView?) {
        var type = ""
        switch item.itemType {
        case "eggs":
            type = L10n.egg
        case "hatchingPotions":
            type = L10n.hatchingPotion
        case "food":
            type = L10n.food
        case "quests":
            type = L10n.quest
        default:
            break
        }
        let sheet = HostingBottomSheetController(rootView: BottomSheetMenu(Text("\(item.text ?? "") \(type)"), iconName: item.imageName) {
            if item.itemType == ItemType.eggs {
                BottomSheetMenuitem(title: L10n.hatchPotion) {[weak self] in
                    self?.dataSource.hatchingItem = item
                    self?.isHatching = true
                }
            } else if item.itemType == ItemType.hatchingPotions {
                BottomSheetMenuitem(title: L10n.hatchEgg) {[weak self] in
                    self?.dataSource.hatchingItem = item
                    self?.isHatching = true
                }
            } else if item.itemType == ItemType.quests {
                BottomSheetMenuitem(title: L10n.showDetails) {[weak self] in
                    if let quest = item as? QuestProtocol {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.showQuestDialog(quest: quest)
                        }
                    }
                }
                BottomSheetMenuitem(title: L10n.inviteParty) {[weak self] in
                    if let quest = item as? QuestProtocol {
                        self?.inventoryRepository.inviteToQuest(quest: quest)
                            .flatMap(.latest, { _ in
                                return self?.socialRepository.retrieveGroup(groupID: "party") ?? .empty
                            })
                            .observeCompleted {
                            self?.dismissIfNeeded()
                        }
                    }
                }
            }
            if item.key != "Saddle" && item.itemType != ItemType.quests && item.itemType != ItemType.special {
                BottomSheetMenuitem(title: HStack(spacing: 4) {
                    Text(L10n.sellNoCurrency(Int(item.value)))
                    Image(uiImage: HabiticaIcons.imageOfGold)
                }) {[weak self] in
                    self?.inventoryRepository.sell(item: item).observeCompleted {
                        self?.dismissIfNeeded()
                    }
                }
            }
            if item.key == "inventory_present" {
                BottomSheetMenuitem(title: L10n.open) {[weak self] in
                    self?.openMysteryItem()
                }
            }
            if item.key != "inventory_present" && item.itemType == ItemType.special {
                BottomSheetMenuitem(title: L10n.use) {[weak self] in
                    let navigationController = StoryboardScene.Main.spellUserNavigationController.instantiate()
                    self?.present(navigationController, animated: true, completion: {
                        let controller = navigationController.topViewController as? SkillsUserTableViewController
                        controller?.item = item
                    })
                }
            }
        })
        present(sheet, animated: true)
    }
    
    private func openMysteryItem() {
        inventoryRepository.openMysteryItem()
            .on(value: {[weak self] item in
                if let item = item {
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
                        self?.showMysteryitemDialog(item: item)
                    }
                }
            })
            .flatMap(.latest, {[weak self] _ in
                return self?.userRepository.retrieveUser(withTasks: false, forced: true) ?? Signal.empty
            })
            .observeCompleted {[weak self] in
            self?.dismissIfNeeded()
        }
    }
    
    private func dismissIfNeeded() {
        if isPresentedModally {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    private func showMysteryitemDialog(item: GearProtocol) {
        let imageAlert = ImageOverlayView(imageName: "shop_\(item.key ?? "")", title: L10n.openMysteryItem, message: nil)
        let text = NSMutableAttributedString(string: item.text ?? "")
        text.addAttribute(.font, value: UIFont.systemFont(ofSize: 16, weight: .semibold))
        text.addAttribute(.foregroundColor, value: ThemeService.shared.theme.primaryTextColor)
        let notes = NSMutableAttributedString(string: item.notes ?? "")
        notes.addAttribute(.font, value: UIFont.systemFont(ofSize: 14))
        notes.addAttribute(.foregroundColor, value: ThemeService.shared.theme.secondaryTextColor)
        imageAlert.attributedMessage = text + NSAttributedString(string: "\n\n") + notes
        imageAlert.addAction(title: L10n.equip, isMainAction: true) {[weak self] _ in
            self?.inventoryRepository.equip(type: "equipped", key: item.key ?? "").observeCompleted {}
        }
        imageAlert.addAction(title: L10n.close)
        imageAlert.arrangeMessageLast = true
        imageAlert.containerViewSpacing = 12
        imageAlert.imageHeight = 99
        imageAlert.enqueue()
    }

    private func showQuestDialog(quest: QuestProtocol) {
        let alertController = HabiticaAlertController(title: quest.text)
        alertController.contentViewInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        let detailView = QuestDetailView(frame: CGRect.zero)
        detailView.configure(quest: quest)
        detailView.translatesAutoresizingMaskIntoConstraints = false
        let imageView = NetworkImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .center

        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.isSelectable = false
        textView.attributedText = try? HabiticaMarkdownHelper.toHabiticaAttributedString(quest.notes ?? "")
//         try? HabiticaMarkdownHelper.toHabiticaAttributedStringAsync(quest.notes ?? "", onComplete: {str in
//             textView.setAttributedMarkedText(str, selectedRange: NSRange(location: 0, length: str?.length ?? 0))
//         })
        textView.font = UIFontMetrics.default.scaledSystemFont(ofSize: 14)
        textView.textColor = ThemeService.shared.theme.primaryTextColor
        textView.backgroundColor = ThemeService.shared.theme.contentBackgroundColor
        let stackView = UIStackView(arrangedSubviews: [imageView, detailView, textView])
        stackView.axis = .vertical
        stackView.spacing = 12
        ImageManager.getImage(name: "quest_" + (quest.key ?? "")) { (image, _) in
            imageView.image = image
            imageView.addHeightConstraint(height: image?.size.height ?? 0)
            imageView.updateConstraints()
            textView.addHeightConstraint(height: textView.sizeThatFits(CGSize(width: stackView.bounds.width, height: .infinity)).height)
            textView.updateConstraints()
            alertController.view.setNeedsLayout()
        }
        alertController.contentView = stackView
        alertController.addAction(title: L10n.inviteParty, style: .default, isMainAction: true) {[weak self] _ in
            self?.inventoryRepository.inviteToQuest(quest: quest)
                .flatMap(.latest, { _ in
                    return self?.socialRepository.retrieveGroup(groupID: "party") ?? .empty
                })
                .observeCompleted {
                self?.dismissIfNeeded()
            }
        }
        alertController.addCloseAction()
        alertController.show()
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
		isHatching = false
		dismissIfNeeded()
    }
    
    @IBAction override func unwindToListSave(_ segue: UIStoryboardSegue) {
        if segue.identifier == "CastUserSpellSegue" {
            guard let userViewController = segue.source as? SkillsUserTableViewController else {
                return
            }
            guard let item = userViewController.item as? SpecialItemProtocol else {
                return
            }
            userRepository.useTransformationItem(item: item, targetId: userViewController.selectedUserID ?? "").observeCompleted {}
        }
    }
}
