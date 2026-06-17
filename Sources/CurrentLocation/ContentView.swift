import SwiftUI
import CoreLocation

struct ContentView: View {
    @ObservedObject var tracker: LocationTracker

    var body: some View {
        VStack(spacing: 24) {
            // Статус
            VStack(spacing: 8) {
                Image(systemName: tracker.isTracking ? "location.fill" : "location.slash")
                    .font(.system(size: 48))
                    .foregroundStyle(tracker.isTracking ? .green : .secondary)
                    .symbolEffect(.bounce, value: tracker.isTracking)

                Text(tracker.statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Координаты
            if let loc = tracker.lastLocation {
                VStack(spacing: 4) {
                    CoordRow(label: "Широта",  value: loc.coordinate.latitude,  format: "%.6f")
                    CoordRow(label: "Долгота", value: loc.coordinate.longitude, format: "%.6f")
                    CoordRow(label: "Точность", value: loc.horizontalAccuracy,  format: "%.1f м")
                }
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
            } else {
                Text("Координаты недоступны")
                    .foregroundStyle(.tertiary)
                    .padding()
            }

            // Кнопка старт / стоп
            Button {
                tracker.isTracking ? tracker.stop() : tracker.start()
            } label: {
                Label(
                    tracker.isTracking ? "Остановить" : "Запустить",
                    systemImage: tracker.isTracking ? "stop.circle.fill" : "play.circle.fill"
                )
                .frame(maxWidth: .infinity)
                .padding()
                .background(tracker.isTracking ? Color.red : Color.green)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .onAppear { tracker.restoreIfNeeded() }
    }
}

private struct CoordRow: View {
    let label: String
    let value: Double
    let format: String

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(String(format: format, value)).monospacedDigit()
        }
    }
}
