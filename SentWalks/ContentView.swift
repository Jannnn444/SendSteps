import HealthKit
import SwiftUI

// MARK: - SwiftUI View Example

struct HealthKitView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("SendWalkSteps!")
                .font(.title)
                .fontWeight(.bold)
            
            if !healthKitManager.isAuthorized {
                VStack(spacing: 15) {
                    Text("HealthKit Permission Required")
                        .font(.headline)
                    
                    Text("This app needs access to your step data to track your daily progress.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button("Grant HealthKit Access") {
                        healthKitManager.requestAuthorization()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                VStack(spacing: 15) {
                    Text("Today's Steps")
                        .font(.headline)
                    
                    Text("\(healthKitManager.stepCount)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    Text("/ 5,000 goal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Refresh Steps") {
                        healthKitManager.fetchStepCount()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            
            if !healthKitManager.errorMessage.isEmpty {
                Text(healthKitManager.errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .onAppear {
            // Don't automatically request authorization on appear
            // Let user tap the button instead
        }
    }
}

// MARK: - Usage in ContentView

struct ContentView: View {
    var body: some View {
        HealthKitView()
    }
}

#Preview {
    ContentView()
}
