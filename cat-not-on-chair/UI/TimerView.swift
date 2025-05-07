import SwiftUI
import ActivityKit

struct TimerView: View {
    @StateObject private var viewModel = PomodoroTimerViewModel()
    @EnvironmentObject private var blockModeService: BlockModeService
    
    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 32) {
                Spacer()
                
                // Block Mode Indicator
                if blockModeService.isBlockModeEnabled && blockModeService.isCurrentlyBlocking {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                        Text("Block Mode Active")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.2))
                    )
                }
                
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
            .background(Color(uiColor: .systemBackground))
            .ignoresSafeArea(edges: .bottom)
            .onReceive(NotificationCenter.default.publisher(for: .blockModeDidStart)) { _ in
                if viewModel.sessionType == .focus && viewModel.timerState == .running {
                    // Show block mode started alert or other UI indication
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .blockModeDidEnd)) { _ in
                // Handle block mode ended
            }
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
            TimerView()
                .environmentObject(BlockModeService())
                .preferredColorScheme(.light)
            TimerView()
                .environmentObject(BlockModeService())
                .preferredColorScheme(.dark)
        }
    }
}