//
//  Activity.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 7/3/16.
//  Copyright © 2016 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import CoreLock

final class LockActivityItem: NSObject {
    
    static let excludedActivityTypes = [UIActivityTypePrint,
                                     UIActivityTypeAssignToContact,
                                     UIActivityTypeAirDrop,
                                     UIActivityTypeCopyToPasteboard,
                                     UIActivityTypeSaveToCameraRoll,
                                     UIActivityTypePostToFlickr]
    
    let identifier: UUID
    
    init(identifier: UUID) {
        
        self.identifier = identifier
    }
    
    // MARK: - Activity Values
    
    var text: String {
        
        guard let lockCache = Store.shared[cache: identifier]
            else { fatalError("Lock not in cache") }
        
        return "I unlocked my door \"\(lockCache.name)\" with Cerradura"
    }
    
    var image: UIImage {
        
        guard let lockCache = Store.shared[cache: identifier]
            else { fatalError("Lock not in cache") }
        
        switch lockCache.permission {
            
        case .owner: return #imageLiteral(resourceName: "permissionBadgeOwner")
        case .admin: return #imageLiteral(resourceName: "permissionBadgeAdmin")
        case .anytime: return #imageLiteral(resourceName: "permissionBadgeAnytime")
        case .scheduled: return #imageLiteral(resourceName: "permissionBadgeScheduled")
        }
    }
}

/// `UIActivity` types
enum LockActivity: String {
    
    case newKey = "com.colemancda.cerradura.activity.newKey"
    case delete = "com.colemancda.cerradura.activity.delete"
    case rename = "com.colemancda.cerradura.activity.rename"
    case homeKitEnable = "com.colemancda.cerradura.activity.homeKitEnable"
}

/// Activity for sharing a key.
final class NewKeyActivity: UIActivity {
    
    override static func activityCategory() -> UIActivityCategory { return .action }
    
    private var item: LockActivityItem!
    
    override func activityType() -> String? {
        
        return LockActivity.newKey.rawValue
    }
    
    override func activityTitle() -> String? {
        
        return "Share Key"
    }
    
    override func activityImage() -> UIImage? {
        
        return #imageLiteral(resourceName: "activityNewKey")
    }
    
    override func canPerform(withActivityItems activityItems: [AnyObject]) -> Bool {
        
        guard let lockItem = activityItems.first as? LockActivityItem,
            let lockCache = Store.shared[cache: lockItem.identifier],
            let _ = LockManager.shared[lockItem.identifier] // Lock must be reachable
            else { return false }
        
        switch lockCache.permission {
            
        case .owner, .admin: return true
            
        default: return false
        }
    }
    
    override func prepare(withActivityItems activityItems: [AnyObject]) {
        
        self.item = activityItems.first as! LockActivityItem
    }
    
    override func activityViewController() -> UIViewController? {
        
        let navigationController = UIStoryboard(name: "NewKey", bundle: nil).instantiateInitialViewController() as! UINavigationController
        
        let destinationViewController = navigationController.viewControllers.first! as! NewKeySelectPermissionViewController
        
        destinationViewController.lockIdentifier = item.identifier
        
        destinationViewController.completion = { self.activityDidFinish($0) }
        
        return navigationController
    }
}

/// Activity for deleting the lock locally.
final class DeleteLockActivity: UIActivity {
    
    override static func activityCategory() -> UIActivityCategory { return .action }
    
    private var item: LockActivityItem!
    
    override func activityType() -> String? {
        
        return LockActivity.delete.rawValue
    }
    
    override func activityTitle() -> String? {
        
        return "Delete"
    }
    
    override func activityImage() -> UIImage? {
        
        return #imageLiteral(resourceName: "activityDelete")
    }
    
    override func canPerform(withActivityItems activityItems: [AnyObject]) -> Bool {
        
        return activityItems.first as? LockActivityItem != nil
    }
    
    override func prepare(withActivityItems activityItems: [AnyObject]) {
        
        self.item = activityItems.first as! LockActivityItem
    }
    
    override func activityViewController() -> UIViewController? {
        
        let alert = UIAlertController(title: NSLocalizedString("Confirmation", comment: "DeletionConfirmation"),
                                      message: "Are you sure you want to delete this key?",
                                      preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: { (UIAlertAction) in
            
            alert.dismiss(animated: true) { self.activityDidFinish(false) }
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete"), style: .destructive, handler: { (UIAlertAction) in
            
            Store.shared.remove(self.item.identifier)
            
            alert.dismiss(animated: true) { self.activityDidFinish(true) }
        }))
        
        return alert
    }
}

/// Activity for renaming a lock.
final class RenameActivity: UIActivity {
    
    override static func activityCategory() -> UIActivityCategory { return .action }
    
    private var item: LockActivityItem!
    
    override func activityType() -> String? {
        
        return LockActivity.rename.rawValue
    }
    
    override func activityTitle() -> String? {
        
        return "Rename"
    }
    
    override func activityImage() -> UIImage? {
        
        return #imageLiteral(resourceName: "activityRename")
    }
    
    override func canPerform(withActivityItems activityItems: [AnyObject]) -> Bool {
        
        return activityItems.first as? LockActivityItem != nil
    }
    
    override func prepare(withActivityItems activityItems: [AnyObject]) {
        
        self.item = activityItems.first as! LockActivityItem
    }
    
    override func activityViewController() -> UIViewController? {
        
        let alert = UIAlertController(title: "Rename",
                                      message: "Type a user friendly name for this lock.",
                                      preferredStyle: .alert)
        
        alert.addTextField { $0.text = Store.shared[cache: self.item.identifier]!.name }
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .`default`, handler: { (UIAlertAction) in
            
            Store.shared[cache: self.item.identifier]!.name = alert.textFields![0].text ?? ""
            
            alert.dismiss(animated: true) { self.activityDidFinish(true) }
            
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .destructive, handler: { (UIAlertAction) in
            
            alert.dismiss(animated: true) { self.activityDidFinish(false) }
        }))
        
        return alert
    }
}

/// Activity for enabling HomeKit.
final class HomeKitEnableActivity: UIActivity {
    
    override static func activityCategory() -> UIActivityCategory { return .action }
    
    private var item: LockActivityItem!
    
    override func activityType() -> String? {
        
        return LockActivity.homeKitEnable.rawValue
    }
    
    override func activityTitle() -> String? {
        
        return "Home Mode"
    }
    
    override func activityImage() -> UIImage? {
        
        return #imageLiteral(resourceName: "activityHomeKit")
    }
    
    override func canPerform(withActivityItems activityItems: [AnyObject]) -> Bool {
        
        guard let lockItem = activityItems.first as? LockActivityItem,
            let lockCache = Store.shared[cache: lockItem.identifier],
            let _ = LockManager.shared[lockItem.identifier] // Lock must be reachable
            where lockCache.permission == .owner
            else { return false }
        
        return true
    }
    
    override func prepare(withActivityItems activityItems: [AnyObject]) {
        
        self.item = activityItems.first as! LockActivityItem
    }
    
    override func activityViewController() -> UIViewController? {
        
        let lockItem = self.item!
        
        let alert = UIAlertController(title: "Home Mode",
                                      message: "Enable Home Mode on this device?",
                                      preferredStyle: .alert)
        
        func enableHomeKit(_ enable: Bool = true) {
            
            guard let (lockCache, keyData) = Store.shared[lockItem.identifier]
                else { alert.dismiss(animated: true) { self.activityDidFinish(false) }; return }
            
            async {
                
                do { try LockManager.shared.enableHomeKit(lockItem.identifier, key: (lockCache.keyIdentifier, keyData), enable: enable) }
                
                catch { mainQueue { alert.showErrorAlert("\(error)"); self.activityDidFinish(false) }; return }
                
                mainQueue { alert.dismiss(animated: true) { self.activityDidFinish(true) } }
            }
        }
            
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: { (UIAlertAction) in
                        
            alert.dismiss(animated: true) { self.activityDidFinish(false) }
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: "Yes"), style: .`default`, handler: { (UIAlertAction) in
            
            enableHomeKit()
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: "No"), style: .`default`, handler: { (UIAlertAction) in
            
            enableHomeKit(false)
        }))
        
        return alert
    }
}