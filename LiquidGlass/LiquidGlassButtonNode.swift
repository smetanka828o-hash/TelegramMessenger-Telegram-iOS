import Foundation
import UIKit
import AsyncDisplayKit
import Display

public final class LiquidGlassButtonNode: ASDisplayNode {
    public let imageNode: ASImageNode
    private var titleNode: ImmediateTextNode?
    private var liquidGlassView: LiquidGlassView?
    private var config: LiquidGlassConfig
    private var targets: [(target: AnyObject, action: Selector)] = []
    
    /// Колбэк изменения выделения (совместим с уже существующим highligthedChanged).
    public var highligthedChanged: ((Bool) -> Void)?
    
    /// Замыкание на tap.
    public var pressed: (() -> Void)?
    
    public init(config: LiquidGlassConfig = LiquidGlassConfig(), icon: UIImage? = nil, title: String? = nil) {
        self.config = config
        self.imageNode = ASImageNode()
        super.init()
        
        setupView()
        
        if let icon = icon {
            self.imageNode.image = icon
        }
        
        if let title = title {
            let titleNode = ImmediateTextNode()
            titleNode.attributedText = NSAttributedString(
                string: title,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: config.tintColor
                ]
            )
            self.titleNode = titleNode
            self.addSubnode(titleNode)
        }
    }
    
    private func setupView() {
        let glassView = LiquidGlassView(config: config)
        glassView.isUserInteractionEnabled = false
        self.liquidGlassView = glassView
        self.setViewBlock { glassView }
        
        self.imageNode.displaysAsynchronously = false
        self.imageNode.displayWithoutProcessing = true
        self.addSubnode(self.imageNode)
    }
    
    public var image: UIImage? {
        get { self.imageNode.image }
        set { self.imageNode.image = newValue }
    }
    
    public func updateCornerRadius(_ radius: CGFloat) {
        self.liquidGlassView?.updateCornerRadius(radius)
    }
    
    public func updateConfig(_ config: LiquidGlassConfig) {
        self.config = config
        self.liquidGlassView?.updateBlurEffect()
    }
    
    public func updateHighlight(_ isHighlighted: Bool) {
        self.liquidGlassView?.isHighlighted = isHighlighted
        self.highligthedChanged?(isHighlighted)
    }
    
    public func updateGlow(_ isGlowing: Bool) {
        self.liquidGlassView?.isGlowing = isGlowing
    }
    
    public func performPressDownAnimation() {
        self.liquidGlassView?.performPressDownAnimation()
    }
    
    public func performReleaseBounceAnimation() {
        self.liquidGlassView?.performReleaseBounceAnimation()
    }
    
    public func performStretchAnimation() {
        self.liquidGlassView?.performStretchAnimation()
    }
    
    /// Совместимость с addTarget(..., .touchUpInside)
    public func addTarget(_ target: AnyObject?, action: Selector, forControlEvents: UIControl.Event) {
        guard forControlEvents == .touchUpInside, let target else {
            return
        }
        self.targets.append((target, action))
    }
    
    private func sendActions() {
        self.pressed?()
        for entry in targets {
            _ = entry.target.perform(entry.action, with: self)
        }
    }
    
    public override func layout() {
        super.layout()
        
        guard let liquidGlassView = self.liquidGlassView else { return }
        
        liquidGlassView.frame = self.bounds
        liquidGlassView.updateCornerRadius(self.bounds.height / 2) // капсула по умолчанию
        
        let iconSize = CGSize(width: min(24, self.bounds.width / 2), height: min(24, self.bounds.height / 2))
        self.imageNode.frame = CGRect(
            origin: CGPoint(
                x: (self.bounds.width - iconSize.width) / 2,
                y: (self.bounds.height - iconSize.height) / 2
            ),
            size: iconSize
        )
        
        if let titleNode = self.titleNode {
            let titleSize = titleNode.updateLayout(self.bounds.size)
            titleNode.frame = CGRect(
                origin: CGPoint(
                    x: (self.bounds.width - titleSize.width) / 2,
                    y: self.bounds.height + 8
                ),
                size: titleSize
            )
        }
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        updateHighlight(true)
        performPressDownAnimation()
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        updateHighlight(false)
        performReleaseBounceAnimation()
        if let touch = touches.first, self.bounds.contains(touch.location(in: self.view)) {
            sendActions()
        }
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        updateHighlight(false)
        performReleaseBounceAnimation()
    }
}
