import UIKit

final class BatteryPigeonApi: BatteryHostApi {
    func getBatteryLevel() throws -> Int64 {
        guard let batteryLevel = BatteryLevelReader.capacityPercent() else {
            throw PigeonError(
                code: "UNAVAILABLE",
                message: "Battery level not available.",
                details: nil
            )
        }
        return Int64(batteryLevel)
    }
}
