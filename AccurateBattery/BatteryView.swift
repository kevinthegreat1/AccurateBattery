import SwiftUI

struct BatteryView: View {
    // Create an instance of the view model that will persist for the life of the view.
    @StateObject private var viewModel = BatteryViewModel()
    
    var body: some View {
        // Use a GroupBox for nice visual separation.
        GroupBox("Battery Status") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // An icon that changes based on the battery state.
                    Image(systemName: batteryIconName)
                        .font(.title)
                        .frame(width: 40)
                        .foregroundColor(batteryColor)
                    
                    VStack(alignment: .leading) {
                        // Display the state (e.g., "Charging", "Unplugged").
                        Text(viewModel.state)
                            .font(.headline)
                        
                        // Display the battery level as a percentage with two decimal place.
                        Text(viewModel.level, format:
                            .percent.precision(.fractionLength(2)))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            // Display the current and max battery capacity.
                            Text(String(viewModel.currentCapacity) + "/" + String(viewModel.maxCapacity))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // Display the design battery capacity
                            Text("Design Capacity: " + String(viewModel.designCapacity))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // A progress bar to visualize the battery level.
                ProgressView(value: viewModel.level)
                    .progressViewStyle(.linear)
                    .tint(batteryColor)
            }
            .padding(.vertical, 8)
        }
        .padding()
        .frame(width: 280) // Give the view a fixed size
        .onDisappear {
            viewModel.shutDown()
        }
    }
    
    /// A computed property to determine the SF Symbol name for the battery icon.
    private var batteryIconName: String {
        // Round the level to the nearest 25% for the icon.
        let levelPercentage = Int(round(viewModel.level * 100))
        
        if viewModel.state == "Charging" {
            return "battery.100.bolt"
        }
        
        switch levelPercentage {
            case 76...100:
                return "battery.100"
            case 51...75:
                return "battery.75"
            case 26...50:
                return "battery.50"
            case 11...25:
                return "battery.25"
            default:
                // Use a special icon for low battery
                return "battery.0"
        }
    }
    
    /// A computed property to determine the color of the icon and progress bar.
    private var batteryColor: Color {
        if viewModel.state == "Charging" || viewModel.state == "Full" {
            return .green
        }
        if viewModel.level <= 0.2 {
            return .red
        }
        return .primary
    }
}

#Preview {
    BatteryView()
}
