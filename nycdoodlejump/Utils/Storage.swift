import Foundation
import CoreGraphics

enum StorageKeys {
    static let highScore = "highScore"
    static let walletCoins = "walletCoins"
    static let ownedSkins = "ownedSkins"
    static let selectedSkin = "selectedSkin"
    static let controlMode = "controlMode"
    static let controlSensitivity = "controlSensitivity"
}

struct Storage {
    static func getHighScore() -> Int {
        UserDefaults.standard.integer(forKey: StorageKeys.highScore)
    }

    static func setHighScore(_ value: Int) {
        UserDefaults.standard.set(value, forKey: StorageKeys.highScore)
    }

    static func getWalletCoins() -> Int {
        UserDefaults.standard.integer(forKey: StorageKeys.walletCoins)
    }

    static func setWalletCoins(_ value: Int) {
        UserDefaults.standard.set(value, forKey: StorageKeys.walletCoins)
    }

    static func getOwnedSkins() -> [String] {
        if let csv = UserDefaults.standard.string(forKey: StorageKeys.ownedSkins), !csv.isEmpty {
            return csv.split(separator: ",").map { String($0) }
        }
        return ["classic_green"]
    }

    static func setOwnedSkins(_ value: [String]) {
        let csv = value.joined(separator: ",")
        UserDefaults.standard.set(csv, forKey: StorageKeys.ownedSkins)
    }

    static func getSelectedSkin() -> String {
        if let skin = UserDefaults.standard.string(forKey: StorageKeys.selectedSkin), !skin.isEmpty {
            return skin
        }
        return "classic_green"
    }

    static func setSelectedSkin(_ value: String) {
        UserDefaults.standard.set(value, forKey: StorageKeys.selectedSkin)
    }

    static func getControlMode() -> String {
        if let mode = UserDefaults.standard.string(forKey: StorageKeys.controlMode), !mode.isEmpty {
            return mode
        }
        return "tap"
    }

    static func setControlMode(_ value: String) {
        UserDefaults.standard.set(value, forKey: StorageKeys.controlMode)
    }

    static func getControlSensitivity() -> CGFloat {
        let value = UserDefaults.standard.double(forKey: StorageKeys.controlSensitivity)
        if value == 0 {
            return 1.0
        }
        return CGFloat(value)
    }

    static func setControlSensitivity(_ value: CGFloat) {
        UserDefaults.standard.set(Double(value), forKey: StorageKeys.controlSensitivity)
    }
}
