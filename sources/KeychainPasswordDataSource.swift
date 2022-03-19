//
//  KeychainPasswordDataSource.swift
//  iTerm2SharedARC
//
//  Created by George Nachman on 3/19/22.
//

import AppKit

fileprivate let serviceName = "iTerm2"

fileprivate class KeychainAccount: NSObject, PasswordManagerAccount {
    private let accountNameUserNameSeparator = "\u{2002}—\u{2002}"

    let accountName: String
    let userName: String
    private let keychainAccountName: String

    fileprivate init(accountName: String, userName: String) {
        self.accountName = accountName
        self.userName = userName
        keychainAccountName = userName.isEmpty ? accountName : accountName + accountNameUserNameSeparator + userName
    }

    fileprivate init?(_ dict: NSDictionary) {
        guard let combinedAccountName = dict[kSecAttrAccount] as? String else {
            return nil
        }
        if let range = combinedAccountName.range(of: accountNameUserNameSeparator) {
            accountName = String(combinedAccountName[..<range.lowerBound])
            userName = String(combinedAccountName[range.upperBound...])
        } else {
            accountName = combinedAccountName
            userName = ""
        }
        keychainAccountName = combinedAccountName
    }

    var displayString: String {
        return keychainAccountName
    }

    func password() throws -> String {
        return try SSKeychain.password(forService: serviceName,
                                       account: keychainAccountName,
                                       error: ())
    }

    func set(password: String) throws {
        try SSKeychain.setPassword(password,
                                   forService: serviceName,
                                   account: keychainAccountName,
                                   error: ())
    }

    func delete() throws {
        try SSKeychain.deletePassword(forService: serviceName,
                                      account: keychainAccountName,
                                      error: ())
    }

    func matches(filter: String) -> Bool {
        return _matches(filter: filter)
    }
}

class KeychainPasswordDataSource: NSObject, PasswordManagerDataSource {
    private var openPanel: NSOpenPanel?
    private static let keychainPathUserDefaultsKey = "NoSyncKeychainPath"
    private static let keychain = KeychainPasswordDataSource()

    private static var pathToKeychain: String? {
        return UserDefaults.standard.string(forKey: keychainPathUserDefaultsKey)
    }

    override init() {
        super.init()
        updateConfiguration()
    }

    var accounts: [PasswordManagerAccount] {
        guard let dicts = SSKeychain.accounts(forService: serviceName) as? [NSDictionary] else {
            return []
        }
        return dicts.compactMap {
            KeychainAccount($0)
        }
    }

    func add(userName: String,
             accountName: String,
             password: String) throws -> PasswordManagerAccount {
        let account = KeychainAccount(accountName: accountName, userName: userName)
        try account.set(password: password)
        return account
    }

    func configure(_ completion: @escaping (Bool) -> ()) {
        let panel = NSOpenPanel()
        self.openPanel = panel
        let home = NSHomeDirectory() as NSString
        panel.directoryURL = URL(fileURLWithPath: home.appendingPathComponents(["Library", "Keychains"]))
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = [ "keychain-db" ]
        panel.begin { [weak self] result in
            let ok = self?.didChooseKeychain(result) ?? false
            completion(ok)
        }
    }

    private func didChooseKeychain(_ response: NSApplication.ModalResponse) -> Bool {
        guard response == .OK, let path = openPanel?.url?.path else {
            return false
        }
        openPanel = nil
        UserDefaults.standard.set(path, forKey: Self.keychainPathUserDefaultsKey)
        updateConfiguration()
        return true
    }

    private func updateConfiguration() {
        SSKeychain.pathToKeychain = Self.pathToKeychain
    }
}
