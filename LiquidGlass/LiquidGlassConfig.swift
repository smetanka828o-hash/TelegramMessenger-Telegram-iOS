import Foundation
import UIKit

public struct LiquidGlassConfig {
    public var blurRadius: CGFloat
    public var tintColor: UIColor
    public var vibrancy: CGFloat
    public var performance: PerformancePreset
    
    public init(blurRadius: CGFloat = 15.0, tintColor: UIColor = UIColor.white, vibrancy: CGFloat = 0.15, performance: PerformancePreset = .balanced) {
        self.blurRadius = blurRadius
        self.tintColor = tintColor
        self.vibrancy = vibrancy
        self.performance = performance
    }
}

public enum PerformancePreset {
    case lowPower
    case balanced
    case highPerformance
    
    var blurRadius: CGFloat {
        switch self {
        case .lowPower:
            return 10.0
        case .balanced:
            return 15.0
        case .highPerformance:
            return 20.0
        }
    }
}