import UIKit
import Foundation
import Combine
import FamilyControls
import SwiftUI
import ManagedSettings
import DeviceActivity
import ActivityKit
import UserNotifications

class TimerViewController: UIViewController {
    private let viewModel = TimerViewModel()
    private let familyControlsManager = FamilyControlsManager.shared
    
    // MARK: - UI Components
    private lazy var timerLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 60, weight: .bold)
        label.textAlignment = .center
        label.text = "25:00"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start Focus", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var stopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Stop", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    private lazy var modeSegmentedControl: UISegmentedControl = {
        let items = FocusMode.allCases.map { $0.rawValue }
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 2 // Default to relax mode
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    // For showing app selection in whitelist mode
    private var activitySelectionViewController: UIViewController?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        
        // Request notification permissions if needed
        requestNotificationPermissions()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(timerLabel)
        view.addSubview(startButton)
        view.addSubview(stopButton)
        view.addSubview(modeSegmentedControl)
        
        NSLayoutConstraint.activate([
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 40),
            startButton.widthAnchor.constraint(equalToConstant: 200),
            startButton.heightAnchor.constraint(equalToConstant: 50),
            
            stopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopButton.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 40),
            stopButton.widthAnchor.constraint(equalToConstant: 200),
            stopButton.heightAnchor.constraint(equalToConstant: 50),
            
            modeSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            modeSegmentedControl.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 20),
            modeSegmentedControl.widthAnchor.constraint(equalToConstant: 300)
        ])
        
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(stopButtonTapped), for: .touchUpInside)
        modeSegmentedControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
    }
    
    private func setupBindings() {
        Task { @MainActor in
            for await _ in viewModel.$timeRemaining.values {
                updateTimerLabel()
            }
        }
        
        Task { @MainActor in
            for await isRunning in viewModel.$isRunning.values {
                startButton.isHidden = isRunning
                stopButton.isHidden = !isRunning
                
                // Update UI based on timer status
                if isRunning {
                    UIApplication.shared.isIdleTimerDisabled = true // Prevent screen sleep
                } else {
                    UIApplication.shared.isIdleTimerDisabled = false
                }
            }
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
                return
            }
            
            if granted {
                print("Notification permissions granted")
            } else {
                print("Notification permissions denied")
            }
        }
    }
    
    private func scheduleCompletionNotification(for session: Session) {
        let content = UNMutableNotificationContent()
        content.title = session.type == .focus ? "Focus Session Complete!" : "Break Time Complete!"
        content.body = session.type == .focus ? "Great job! Time for a break." : "Time to get back to work!"
        content.sound = .default
        
        // Create a notification trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create the request
        let request = UNNotificationRequest(
            identifier: "SessionComplete-\(session.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Actions
    @objc private func startButtonTapped() {
        Task { @MainActor in
            let selectedMode = FocusMode.allCases[modeSegmentedControl.selectedSegmentIndex]
            viewModel.focusMode = selectedMode
            
            // Check if we need FamilyControls permission for the selected mode
            if (selectedMode == .strict || selectedMode == .whitelist) && !familyControlsManager.checkAuthorization() {
                // Directly request system authorization
                let granted = await familyControlsManager.requestAuthorization()
                if !granted {
                    // Only show an alert if permission was denied
                    let alert = UIAlertController(
                        title: "Permission Declined",
                        message: "App blocking requires Family Controls access. Focus session will start without blocking apps.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            }
            
            // Start the focus session
            viewModel.startFocusSession()
        }
    }
    
    @objc private func stopButtonTapped() {
        Task { @MainActor in
            viewModel.stopSession()
        }
    }
    
    @objc private func modeChanged() {
        let selectedMode = FocusMode.allCases[modeSegmentedControl.selectedSegmentIndex]
        viewModel.focusMode = selectedMode  // Always update the focus mode
        
        if selectedMode == .whitelist {
            Task {
                // Request app selection if we have permission
                if !familyControlsManager.checkAuthorization() {
                    // Directly request system permission
                    let granted = await familyControlsManager.requestAuthorization()
                    if granted {
                        // If granted, show the app selection
                        await MainActor.run {
                            showAppSelectionIfNeeded(for: selectedMode)
                        }
                    }
                } else {
                    // We already have permission, show the app selection
                    await MainActor.run {
                        showAppSelectionIfNeeded(for: selectedMode)
                    }
                }
            }
        } else if viewModel.isRunning {
            // If we're already running a session and the mode changed,
            // apply the new blocking settings immediately
            Task {
                await MainActor.run {
                    viewModel.applyCurrentModeBlocking()
                }
            }
        }
    }
    
    // Present app selection UI for the whitelist mode
    private func showAppSelectionIfNeeded(for mode: FocusMode) {
        if mode == .whitelist {
            // Only show activity picker if we have authorization
            guard familyControlsManager.checkAuthorization() else {
                return
            }
            
            // Create a binding for SwiftUI
            let activityBinding = Binding<FamilyActivitySelection>(
                get: { self.familyControlsManager.getSelection() ?? FamilyActivitySelection() },
                set: { newValue in
                    // When selection changes, update the view model
                    self.viewModel.updateActivitySelection(newValue)
                }
            )
            
            // Create a custom view with the FamilyActivityPicker and a dismiss button
            let pickerView = FamilyActivityPickerWithDismiss(
                selection: activityBinding,
                dismiss: { [weak self] in
                    self?.activitySelectionViewController?.dismiss(animated: true)
                    self?.activitySelectionViewController = nil
                }
            )
            
            let pickerVC = UIHostingController(rootView: pickerView)
            
            pickerVC.modalPresentationStyle = UIModalPresentationStyle.pageSheet
            pickerVC.isModalInPresentation = false // Allow dismissal by swiping
            
            if let sheet = pickerVC.sheetPresentationController {
                sheet.detents = [UISheetPresentationController.Detent.medium(), 
                                UISheetPresentationController.Detent.large()]
                sheet.prefersGrabberVisible = true
            }
            
            present(pickerVC, animated: true)
            
            // Store for later dismissal
            self.activitySelectionViewController = pickerVC
        }
    }
    
    // Create a custom SwiftUI view with FamilyActivityPicker and a dismiss button
    private struct FamilyActivityPickerWithDismiss: View {
        @Binding var selection: FamilyActivitySelection
        let dismiss: () -> Void
        
        var body: some View {
            VStack {
                HStack {
                    Text("Select Apps to Allow")
                        .font(.headline)
                        .padding(.leading)
                    
                    Spacer()
                    
                    Button("Save & Close") {
                        // Make sure the selection is applied before dismissing
                        print("Saving selection with \(selection.applicationTokens.count) apps")
                        dismiss()
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
                
                FamilyActivityPicker(selection: $selection)
                    .onChange(of: selection) { newValue in
                        // Log changes to selection
                        print("Selection changed: \(newValue.applicationTokens.count) apps selected")
                    }
            }
        }
    }
    
    // MARK: - Helpers
    private func updateTimerLabel() {
        let minutes = Int(viewModel.timeRemaining) / 60
        let seconds = Int(viewModel.timeRemaining) % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
        
        // When timer completes, schedule a notification
        if viewModel.timeRemaining <= 0 && viewModel.currentSession != nil {
            scheduleCompletionNotification(for: viewModel.currentSession!)
        }
    }
} 