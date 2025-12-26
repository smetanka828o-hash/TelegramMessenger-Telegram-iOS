import Foundation
import UIKit
import AsyncDisplayKit
import Display
import ObjectiveC

public final class LiquidGlassPerformanceTester {
    private final class FrameCounter {
        var frames: Int = 0
        let startTime = CACurrentMediaTime()
    }
    
    private static var counterKey: UInt8 = 0
    
    public init() {}
    
    public func measurePerformance(block: () -> Void) -> TimeInterval {
        let start = CFAbsoluteTimeGetCurrent()
        block()
        return CFAbsoluteTimeGetCurrent() - start
    }
    
    public func measureFrameRate(for view: UIView, duration: TimeInterval = 5.0, completion: @escaping (Double) -> Void) {
        let counter = FrameCounter()
        
        let displayLink = CADisplayLink(target: self, selector: #selector(frameRendered(_:)))
        objc_setAssociatedObject(displayLink, &LiquidGlassPerformanceTester.counterKey, counter, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        displayLink.add(to: .main, forMode: .common)
        
        Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            displayLink.invalidate()
            let elapsed = CACurrentMediaTime() - counter.startTime
            let fps = elapsed > 0 ? Double(counter.frames) / elapsed : 0
            completion(fps)
        }
    }
    
    @objc private func frameRendered(_ link: CADisplayLink) {
        if let counter = objc_getAssociatedObject(link, &LiquidGlassPerformanceTester.counterKey) as? FrameCounter {
            counter.frames += 1
        }
    }
    
    public func testBlurPerformance(config: LiquidGlassConfig, iterations: Int = 100) -> TimeInterval {
        let testImage = generateTestImage()
        let manager = LiquidGlassManager.shared
        
        var totalTime: TimeInterval = 0
        for _ in 0..<iterations {
            let time = measurePerformance {
                _ = manager.applyBlur(to: testImage, with: config)
            }
            totalTime += time
        }
        return totalTime / Double(iterations)
    }
    
    public func testAnimationPerformance(animations: [() -> Void], iterations: Int = 50) -> [TimeInterval] {
        var results: [TimeInterval] = []
        for animation in animations {
            var total: TimeInterval = 0
            for _ in 0..<iterations {
                total += measurePerformance {
                    animation()
                }
            }
            results.append(total / Double(iterations))
        }
        return results
    }
    
    private func generateTestImage() -> UIImage {
        let size = CGSize(width: 300, height: 300)
        return UIGraphicsImageRenderer(size: size).image { context in
            context.cgContext.setFillColor(UIColor.systemBlue.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    
    public func getDevicePerformanceLevel() -> PerformancePreset {
        return LiquidGlassManager.shared.getPerformanceLevel()
    }
    
    public func optimizeForPerformance(config: inout LiquidGlassConfig, targetFrameRate: Double = 60.0) {
        let currentPerformanceLevel = getDevicePerformanceLevel()
        config.performance = currentPerformanceLevel
        
        if targetFrameRate < 60 {
            config.blurRadius = min(config.blurRadius, currentPerformanceLevel.blurRadius * 0.7)
        } else {
            config.blurRadius = currentPerformanceLevel.blurRadius
        }
    }
}
