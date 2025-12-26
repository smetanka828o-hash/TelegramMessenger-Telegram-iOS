import Foundation
import UIKit
import AsyncDisplayKit
import Display

public final class LiquidGlassSliderNode: ASDisplayNode {
    private let trackNode: ASDisplayNode
    private let thumbNode: LiquidGlassButtonNode
    private var config: LiquidGlassConfig
    private var _value: Float = 0.0
    private var tracking = false
    
    public var value: Float {
        get { return _value }
        set { setValue(newValue, animated: false) }
    }
    
    public var onValueChange: ((Float) -> Void)?
    
    public init(config: LiquidGlassConfig = LiquidGlassConfig()) {
        self.config = config
        self.trackNode = ASDisplayNode()
        self.thumbNode = LiquidGlassButtonNode(config: config)
        super.init()
        
        setupView()
    }
    
    private func setupView() {
        self.trackNode.backgroundColor = config.tintColor.withAlphaComponent(0.3)
        self.trackNode.cornerRadius = 1.5
        self.addSubnode(self.trackNode)
        
        self.thumbNode.pressed = { [weak self] in
            self?.handleThumbPress()
        }
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.view.addGestureRecognizer(panGesture)
        
        self.addSubnode(self.thumbNode)
    }
    
    private func handleThumbPress() {
        self.tracking = true
        self.thumbNode.updateGlow(true)
        self.thumbNode.performPressDownAnimation()
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        let location = gesture.location(in: view)
        let newValue = calculateValueFromLocation(location)
        
        switch gesture.state {
        case .began:
            self.tracking = true
            self.thumbNode.updateGlow(true)
            self.thumbNode.performPressDownAnimation()
        case .changed:
            setValue(newValue, animated: false)
            onValueChange?(self._value)
        case .ended, .cancelled:
            self.tracking = false
            self.thumbNode.updateGlow(false)
            self.thumbNode.performReleaseBounceAnimation()
            performJellyEffect()
        default:
            break
        }
    }
    
    private func calculateValueFromLocation(_ location: CGPoint) -> Float {
        let x = max(0, min(location.x, self.bounds.width - self.thumbNode.bounds.width))
        return Float(x / (self.bounds.width - self.thumbNode.bounds.width))
    }
    
    public func setValue(_ value: Float, animated: Bool) {
        let clampedValue = max(0.0, min(1.0, value))
        self._value = clampedValue
        
        if !tracking {
            updateThumbPosition(animated: animated)
        }
    }
    
    private func updateThumbPosition(animated: Bool = true) {
        let trackWidth = self.bounds.width - self.thumbNode.bounds.width
        let xPosition = CGFloat(self._value) * trackWidth
        
        if animated {
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: { [weak self] in
                guard let self else { return }
                self.thumbNode.layer.position = CGPoint(
                    x: xPosition + self.thumbNode.bounds.width / 2,
                    y: self.bounds.height / 2
                )
            })
        } else {
            self.thumbNode.frame = CGRect(
                x: xPosition,
                y: (self.bounds.height - self.thumbNode.bounds.height) / 2,
                width: self.thumbNode.bounds.width,
                height: self.thumbNode.bounds.height
            )
        }
    }
    
    private func performJellyEffect() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.2)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        self.thumbNode.layer.transform = CATransform3DConcat(
            CATransform3DMakeScale(1.2, 0.8, 1.0),
            self.thumbNode.layer.transform
        )
        CATransaction.commit()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.15)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
            self.thumbNode.layer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)
            CATransaction.commit()
        }
    }
    
    public func updateConfig(_ config: LiquidGlassConfig) {
        self.config = config
        self.trackNode.backgroundColor = config.tintColor.withAlphaComponent(0.3)
        self.thumbNode.updateConfig(config)
    }
    
    public override func layout() {
        super.layout()
        
        let trackHeight: CGFloat = 3.0
        self.trackNode.frame = CGRect(
            x: self.thumbNode.bounds.width / 2,
            y: (self.bounds.height - trackHeight) / 2,
            width: self.bounds.width - self.thumbNode.bounds.width,
            height: trackHeight
        )
        
        self.thumbNode.updateCornerRadius(self.thumbNode.bounds.height / 2)
        updateThumbPosition(animated: false)
    }
}
