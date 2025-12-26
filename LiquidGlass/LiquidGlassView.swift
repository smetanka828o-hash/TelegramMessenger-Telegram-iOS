import Foundation
import UIKit
import AsyncDisplayKit
import Display
import ImageBlur
import MetalEngine

public class LiquidGlassView: UIView {
    private var blurEffectView: UIVisualEffectView?
    private var vibrancyEffectView: UIVisualEffectView?
    private var backgroundView: UIView?
    private var highlightLayer: CALayer?
    private var glowLayer: CALayer?
    private var config: LiquidGlassConfig
    private var animationLayers: [CALayer] = []
    
    public var isHighlighted: Bool = false {
        didSet {
            updateHighlight()
        }
    }
    
    public var isGlowing: Bool = false {
        didSet {
            updateGlow()
        }
    }
    
    public init(config: LiquidGlassConfig = LiquidGlassConfig()) {
        self.config = config
        super.init(frame: CGRect.zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        self.config = LiquidGlassConfig()
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        self.backgroundColor = UIColor.clear
        createBlurEffect()
        createHighlightLayer()
        createGlowLayer()
    }
    
    private func createBlurEffect() {
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.layer.cornerRadius = 0
        blurEffectView.layer.masksToBounds = true
        self.blurEffectView = blurEffectView
        self.addSubview(blurEffectView)
        
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
        vibrancyEffectView.frame = self.bounds
        vibrancyEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.vibrancyEffectView = vibrancyEffectView
        blurEffectView.contentView.addSubview(vibrancyEffectView)
    }
    
    private func createHighlightLayer() {
        let highlightLayer = CALayer()
        highlightLayer.backgroundColor = config.tintColor.withAlphaComponent(0.12).cgColor
        highlightLayer.cornerRadius = 0
        highlightLayer.masksToBounds = true
        highlightLayer.opacity = 0.0
        self.highlightLayer = highlightLayer
        self.layer.addSublayer(highlightLayer)
    }
    
    private func createGlowLayer() {
        let glowLayer = CALayer()
        glowLayer.backgroundColor = config.tintColor.withAlphaComponent(0.18).cgColor
        glowLayer.cornerRadius = 0
        glowLayer.masksToBounds = true
        glowLayer.opacity = 0.0
        self.glowLayer = glowLayer
        self.layer.addSublayer(glowLayer)
    }
    
    public func updateCornerRadius(_ radius: CGFloat) {
        self.layer.cornerRadius = radius
        self.blurEffectView?.layer.cornerRadius = radius
        self.highlightLayer?.cornerRadius = radius
        self.glowLayer?.cornerRadius = radius
    }
    
    private func updateHighlight() {
        let targetOpacity: Float = isHighlighted ? 1.0 : 0.0
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.highlightLayer?.opacity = targetOpacity
        CATransaction.commit()
        
        // Анимация при изменении состояния
        if isHighlighted {
            self.highlightLayer?.opacity = 0.0
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.1)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
            self.highlightLayer?.opacity = 1.0
            CATransaction.commit()
        }
    }
    
    private func updateGlow() {
        let targetOpacity: Float = isGlowing ? 1.0 : 0.0
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.glowLayer?.opacity = targetOpacity
        CATransaction.commit()
        
        // Анимация при изменении состояния
        if isGlowing {
            self.glowLayer?.opacity = 0.0
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.22)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
            self.glowLayer?.opacity = 0.18
            CATransaction.commit()
        }
    }
    
    public func performPressDownAnimation() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.1)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
        self.layer.transform = CATransform3DMakeScale(0.96, 0.96, 1.0)
        CATransaction.commit()
    }
    
    public func performReleaseBounceAnimation() {
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [0.96, 1.08, 0.99, 1.0]
        animation.keyTimes = [0.0, 0.35, 0.70, 1.0]
        animation.duration = 0.52
        animation.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.8, 0.2, 1.0)
        
        self.layer.add(animation, forKey: "bounce")
        self.layer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)
    }
    
    public func performStretchAnimation() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.28)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
        self.layer.transform = CATransform3DMakeScale(1.12, 0.92, 1.0)
        CATransaction.commit()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.1)
            self.layer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)
            CATransaction.commit()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Обновляем размеры внутренних слоев
        if let blurEffectView = self.blurEffectView {
            blurEffectView.frame = self.bounds
        }
        
        if let vibrancyEffectView = self.vibrancyEffectView {
            vibrancyEffectView.frame = self.bounds
        }
        
        if let highlightLayer = self.highlightLayer {
            highlightLayer.frame = self.bounds
        }
        
        if let glowLayer = self.glowLayer {
            glowLayer.frame = self.bounds
        }
    }
    
    // Метод для обновления эффекта размытия
    public func updateBlurEffect() {
        // Обновляем blur effect с учетом производительности
        if config.performance == .lowPower {
            // Используем упрощенный эффект для экономии ресурсов
            let blurEffect = UIBlurEffect(style: .light)
            self.blurEffectView?.effect = blurEffect
        } else {
            // Используем более качественный эффект
            let blurEffect = UIBlurEffect(style: .systemMaterial)
            self.blurEffectView?.effect = blurEffect
        }
    }
    
    // Метод для получения snapshot для размытия
    public func captureSnapshotForBlur() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        self.layer.render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}