//
//  RewardViewDataSource.swift
//  Habitica
//
//  Created by Phillip Thelen on 16.05.18.
//  Copyright © 2018 HabitRPG Inc. All rights reserved.
//

import Foundation
import Habitica_Models

class RewardViewDataSource: BaseReactiveCollectionViewDataSource<BaseRewardProtocol> {
    
    private let userRepository = UserRepository()
    private let taskRepository = TaskRepository()
    
    override init() {
        super.init()
        sections.append(ItemSection<BaseRewardProtocol>())
        sections.append(ItemSection<BaseRewardProtocol>())
        
        disposable.inner.add(taskRepository.getTasks(predicate: NSPredicate(format: "type == 'reward'")).on(value: { (tasks, changes) in
            self.sections[0].items = tasks
            self.notify(changes: changes)
        }).start())
        disposable.inner.add(userRepository.getInAppRewards().on(value: { (inAppRewards, changes) in
            self.sections[1].items = inAppRewards
            self.notify(changes: changes)
        }).start())
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if isCustomRewardsSection(indexPath.section) {
            return CGSize(width: self.collectionView?.frame.size.width ?? 0, height: 70)
        } else {
            return CGSize(width: 90, height: 120)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if isCustomRewardsSection(section) {
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            return UIEdgeInsets(top: 12, left: 6, bottom: 12, right: 6)
        }
    }
    
    func isCustomRewardsSection(_ section: Int) -> Bool {
        if let item = item(at: IndexPath(row: 0, section: section)) {
            if item as? TaskProtocol != nil {
                return true
            }
        }
        return false
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let reward = item(at: indexPath) as? TaskProtocol {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomRewardCell", for: indexPath)
            if let rewardCell = cell as? CustomRewardCell {
                rewardCell.configure(reward: reward)
                rewardCell.canAfford = reward.value < HRPGManager.shared().getUser().gold.floatValue
                rewardCell.onBuyButtonTapped = {
                    self.userRepository.buyCustomReward(reward: reward).observeCompleted {}
                }
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "InAppRewardCell", for: indexPath)
            if let rewardCell = cell as? InAppRewardCell, let reward = item(at: indexPath) as? InAppRewardProtocol {
                rewardCell.configure(reward: reward)
            }
            return cell
        }
    }
}
