import Foundation
import HealthKit
import SwiftUI

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var stepCount: Int = 0
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var isAuthorized: Bool = false
    @Published var errorMessage: String = ""
    @Published var lastBloodPressureWrite: String = ""
    
    // Define the health data types we need
    private let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    private let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    
    // Blood pressure types
//    private let bloodPressureType = HKCorrelationType.correlationType(forIdentifier: .bloodPressure)!
    private let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
    private let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
    
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            DispatchQueue.main.async {
                self.errorMessage = "HealthKit is not available on this device"
            }
            return
        }
        
        // Define what we want to read and write
        let typesToRead: Set<HKObjectType> = [
            stepCountType,
            distanceType,
            activeEnergyType,
//            bloodPressureType,
            systolicType,
            diastolicType
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            stepCountType,
            distanceType,
            activeEnergyType,
//            bloodPressureType,
            systolicType,
            diastolicType
        ]
        
        print("🔄 Requesting HealthKit authorization...")
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Authorization error: \(error.localizedDescription)")
                    self?.errorMessage = "Authorization failed: \(error.localizedDescription)"
                    return
                }
                
                if success {
                    print("✅ Authorization request completed")
                    self?.checkAuthorizationStatus()
                } else {
                    print("❌ Authorization was denied")
                    self?.errorMessage = "HealthKit authorization was denied"
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        let status = healthStore.authorizationStatus(for: stepCountType)
        
        DispatchQueue.main.async {
            self.authorizationStatus = status
            self.isAuthorized = (status == .sharingAuthorized)
            
            print("📊 Authorization status: \(status.rawValue)")
            
            switch status {
            case .notDetermined:
                print("⏳ Authorization not determined")
                self.errorMessage = "HealthKit permission not requested yet"
            case .sharingDenied:
                print("🚫 Authorization denied")
                self.errorMessage = "HealthKit access denied. Please enable in Settings → Privacy & Security → Health"
            case .sharingAuthorized:
                print("✅ Authorization granted")
                self.errorMessage = ""
                self.fetchStepCount()
            @unknown default:
                print("❓ Unknown authorization status")
                self.errorMessage = "Unknown authorization status"
            }
        }
    }
    
    // MARK: - Data Fetching
    
    func fetchStepCount() {
        guard authorizationStatus == .sharingAuthorized else {
            DispatchQueue.main.async {
                self.errorMessage = "Not authorized to read step data"
            }
            print("❌ Cannot fetch steps: Not authorized")
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: stepCountType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error fetching steps: \(error.localizedDescription)")
                    self?.errorMessage = "Error fetching steps: \(error.localizedDescription)"
                    return
                }
                
                guard let result = result, let sum = result.sumQuantity() else {
                    print("📊 No step data available")
                    self?.stepCount = 0
                    return
                }
                
                let steps = Int(sum.doubleValue(for: HKUnit.count()))
                print("📊 Fetched steps: \(steps)")
                self?.stepCount = steps
                self?.errorMessage = ""
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Blood Pressure Functions
    
    /// Write blood pressure data to HealthKit
    /// - Parameters:
    ///   - systolic: Top number (e.g., 120)
    ///   - diastolic: Bottom number (e.g., 80)
    ///   - date: When the reading was taken (defaults to now)
    func writeBloodPressure(systolic: Double, diastolic: Double, date: Date = Date()) {
        guard isAuthorized else {
            DispatchQueue.main.async {
                self.errorMessage = "Not authorized to write health data"
            }
            return
        }
        
        // Validate blood pressure values
        guard systolic > 0 && diastolic > 0 && systolic > diastolic else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid blood pressure values. Systolic must be greater than diastolic."
            }
            return
        }
        
        // Create systolic and diastolic samples
        let systolicQuantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: systolic)
        let diastolicQuantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: diastolic)
        
        let systolicSample = HKQuantitySample(
            type: systolicType,
            quantity: systolicQuantity,
            start: date,
            end: date
        )
        
        let diastolicSample = HKQuantitySample(
            type: diastolicType,
            quantity: diastolicQuantity,
            start: date,
            end: date
        )
        
        // Create correlation (combines both values)
//        let bloodPressureCorrelation = HKCorrelation(
////            type: bloodPressureType,
//            start: date,
//            end: date,
//            objects: Set([systolicSample, diastolicSample])
//        )
        
        print("💉 Writing blood pressure: \(Int(systolic))/\(Int(diastolic)) mmHg")
        
        // Save to HealthKit
//        healthStore.save(bloodPressureCorrelation) { [weak self] success, error in
//            DispatchQueue.main.async {
//                if let error = error {
//                    print("❌ Failed to save blood pressure: \(error.localizedDescription)")
//                    self?.errorMessage = "Failed to save blood pressure: \(error.localizedDescription)"
//                } else if success {
//                    print("✅ Blood pressure saved successfully")
//                    let formatter = DateFormatter()
//                    formatter.dateStyle = .short
//                    formatter.timeStyle = .short
//                    self?.lastBloodPressureWrite = "Saved \(Int(systolic))/\(Int(diastolic)) at \(formatter.string(from: date))"
//                    self?.errorMessage = ""
//                } else {
//                    print("❌ Failed to save blood pressure: Unknown error")
//                    self?.errorMessage = "Failed to save blood pressure: Unknown error"
//                }
//            }
//        }
    }
    
    /// Write a static/example blood pressure reading
    func writeStaticBloodPressure() {
        // Example values - you can change these
        let exampleSystolic: Double = 120  // Normal systolic
        let exampleDiastolic: Double = 80   // Normal diastolic
        
        writeBloodPressure(systolic: exampleSystolic, diastolic: exampleDiastolic)
    }
    
    /// Write random realistic blood pressure values (for testing)
    func writeRandomBloodPressure() {
        // Generate realistic blood pressure values
        let systolic = Double.random(in: 110...140)  // Normal range
        let diastolic = Double.random(in: 70...90)   // Normal range
        
        writeBloodPressure(systolic: systolic, diastolic: diastolic)
    }
    
    // MARK: - Background Observer (Optional)
    
    func setupBackgroundObserver() {
        guard isAuthorized else { return }
        
        let query = HKObserverQuery(sampleType: stepCountType, predicate: nil) { [weak self] _, _, error in
            if let error = error {
                print("❌ Observer query error: \(error.localizedDescription)")
                return
            }
            
            print("🔄 Step data changed, refreshing...")
            self?.fetchStepCount()
        }
        
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: stepCountType, frequency: .immediate) { success, error in
            if let error = error {
                print("❌ Background delivery error: \(error.localizedDescription)")
            } else {
                print("✅ Background delivery enabled: \(success)")
            }
        }
    }
}
