import SwiftUI

@main
struct AccurateBatteryApp: App {
    @StateObject private var viewModel = BatteryViewModel()

    var body: some Scene {
        MenuBarExtra("Battery Status", systemImage: viewModel.batteryIconName) {
            BatteryView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
