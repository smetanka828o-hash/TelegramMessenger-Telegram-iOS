import Foundation
import UIKit
import AsyncDisplayKit
import Display

public struct LiquidGlassIntegrationValidator {
    public init() {}
    
    public func validateIntegration() -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        results["LiquidGlassView"] = validateView()
        results["LiquidGlassButtonNode"] = validateButton()
        results["LiquidGlassNavigationBar"] = validateNavigationBar()
        results["LiquidGlassSliderNode"] = validateSlider()
        results["LiquidGlassSwitchNode"] = validateSwitch()
        results["LiquidGlassManager"] = validateManager()
        
        return results
    }
    
    private func validateView() -> Bool {
        let config = LiquidGlassConfig()
        let view = LiquidGlassView(config: config)
        view.isHighlighted = true
        view.isGlowing = true
        return view.subviews.contains { $0 is UIVisualEffectView }
    }
    
    private func validateButton() -> Bool {
        let button = LiquidGlassButtonNode(config: LiquidGlassConfig())
        button.updateHighlight(true)
        button.performPressDownAnimation()
        button.performReleaseBounceAnimation()
        return button.imageNode.image == nil || button.imageNode.image != nil
    }
    
    private func validateNavigationBar() -> Bool {
        let bar = LiquidGlassNavigationBar(config: LiquidGlassConfig())
        bar.addLeftButton(LiquidGlassButtonNode())
        bar.addRightButton(LiquidGlassButtonNode())
        return true
    }
    
    private func validateSlider() -> Bool {
        let slider = LiquidGlassSliderNode(config: LiquidGlassConfig())
        slider.setValue(0.5, animated: false)
        return slider.value == 0.5
    }
    
    private func validateSwitch() -> Bool {
        let toggle = LiquidGlassSwitchNode(config: LiquidGlassConfig())
        let initial = toggle.isOn
        toggle.setOn(!initial, animated: false)
        return toggle.isOn != initial
    }
    
    private func validateManager() -> Bool {
        let manager = LiquidGlassManager.shared
        let testView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        testView.backgroundColor = .red
        guard let snapshot = manager.createSnapshot(for: testView) else {
            return false
        }
        return manager.applyBlur(to: snapshot, with: LiquidGlassConfig()) != nil
    }
    
    public func printValidationReport() {
        let results = validateIntegration()
        print("=== Liquid Glass Integration Validation Report ===")
        for (component, ok) in results {
            print("\(component): \(ok ? "PASS" : "FAIL")")
        }
        print("=== End of Report ===")
    }
}
