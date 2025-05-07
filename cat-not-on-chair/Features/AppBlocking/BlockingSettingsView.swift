import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

// Note: PomodoroTimerViewModel and AppBlockingService are part of the same module
// and will be accessible since they're in the Core directory

struct BlockingSettingsView: View {
    @ObservedObject var viewModel: PomodoroTimerViewModel
    @ObservedObject var blockingService = AppBlockingService.shared
    @State private var showAppSelectionPicker = false
    @State private var isRequestingPermission = false
    
    var body: some View {
        Form {
            Section(header: Text("App Blocking Mode")) {
                ForEach(BlockingMode.allCases) { mode in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(mode.displayName)
                                .font(.headline)
                            Text(mode.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if viewModel.blockingMode == mode {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.blockingMode = mode
                    }
                }
            }
            
            if viewModel.blockingMode == .whitelist {
                Section(header: Text("Allowed Apps During Focus")) {
                    if !blockingService.hasPermission {
                        Button(action: {
                            isRequestingPermission = true
                            Task {
                                await viewModel.requestFamilyControlsPermission()
                                isRequestingPermission = false
                            }
                        }) {
                            HStack {
                                Text("Request Permission")
                                Spacer()
                                if isRequestingPermission {
                                    ProgressView()
                                }
                            }
                        }
                    } else {
                        Button(action: {
                            showAppSelectionPicker = true
                        }) {
                            HStack {
                                Text("Select Allowed Apps")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Text("These apps will remain accessible during focus time, all other apps will be blocked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if viewModel.blockingMode == .strict {
                Section {
                    Text("In strict mode, all apps except this one will be blocked during focus time.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button(action: {
                    Task {
                        await viewModel.requestFamilyControlsPermission()
                    }
                }) {
                    if !blockingService.hasPermission {
                        Text("Grant App Blocking Permission")
                            .foregroundColor(.red)
                    } else {
                        Text("App Blocking Permission Granted")
                            .foregroundColor(.green)
                    }
                }
                .disabled(blockingService.hasPermission)
            }
        }
        .navigationTitle("App Blocking")
        .modifier(FamilyActivityPickerModifier(isPresented: $showAppSelectionPicker, selection: blockingService))
        .onAppear {
            blockingService.checkAuthorizationStatus()
        }
    }
}

// Add this modifier to conditionally apply familyActivityPicker
struct FamilyActivityPickerModifier: ViewModifier {
    @Binding var isPresented: Bool
    var selection: AppBlockingService
    
    func body(content: Content) -> some View {
        #if canImport(FamilyControls)
        return content.onChange(of: isPresented) { newValue in
            if newValue {
                Task {
                    // This will now open system settings as a reliable fallback
                    await selection.selectApps()
                    isPresented = false
                }
            }
        }
        #else
        return content
        #endif
    }
}

struct BlockingSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BlockingSettingsView(viewModel: PomodoroTimerViewModel())
        }
    }
} 