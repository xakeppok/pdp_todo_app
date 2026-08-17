import UIKit

enum BatteryLevelReader {
    static func capacityPercent() -> Int? {
        let device = UIDevice.current
        if !device.isBatteryMonitoringEnabled {
            device.isBatteryMonitoringEnabled = true
        }
        let batteryLevel = device.batteryLevel
        guard batteryLevel >= 0 else { return nil }
        return Int(batteryLevel * 100)
    }
}
