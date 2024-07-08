//
//  SharingManager.swift
//  Habitica
//
//  Created by Phillip Thelen on 17.08.20.
//  Copyright © 2020 HabitRPG Inc. All rights reserved.
//

import UIKit
#if !targetEnvironment(macCatalyst)
import SwiftUI
#endif
import Habitica_Models

class SharingManager {
    static func share(identifier: String, items: [Any], presentingViewController: UIViewController?, sourceView: UIView?) {
        guard let viewController = presentingViewController ?? UIApplication.topViewController() else {
            return
        }
        
        var sharedItems = [Any]()
#if !targetEnvironment(macCatalyst)
        for item in items {
            if let image = item as? UIImage, let newImage = addSharingBanner(inImage: image) {
                sharedItems.append(newImage)
            } else {
                sharedItems.append(item)
            }
        }
#endif
        let avc = UIActivityViewController(activityItems: sharedItems, applicationActivities: nil)
        avc.popoverPresentationController?.sourceView = sourceView ?? viewController.view
        viewController.present(avc, animated: true, completion: nil)
    }

    static func share(pet: AnimalProtocol, shareIdentifier: String = "pet") {
        var items: [Any] = []
        if #available(iOS 15.0, *) {
            items.append(StableBackgroundView(content: PetView(pet: pet)
                .padding(.top, 30), animateFlying: false)
            .frame(width: 300, height: 124)
            .snapshot())
        } else {
            items.append(PetView(pet: pet)
                .frame(width: 300, height: 124)
                .snapshot())
        }
        SharingManager.share(identifier: shareIdentifier, items: items, presentingViewController: nil, sourceView: nil)
    }
    
    static func share(mount: AnimalProtocol, shareIdentifier: String = "mount") {
        var items: [Any] = []
        if #available(iOS 15.0, *) {
            items.append(StableBackgroundView(content: MountView(mount: mount)
                .padding(.top, 30), animateFlying: false)
            .frame(width: 300, height: 124)
            .snapshot())
        } else {
            items.append(MountView(mount: mount)
                .frame(width: 300, height: 124)
                .snapshot())
        }
        SharingManager.share(identifier: shareIdentifier, items: items, presentingViewController: nil, sourceView: nil)
    }
    
    static func share(avatar: AvatarProtocol, shareIdentifier: String = "avatar") {
        let view = AvatarView(frame: CGRect(x: 0, y: 0, width: 140, height: 147))
        
        view.avatar = AvatarViewModel(avatar: avatar)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIGraphicsBeginImageContextWithOptions(view.bounds.size, true, UIScreen.main.scale)
            if let currentContext = UIGraphicsGetCurrentContext() {
                view.layer.render(in: currentContext)
                if let image = UIGraphicsGetImageFromCurrentImageContext() {
                    SharingManager.share(identifier: shareIdentifier, items: [image], presentingViewController: nil, sourceView: nil)
                }
                UIGraphicsEndImageContext()
            }
        }
    }
    
#if !targetEnvironment(macCatalyst)
    static func addSharingBanner(inImage image: UIImage) -> UIImage? {
        let bannerHeight: CGFloat = 18

        UIGraphicsBeginImageContextWithOptions(CGSize(width: image.size.width, height: image.size.height + bannerHeight), false, 1)
        if let context = UIGraphicsGetCurrentContext() {
            
            context.setFillColor(UIColor.white.cgColor)
            context.addRect(CGRect(origin: CGPoint.zero, size: image.size))
            context.drawPath(using: .fill)
            context.setFillColor(UIColor.purple300.cgColor)
            context.addRect(CGRect(origin: CGPoint(x: 0, y: image.size.height), size: CGSize(width: image.size.width, height: bannerHeight)))
            context.drawPath(using: .fill)
        
            image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))

            let logo = Asset.wordmarkWhite.image
            let height = bannerHeight - 4
            let width = logo.size.width / (logo.size.height / height)
            logo.draw(in: CGRect(x: image.size.width - width - 4, y: image.size.height + 2, width: width, height: height))
        }
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
    #endif
}
