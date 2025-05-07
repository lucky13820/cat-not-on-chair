import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: PomodoroTimerViewModel
    
    var body: some View {
        Form {
            Section(header: Text("Focus Time")) {
                // Timer settings could go here
                Text("Focus Duration: 25 minutes")
                Text("Short Break: 5 minutes")
                Text("Long Break: 15 minutes")
            }
            
            Section(header: Text("App Blocking")) {
                NavigationLink(destination: BlockingSettingsView(viewModel: viewModel)) {
                    HStack {
                        Image(systemName: "lock.shield")
                            .foregroundColor(.accentColor)
                            .imageScale(.large)
                        
                        VStack(alignment: .leading) {
                            Text("App Blocking Settings")
                            Text("Configure how apps are blocked during focus time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                HStack {
                    Text("Current Mode")
                    Spacer()
                    Text(viewModel.blockingMode.displayName)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("About App")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cat Not On Chair")
                        .font(.headline)
                    
                    Text("A simple Pomodoro timer app to help you stay focused.")
                    
                    Text("Take regular breaks to maintain productivity.")
                        .padding(.top, 4)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Settings")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView(viewModel: PomodoroTimerViewModel())
        }
    }
} 