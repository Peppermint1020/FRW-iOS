//
//  BackupManager.swift
//  Lilico
//
//  Created by Hao Fu on 2/1/22.
//

import FirebaseAuth
import Foundation
import GoogleAPIClientForREST_Drive
import GoogleAPIClientForRESTCore
import GoogleSignIn
import GTMSessionFetcherCore
import WalletCore

protocol BackupTarget {
    func uploadMnemonic(password: String) async throws
    func getCurrentDriveItems() async throws -> [BackupManager.DriveItem]
}

extension BackupManager {
    enum BackupType: Int {
        case icloud = 0
        case googleDrive
        case manual
        
        var descLocalizedString: String {
            switch self {
            case .icloud:
                return "icloud_drive".localized
            case .googleDrive:
                return "google_drive".localized
            case .manual:
                return "manually".localized
            }
        }
    }
    
    static let backupFileName = "outblock_backup"
}

extension BackupManager {
    class DriveItem: Codable {
        var username: String
        var uid: String?
        var data: String
        var version: String
        var time: String?
        
        init() {
            username = ""
            uid = ""
            data = ""
            version = ""
        }
    }
}

extension BackupManager {
    func uploadMnemonic(to type: BackupManager.BackupType, password: String) async throws {
        switch type {
        case .googleDrive:
            try await gdTarget.uploadMnemonic(password: password)
        case .icloud:
            try await iCloudTarget.uploadMnemonic(password: password)
        default:
            break
        }
        
        LocalUserDefaults.shared.backupType = type
    }
    
    func getCloudDriveItems(from type: BackupManager.BackupType) async throws -> [BackupManager.DriveItem] {
        switch type {
        case .googleDrive:
            return try await gdTarget.getCurrentDriveItems()
        case .icloud:
            return try await iCloudTarget.getCurrentDriveItems()
        default:
            return []
        }
    }
    
    func isExistOnCloud(_ type: BackupManager.BackupType) async throws -> Bool {
        guard let username = UserManager.shared.userInfo?.username else {
            return false
        }
        
        let items = try await getCloudDriveItems(from: type)
        for item in items {
            if item.username == username {
                return true
            }
        }
        
        return false
    }
}

class BackupManager: ObservableObject {
    static let shared = BackupManager()

    private let gdTarget = BackupGDTarget()
    private let iCloudTarget = BackupiCloudTarget()
}

// MARK: - Helper

extension BackupManager {
    /// append current user mnemonic to list with encrypt
    func addCurrentMnemonicToList(_ list: [BackupManager.DriveItem], password: String) throws -> [BackupManager.DriveItem] {
        guard let username = UserManager.shared.userInfo?.username, !username.isEmpty else {
            throw BackupError.missingUserName
        }
        
        guard let mnemonic = WalletManager.shared.getCurrentMnemonic(), !mnemonic.isEmpty, let mnemonicData = mnemonic.data(using: .utf8) else {
            throw BackupError.missingMnemonic
        }
        
        let dataHexString = try encryptMnemonic(mnemonicData, password: password)
        
        let existItem = list.first { item in
            item.username == username
        }
        
        if let existItem = existItem {
            existItem.version = "1"
            existItem.data = dataHexString
            return list
        }
        
        guard let uid = UserManager.shared.getUid(), !uid.isEmpty else {
            throw BackupError.missingUid
        }
        
        let item = BackupManager.DriveItem()
        item.username = username
        item.uid = uid
        item.version = "1"
        item.data = dataHexString
        
        var newList = [item]
        newList.append(contentsOf: list)
        return newList
    }
    
    /// encrypt list to hex string
    func encryptList(_ list: [BackupManager.DriveItem]) throws -> String {
        let jsonData = try JSONEncoder().encode(list)
        let encrypedData = try WalletManager.encryptionAES(key: LocalEnvManager.shared.backupAESKey, data: jsonData)
        return encrypedData.hexString
    }
    
    /// decrypt hex string to list
    func decryptHexString(_ hexString: String) throws -> [BackupManager.DriveItem] {
        guard let data = Data(hexString: hexString) else {
            throw BackupError.hexStringToDataFailed
        }
        
        return try decryptData(data)
    }
    
    private func decryptData(_ data: Data) throws -> [BackupManager.DriveItem] {
        let jsonData = try WalletManager.decryptionAES(key: LocalEnvManager.shared.backupAESKey, data: data)
        let list = try JSONDecoder().decode([BackupManager.DriveItem].self, from: jsonData)
        return list
    }
    
    /// encrypt mnemonic data to hex string
    func encryptMnemonic(_ mnemonicData: Data, password: String) throws -> String {
        let dataHexString = try WalletManager.encryptionAES(key: password, data: mnemonicData).hexString
        return dataHexString
    }
    
    /// decrypt hex string to mnemonic string
    func decryptMnemonic(_ hexString: String, password: String) throws -> String {
        guard let encryptData = Data(hexString: hexString) else {
            throw BackupError.hexStringToDataFailed
        }
        
        let decryptedData = try WalletManager.decryptionAES(key: password, data: encryptData)
        guard let mm = String(data: decryptedData, encoding: .utf8), !mm.isEmpty else {
            throw BackupError.decryptMnemonicFailed
        }
        
        return mm
    }
}
