import Foundation
import UIKit
import AsyncDisplayKit
import Display

public final class LiquidGlassSwitchNode: ASDisplayNode {
    private let trackNode: ASDisplayNode
    private let thumbNode: LiquidGlassButtonNode
    private var config: LiquidGlassConfig
    private var _isOn: Bool = false
    private var tracking = false
    
    public var isOn: Bool {
        get { return _isOn }
        set { setOn(newValue, animated: false) }
    }
    
    public var onToggle: ((Bool) -> Void)?
    
    public init(config: LiquidGlassConfig = LiquidGlassConfig()) {
        self.config = config
        self.trackNode = ASDisplayNode()
        self.thumbNode = LiquidGlassButtonNode(config: config)
        super.init()
        
        setupView()
    }
    
    private func setupView() {
        self.trackNode.isUserInteractionEnabled = false
        self.addSubnode(self.trackNode)
        
        self.thumbNode.pressed = { [weak self] in
            self?.toggle()
        }
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.view.addGestureRecognizer(panGesture)
        
        self.addSubnode(self.thumbNode)
    }
    
    public func setOn(_ isOn: Bool, animated: Bool) {
        if self._isOn == isOn { return }
        
        self._isOn = isOn
        updateThumbPosition(animated: animated)
        updateTrackColor()
        
        if !tracking {
            onToggle?(self._isOn)
        }
    }
    
    private func toggle() {
        setOn(!_isOn, animated: true)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        let location = gesture.location(in: view)
        let newValue = location.x > (self.bounds.width / 2)
        
        switch gesture.state {
        case .began:
            self.tracking = true
            self.thumbNode.updateGlow(true)
            self.thumbNode.performPressDownAnimation()
        case .changed:
            let xPosition = max(
                self.bounds.height / 2,
                min(location.x, self.bounds.width - self.bounds.height / 2)
            )
            
            self.thumbNode.layer.position = CGPoint(x: xPosition, y: self.bounds.height / 2)
        case .ended, .cancelled:
            self.tracking = false
            setOn(newValue, animated: true)
            self.thumbNode.updateGlow(false)
            self.thumbNode.performReleaseBounceAnimation()
        default:
            break
        }
    }
    
    private func updateThumbPosition(animated: Bool = true) {
        let thumbDiameter = min(self.bounds.height, self.bounds.width) - 4
        let trackWidth = self.bounds.width - thumbDiameter
        
        let xPosition: CGFloat = _isOn ? trackWidth + 2 : 2
        
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.thumbNode.layer.position = CGPoint(
                    x: xPosition + thumbDiameter / 2,
                    y: strongSelf.bounds.height / 2
                )
            })
        } else {
            self.thumbNode.frame = CGRect(
                x: xPosition,
                y: 2,
                width: thumbDiameter,
                height: thumbDiameter
            )
        }
    }
    
    private func updateTrackColor() {
        // Фон трека без blur, только цветовая подсветка состояния
        let color = _isOn ? config.tintColor.withAlphaComponent(0.5) : config.tintColor.withAlphaComponent(0.22)
        self.trackNode.backgroundColor = color
    }
    
    public func updateConfig(_ config: LiquidGlassConfig) {
        self.config = config
        self.thumbNode.updateConfig(config)
        updateTrackColor()
    }
    
    public override func layout() {
        super.layout()
        
        self.trackNode.frame = self.bounds
        self.trackNode.cornerRadius = self.bounds.height / 2
        updateTrackColor()
        
        let thumbDiameter = min(self.bounds.height, self.bounds.width) - 4
        self.thumbNode.bounds = CGRect(x: 0, y: 0, width: thumbDiameter, height: thumbDiameter)
        self.thumbNode.updateCornerRadius(thumbDiameter / 2)
        updateThumbPosition(animated: false)
    }
}
