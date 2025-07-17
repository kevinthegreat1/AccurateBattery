import SwiftUI
import Charts

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
                        .symbolRenderingMode(.hierarchical)
                        .font(.system(size: 36))
                        .fontWeight(.light)
                        .foregroundStyle(batteryColor)
                    
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
                            Text("Design Capacity: " + String(viewModel.designCapacity) + " mAh")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // A progress bar to visualize the battery level.
                ProgressView(value: viewModel.level)
                    .progressViewStyle(.linear)
                    .tint(batteryColor)
                
                // A chart that graphs current capacity over time
                Chart(viewModel.capacities) { entry in
                    LineMark(
                        x: .value("Time", entry.timestamp),
                        y: .value("Capacity (mAh)", entry.capacity)
                    )
                }
                .chartYScale(domain: 0...viewModel.maxCapacity)
                .frame(height: 200)
                .padding(.top, 8)
            }
            .padding(.vertical, 8)
        }
        .padding()
        .frame(width: 500) // Give the view a fixed size
        .onDisappear {
            viewModel.shutDown()
        }
    }
    
    /// A computed property to determine the SF Symbol name for the battery icon.
    private var batteryIconName: String {
        // Round the level to the nearest 25% for the icon.
        let levelPercentage = Int(round(viewModel.level * 100))
        
        if viewModel.isCharging || viewModel.externalConnected {
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
        if viewModel.isCharging {
            return .green
        }
        if viewModel.externalConnected {
            return .blue
        }
        if viewModel.level <= 0.1 {
            return .red
        }
        return .primary
    }
}

#Preview {
    BatteryView()
}
