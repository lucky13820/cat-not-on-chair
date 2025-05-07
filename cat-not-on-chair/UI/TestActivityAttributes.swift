import ActivityKit
import Foundation

// Define TestActivityAttributes to be shared between app and widget extension
public struct TestActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var counter: Int
        
        public init(counter: Int) {
            self.counter = counter
        }
    }
    
    public var name: String
    
    public init(name: String) {
        self.name = name
    }
} 