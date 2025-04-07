//
//  widgetLiveActivity.swift
//  widget
//
//  Created by Ryan Yao on 2025-04-07.
//

import ActivityKit
import WidgetKit
import SwiftUI

// Match the definition in the main app
struct TimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var timeRemaining: TimeInterval
        var endTime: Date
        var isBreakTime: Bool
        
        init(timeRemaining: TimeInterval, endTime: Date, isBreakTime: Bool) {
            self.timeRemaining = timeRemaining
            self.endTime = endTime
            self.isBreakTime = isBreakTime
        }
    }
}

struct widgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            // Lock screen/banner UI goes here
            HStack {
                VStack(alignment: .leading) {
                    Text(context.state.isBreakTime ? "Break Time" : "Focus Time")
                        .font(.headline)
                        .foregroundColor(context.state.isBreakTime ? .green : .blue)
                    
                    // Use TimelineView for auto-updating timer even when not being updated by app
                    TimelineView(.periodic(from: Date(), by: 60)) { _ in
                        Text(timeString(from: max(0, context.state.endTime.timeIntervalSinceNow)))
                            .font(.system(size: 24, weight: .bold))
                            .monospacedDigit()
                            .contentTransition(.numericText()) // Smooth transitions
                    }
                }
                
                Spacer()
                
                // Use TimelineView for auto-updating progress
                TimelineView(.animation) { _ in
                    CircularProgressView(
                        progress: progress(for: context),
                        color: context.state.isBreakTime ? .green : .blue
                    )
                    .frame(width: 40, height: 40)
                }
            }
            .padding()
            .activityBackgroundTint(Color.white.opacity(0.8))
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.state.isBreakTime ? "Break Time" : "Focus Time")
                            .font(.headline)
                            .foregroundColor(context.state.isBreakTime ? .green : .blue)
                    } icon: {
                        Image(systemName: context.state.isBreakTime ? "cup.and.saucer.fill" : "timer")
                            .foregroundColor(context.state.isBreakTime ? .green : .blue)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    // Use TimelineView for auto-updating
                    TimelineView(.periodic(from: Date(), by: 1)) { _ in
                        Text(timeString(from: max(0, context.state.endTime.timeIntervalSinceNow)))
                            .font(.system(size: 24, weight: .bold))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .foregroundColor(context.state.isBreakTime ? .green : .blue)
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    // Use TimelineView for auto-updating progress
                    TimelineView(.periodic(from: Date(), by: 0.5)) { _ in
                        ProgressView(value: progress(for: context))
                            .progressViewStyle(.linear)
                            .tint(context.state.isBreakTime ? .green : .blue)
                            .frame(height: 6)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        if context.state.isBreakTime {
                            Text("Relax and recharge!")
                        } else {
                            Text("Stay focused!")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
            } compactLeading: {
                // Compact Leading View
                Image(systemName: context.state.isBreakTime ? "cup.and.saucer.fill" : "timer")
                    .foregroundColor(context.state.isBreakTime ? .green : .blue)
            } compactTrailing: {
                // Compact Trailing View
                // Use TimelineView for auto-updating
                TimelineView(.periodic(from: Date(), by: 1)) { _ in
                    Text(timeString(from: max(0, context.state.endTime.timeIntervalSinceNow)))
                        .font(.caption2)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .foregroundColor(context.state.isBreakTime ? .green : .blue)
                }
            } minimal: {
                // Minimal View
                Image(systemName: context.state.isBreakTime ? "cup.and.saucer.fill" : "timer")
                    .foregroundColor(context.state.isBreakTime ? .green : .blue)
            }
        }
    }
    
    private func progress(for context: ActivityViewContext<TimerAttributes>) -> Double {
        // Calculate total duration from end time and time remaining
        let totalTime = context.state.endTime.timeIntervalSince(
            context.state.endTime.addingTimeInterval(-context.state.timeRemaining)
        )
        
        // Get current time from endTime - now, not from timeRemaining property
        // This ensures the progress updates even if the app isn't updating the activity
        let currentTimeRemaining = max(0, context.state.endTime.timeIntervalSinceNow)
        let currentProgress = 1.0 - (currentTimeRemaining / totalTime)
        
        return min(max(currentProgress, 0.0), 1.0) // Ensure value is between 0 and 1
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// For preview in Xcode
extension TimerAttributes {
    fileprivate static var preview: TimerAttributes {
        TimerAttributes()
    }
}

extension TimerAttributes.ContentState {
    fileprivate static var focusing: TimerAttributes.ContentState {
        TimerAttributes.ContentState(
            timeRemaining: 15 * 60, // 15 minutes
            endTime: Date().addingTimeInterval(15 * 60),
            isBreakTime: false
        )
    }
    
    fileprivate static var onBreak: TimerAttributes.ContentState {
        TimerAttributes.ContentState(
            timeRemaining: 5 * 60, // 5 minutes
            endTime: Date().addingTimeInterval(5 * 60),
            isBreakTime: true
        )
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress) // Smooth progress animation
        }
    }
}

#Preview("Notification", as: .content, using: TimerAttributes.preview) {
   widgetLiveActivity()
} contentStates: {
    TimerAttributes.ContentState.focusing
    TimerAttributes.ContentState.onBreak
}

