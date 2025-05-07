import SwiftUI

#if canImport(ActivityKit)
import ActivityKit
#endif

struct TimerView: View {
    @ObservedObject var viewModel: PomodoroTimerViewModel
    
    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 32) {
                Spacer()
                
                // Chair and Cat
                ZStack {
                    Image(systemName: "chair.lounge.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width * 0.5)
                        .foregroundColor(.accentColor)
                    if viewModel.sessionType == PomodoroSessionType.focus && viewModel.timerState == PomodoroTimerState.running {
                        Image(systemName: "pawprint.fill") // Placeholder for cat
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width * 0.2)
                            .offset(y: geometry.size.width * 0.1)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.top, 40)
                
                // Timer
                Text(formattedTime(viewModel.remainingTime))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.5)
                    .accessibilityLabel("Time remaining")
                
                // Session Type
                Text(sessionTypeText)
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Session type: \(sessionTypeText)")
                
                // Blocking Mode
                Text("Blocking: \(viewModel.blockingMode.displayName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Controls
                HStack(spacing: 24) {
                    Button(action: { viewModel.reset() }) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .disabled(viewModel.timerState == .idle)
                    
                    if viewModel.timerState == .running {
                        Button(action: { viewModel.stop() }) {
                            Label("Stop", systemImage: "stop.fill")
                        }
                        .tint(.red)
                    } else {
                        Button(action: { viewModel.start() }) {
                            Label("Start", systemImage: "play.fill")
                        }
                        .tint(.green)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .ignoresSafeArea(edges: .bottom)
        }
    }
    
    private var sessionTypeText: String {
        switch viewModel.sessionType {
        case .focus: return "Focus Time"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TimerView(viewModel: PomodoroTimerViewModel())
                .preferredColorScheme(.light)
            TimerView(viewModel: PomodoroTimerViewModel())
                .preferredColorScheme(.dark)
        }
    }
}