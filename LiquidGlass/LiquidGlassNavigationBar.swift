import Foundation
import UIKit
import AsyncDisplayKit
import Display

public class LiquidGlassNavigationBar: ASDisplayNode {
    private var liquidGlassView: LiquidGlassView?
    private var titleNode: ImmediateTextNode?
    private var leftButtonNodes: [ASDisplayNode] = []
    private var rightButtonNodes: [ASDisplayNode] = []
    private var config: LiquidGlassConfig
    
    public init(config: LiquidGlassConfig = LiquidGlassConfig(), title: String? = nil) {
        self.config = config
        super.init()
        
        setupView()
        
        if let title = title {
            self.titleNode = ImmediateTextNode()
            self.titleNode?.attributedText = NSAttributedString(string: title, attributes: [.font: UIFont.boldSystemFont(ofSize: 18), .foregroundColor: config.tintColor])
        }
    }
    
    private func setupView() {
        let liquidGlassView = LiquidGlassView(config: config)
        liquidGlassView.isUserInteractionEnabled = false
        self.liquidGlassView = liquidGlassView
        self.setViewBlock({
            return liquidGlassView
        })
        
        if let titleNode = self.titleNode {
            self.addSubnode(titleNode)
        }
    }
    
    public func updateConfig(_ config: LiquidGlassConfig) {
        self.config = config
        self.liquidGlassView?.updateBlurEffect()
    }
    
    public func setTitle(_ title: String) {
        self.titleNode?.attributedText = NSAttributedString(string: title, attributes: [.font: UIFont.boldSystemFont(ofSize: 18), .foregroundColor: config.tintColor])
    }
    
    public func addLeftButton(_ buttonNode: ASDisplayNode) {
        self.leftButtonNodes.append(buttonNode)
        self.addSubnode(buttonNode)
        self.setNeedsLayout()
    }
    
    public func addRightButton(_ buttonNode: ASDisplayNode) {
        self.rightButtonNodes.append(buttonNode)
        self.addSubnode(buttonNode)
        self.setNeedsLayout()
    }
    
    public func removeLeftButton(_ buttonNode: ASDisplayNode) {
        if let index = self.leftButtonNodes.firstIndex(where: { $0 === buttonNode }) {
            self.leftButtonNodes.remove(at: index)
            buttonNode.removeFromSupernode()
            self.setNeedsLayout()
        }
    }
    
    public func removeRightButton(_ buttonNode: ASDisplayNode) {
        if let index = self.rightButtonNodes.firstIndex(where: { $0 === buttonNode }) {
            self.rightButtonNodes.remove(at: index)
            buttonNode.removeFromSupernode()
            self.setNeedsLayout()
        }
    }
    
    public override func layout() {
        super.layout()
        
        guard let liquidGlassView = self.liquidGlassView else { return }
        
        // Устанавливаем размер и положение основного фона
        liquidGlassView.frame = self.bounds
        liquidGlassView.updateCornerRadius(0)
        
        // Позиционируем заголовок по центру
        if let titleNode = self.titleNode {
            let titleSize = titleNode.updateLayout(CGSize(width: 200, height: 30)) // Ограничиваем ширину для центрирования
            titleNode.frame = CGRect(
                origin: CGPoint(
                    x: (self.bounds.width - titleSize.width) / 2,
                    y: (self.bounds.height - titleSize.height) / 2
                ),
                size: titleSize
            )
        }
        
        // Позиционируем левые кнопки
        var leftOffset: CGFloat = 8
        for buttonNode in self.leftButtonNodes {
            let buttonSize = buttonNode.measure(CGSize(width: 44, height: 44))
            buttonNode.frame = CGRect(
                origin: CGPoint(x: leftOffset, y: (self.bounds.height - buttonSize.height) / 2),
                size: buttonSize
            )
            leftOffset += buttonSize.width + 8
        }
        
        // Позиционируем правые кнопки
        var rightOffset: CGFloat = self.bounds.width - 8
        for buttonNode in self.rightButtonNodes.reversed() { // Разворачиваем для правильного порядка
            let buttonSize = buttonNode.measure(CGSize(width: 44, height: 44))
            rightOffset -= buttonSize.width
            buttonNode.frame = CGRect(
                origin: CGPoint(x: rightOffset, y: (self.bounds.height - buttonSize.height) / 2),
                size: buttonSize
            )
            rightOffset -= 8
        }
    }
    
    // Метод для обновления эффекта при скролле
    public func updateForScrollOffset(_ offset: CGFloat) {
        // При прокрутке может изменяться прозрачность или интенсивность эффекта
        let normalizedOffset = min(max(offset, 0), 100) / 100 // Нормализуем смещение к 0-1
        let alpha = 1.0 - (normalizedOffset * 0.3) // Уменьшаем прозрачность при скролле вниз
        
        self.liquidGlassView?.alpha = alpha
    }
}