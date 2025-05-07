//
//  CatNotOnChairWidgetExtension.swift
//  CatNotOnChairWidgetExtension
//
//  Created by Ryan Yao on 2025-05-07.
//

import WidgetKit
import SwiftUI
import ActivityKit

// Simple test Live Activity
struct TestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TestActivityAttributes.self) { context in
            // Lock screen/banner UI
            VStack(spacing: 12) {
                Text("Test Live Activity")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Counter: \(context.state.counter)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Simple visual
                Image(systemName: "timer")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.blue)
            .cornerRadius(16)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Text("Test")
                        .foregroundColor(.white)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: "timer")
                        .foregroundColor(.white)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    Text("\(context.state.counter)")
                        .font(.system(.title, design: .rounded))
                        .foregroundColor(.white)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Simple Test Activity")
                        .foregroundColor(.white)
                }
                
            } compactLeading: {
                // Compact leading
                Image(systemName: "timer")
                    .foregroundColor(.white)
            } compactTrailing: {
                // Compact trailing
                Text("\(context.state.counter)")
                    .foregroundColor(.white)
            } minimal: {
                // Minimal
                Image(systemName: "timer")
                    .foregroundColor(.white)
            }
        }
    }
}

// Helper function to start test activity
func startTestActivity() {
    let attributes = TestActivityAttributes(name: "Test")
    let contentState = TestActivityAttributes.ContentState(counter: 42)
    do {
        let activity = try Activity<TestActivityAttributes>.request(
            attributes: attributes,
            contentState: contentState,
            pushType: nil
        )
        print("Test Live Activity started: \(activity.id)")
    } catch {
        print("Failed to start Test Live Activity: \(error)")
    }
}

// Pomodoro Live Activity
struct PomodoroLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroActivityAttributes.self) { context in
            // Lock screen/banner UI
            ZStack {
                // Background based on session type
                backgroundForSessionType(context.state.sessionType)
                
                VStack(spacing: 12) {
                    // Header with session type
                    Text(context.state.sessionType)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // Timer display
                    Text(formattedTime(context.state.remainingTime))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // Visual representation
                    HStack {
                        if context.state.sessionType == "Focus" {
                            Image(systemName: "chair.lounge.fill")
                                .font(.title)
                            
                            Image(systemName: "pawprint.fill")
                                .font(.title)
                                .foregroundColor(.orange)
                        } else {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.title)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding()
            }
            .cornerRadius(16)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.sessionType == "Focus" ? "chair.lounge.fill" : "cup.and.saucer.fill")
                        .foregroundColor(.white)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    sessionProgress(
                        timeRemaining: context.state.remainingTime,
                        totalTime: context.attributes.totalTime
                    )
                }
                
                DynamicIslandExpandedRegion(.center) {
                    Text(formattedTime(context.state.remainingTime))
                        .font(.system(.title2, design: .rounded))
                        .foregroundColor(.white)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.sessionType)
                        .foregroundColor(.white)
                }
                
            } compactLeading: {
                // Compact leading
                Image(systemName: context.state.sessionType == "Focus" ? "chair.lounge.fill" : "cup.and.saucer.fill")
                    .foregroundColor(.white)
            } compactTrailing: {
                // Compact trailing
                Text(formattedTime(context.state.remainingTime))
                    .foregroundColor(.white)
            } minimal: {
                // Minimal UI
                Image(systemName: context.state.sessionType == "Focus" ? "timer" : "cup.and.saucer.fill")
                    .foregroundColor(.white)
            }
            .widgetURL(URL(string: "pomodoro://timer"))
            .keylineTint(colorForSessionType(context.state.sessionType))
        }
    }
    
    // Helper functions
    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func colorForSessionType(_ sessionType: String) -> Color {
        switch sessionType {
        case "Focus":
            return .red
        case "Short Break":
            return .green
        case "Long Break":
            return .blue
        default:
            return .gray
        }
    }
    
    private func backgroundForSessionType(_ sessionType: String) -> some View {
        let color = colorForSessionType(sessionType)
        return LinearGradient(
            gradient: Gradient(colors: [color, color.opacity(0.7)]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func sessionProgress(timeRemaining: TimeInterval, totalTime: TimeInterval) -> some View {
        let progress = 1 - (timeRemaining / totalTime)
        
        return CircularProgressView(progress: progress)
            .frame(width: 30, height: 30)
    }
}

// Circular progress indicator for timer
struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.white.opacity(0.3),
                    lineWidth: 3
                )
            
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    Color.white,
                    style: StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)
        }
    }
}