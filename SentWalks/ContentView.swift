import SwiftUI
import HealthKit

struct HealthKitView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var systolicValue: String = "120"
    @State private var diastolicValue: String = "80"
    @State private var showingCustomBP = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    Text("SendWalkSteps!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    // Authorization Section
                    if !healthKitManager.isAuthorized {
                        authorizationSection
                    } else {
                        authorizedContent
                    }
                    
                    // Error Display
                    if !healthKitManager.errorMessage.isEmpty {
                        errorSection
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCustomBP) {
            customBloodPressureSheet
        }
    }
    
    // MARK: - Authorization Section
    private var authorizationSection: some View {
        VStack(spacing: 15) {
            Image(systemName: "heart.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("HealthKit Permission Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("This app needs access to read your step data and write blood pressure measurements to the Health app.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Grant HealthKit Access") {
                healthKitManager.requestAuthorization()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // MARK: - Authorized Content
    
    private var authorizedContent: some View {
        VStack(spacing: 25) {
            // Steps Section
            stepsSection
            
            // Blood Pressure Section
            bloodPressureSection
        }
    }
    
    private var stepsSection: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "figure.walk")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("Today's Steps")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(healthKitManager.stepCount)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    
                    Text("/ 5,000 goal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Refresh") {
                    healthKitManager.fetchStepCount()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private var bloodPressureSection: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "heart.circle")
                    .font(.title2)
                    .foregroundColor(.red)
                Text("Blood Pressure")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if !healthKitManager.lastBloodPressureWrite.isEmpty {
                Text(healthKitManager.lastBloodPressureWrite)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Quick Buttons
            VStack(spacing: 10) {
                Button("Write Static BP (120/80)") {
                    healthKitManager.writeStaticBloodPressure()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                HStack(spacing: 15) {
                    Button("Random BP") {
                        healthKitManager.writeRandomBloodPressure()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Custom BP") {
                        showingCustomBP = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Text("Data will appear in the Apple Health app")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // MARK: - Custom Blood Pressure Sheet
    
    private var customBloodPressureSheet: some View {
        NavigationView {
            VStack(spacing: 25) {
                Text("Enter Blood Pressure")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                VStack(spacing: 15) {
                    HStack {
                        Text("Systolic (top number):")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        TextField("120", text: $systolicValue)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                        Text("mmHg")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Diastolic (bottom number):")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        TextField("80", text: $diastolicValue)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                        Text("mmHg")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Button("Save to Health App") {
                    if let systolic = Double(systolicValue),
                       let diastolic = Double(diastolicValue) {
                        healthKitManager.writeBloodPressure(systolic: systolic, diastolic: diastolic)
                        showingCustomBP = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Blood Pressure")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    showingCustomBP = false
                }
            )
        }
    }
    
    // MARK: - Error Section
    
    private var errorSection: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(healthKitManager.errorMessage)
                .font(.caption)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Content View

struct ContentView: View {
    var body: some View {
        HealthKitView()
    }
}

#Preview {
    ContentView()
}
