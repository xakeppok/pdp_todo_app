import UIKit

final class BatteryPigeonApi: BatteryHostApi {
    func getBatteryLevel() throws -> Int64 {
        UIDevice.current.isBatteryMonitoringEnabled = true

        let batteryLevel = UIDevice.current.batteryLevel

        if batteryLevel >= 0 {
            return Int64(batteryLevel * 100)
        }

        throw PigeonError(
            code: "UNAVAILABLE",
            message: "Battery level not available.",
            details: nil
        )
    }
}
