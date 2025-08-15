import Charts
import SwiftUI

struct BatteryView: View {
    @ObservedObject var viewModel: BatteryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // An icon that changes based on the battery state.
                Image(systemName: viewModel.batteryIconName)
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 36))
                    .fontWeight(.light)
                    .foregroundStyle(viewModel.batteryColor)

                VStack(alignment: .leading) {
                    // Display the state (e.g., "Charging", "Unplugged").
                    Text(viewModel.state)
                        .font(.headline)

                    // Display the battery level as a percentage with two decimal place.
                    Text(viewModel.level, format: .percent.precision(.fractionLength(2)))
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        // Display the current and max battery capacity.
                        Text("\(viewModel.currentCapacity.formatted(.number.grouping(.never).precision(.fractionLength(1))))/\(viewModel.maxCapacity.formatted(.number.grouping(.never))) mAh")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Display the design battery capacity
                        Text("Design Capacity: \(viewModel.designCapacity.formatted(.number.grouping(.never))) mAh")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // A progress bar to visualize the battery level.
            ProgressView(value: viewModel.level)
                .progressViewStyle(.linear)
                .tint(viewModel.batteryColor)

            // A chart that graphs extrapolated capacity over time
            Chart(viewModel.capacities) { entry in
                LineMark(
                    x: .value("Time", entry.timestamp),
                    y: .value("Capacity (mAh)", entry.capacity)
                )
            }
            .chartYScale(domain: 0...viewModel.maxCapacity)
            .frame(height: 200)
        }
        .padding()
        .frame(width: 400)  // Give the view a fixed size
    }
}

#Preview {
    BatteryView(viewModel: BatteryViewModel())
}
