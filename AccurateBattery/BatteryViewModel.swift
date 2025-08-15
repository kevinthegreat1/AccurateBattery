import IOKit
import SwiftUI

@MainActor
final class BatteryViewModel: ObservableObject {
    @Published private var lastDataDate: Date = Date()
    @Published private var lastActualCapacity: Int = 0
    @Published private(set) var maxCapacity: Int = 0
    @Published private(set) var designCapacity: Int = 0

    @Published private(set) var externalConnected: Bool = false
    @Published private(set) var isCharging: Bool = false
    @Published private(set) var fullyCharged: Bool = false
    @Published private(set) var amperage: Int = 0

    @Published private(set) var state: String = "Unknown"
    @Published private(set) var capacities: [CapacityEntry] = []

    private var extrapolationTimer: Timer?

    // Find the AppleSmartBattery service.
    private var service: io_service_t = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
    // Create a notification port
    private var notificationPort: IONotificationPortRef? = IONotificationPortCreate(kIOMainPortDefault)
    private var notification: io_object_t = 0

    /// Registers for notifications about changes to the AppleSmartBattery service.
    init() {
        // Add the notification port to the current run loop.
        if let port = notificationPort, let runLoopSource = IONotificationPortGetRunLoopSource(port)?.takeRetainedValue() {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
        } else {
            print("Error: Could not create IOKit notification port.")
            return
        }

        // Define a callback closure that IOKit will call when a notification occurs.
        let callback: IOServiceInterestCallback = { (refCon, service, messageType, messageArgument) in
            guard let refCon = refCon else { return }

            // Get the ViewModel instance from the opaque pointer.
            let viewModel = Unmanaged<BatteryViewModel>.fromOpaque(refCon).takeUnretainedValue()

            // Trigger an update on the main thread.
            Task { @MainActor in
                viewModel.updateBatteryInfo()
            }
        }

        // Register for "general interest" notifications for the battery service.
        // This will notify us of state changes.
        let result = IOServiceAddInterestNotification(
            notificationPort,
            service,
            kIOGeneralInterest,  // Notification type for state changes.
            callback,
            Unmanaged.passUnretained(self).toOpaque(),  // Pass self as the `refcon` so we can access it in the callback.
            &notification
        )

        if result != kIOReturnSuccess {
            print("Error: IOServiceAddInterestNotification failed with result: \(String (cString: mach_error_string(result)))")
        }

        // Perform an initial update to populate the UI.
        updateBatteryInfo()

        extrapolationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                self.extrapolateBatteryInfo()
            }
        }
    }

    /// Reads battery properties from the I/O Registry and updates the view model.
    func updateBatteryInfo() {
        guard service != 0 else {
            self.state = "Not Available"
            return
        }

        // Use `IORegistryEntryCreateCFProperty` to get the battery properties.
        guard
            let currentCapacity = IORegistryEntryCreateCFProperty(service, "AppleRawCurrentCapacity" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int,
            let maxCapacity = IORegistryEntryCreateCFProperty(service, "AppleRawMaxCapacity" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int,
            let designCapacity = IORegistryEntryCreateCFProperty(service, "DesignCapacity" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int,
            let externalConencted = IORegistryEntryCreateCFProperty(service, "ExternalConnected" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Bool,
            let isCharging = IORegistryEntryCreateCFProperty(service, "IsCharging" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Bool,
            let fullyCharged = IORegistryEntryCreateCFProperty(service, "FullyCharged" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Bool,
            let amperage = IORegistryEntryCreateCFProperty(service, "Amperage" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int
        else {
            self.state = "Error Reading Properties"
            return
        }

        self.lastActualCapacity = currentCapacity
        self.maxCapacity = maxCapacity
        self.designCapacity = designCapacity

        self.externalConnected = externalConencted
        self.isCharging = isCharging
        self.fullyCharged = fullyCharged
        self.amperage = amperage

        // Determine the battery state.
        if fullyCharged {
            self.state = "Full"
        } else if isCharging {
            self.state = "Charging"
        } else if externalConencted {
            self.state = "On Power Adapter"
        } else {
            self.state = "On Battery"
        }

        capacities.append(.init(capacity: Float(currentCapacity), extrapolated: false))

        lastDataDate = Date()
    }

    func extrapolateBatteryInfo() {
        guard isCharging else {
            return
        }

        let deltaTime = Date().timeIntervalSince(lastDataDate)
        // Extrapolate capacity delta from cached amperage (in mA)
        let deltaCapacity = Float(Double(amperage) * deltaTime / 3600.0)
        let extrapolatedCurrentCapacity = min(Float(maxCapacity), Float(lastActualCapacity) + deltaCapacity)
        capacities.append(.init(capacity: extrapolatedCurrentCapacity, extrapolated: true))
    }

    func shutDown() {
        if service != 0 {
            IOObjectRelease(service)
            service = 0
        }
        if notification != 0 {
            IOObjectRelease(notification)
            notification = 0
        }
        if extrapolationTimer != nil {
            extrapolationTimer?.invalidate()
            extrapolationTimer = nil
        }
    }

    struct CapacityEntry: Identifiable {
        let id = UUID()
        let timestamp = Date()
        let capacity: Float
        let extrapolated: Bool
    }
}
