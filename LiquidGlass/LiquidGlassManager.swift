import Foundation
import UIKit
import AsyncDisplayKit
import Display
import MetalEngine

public final class LiquidGlassManager {
    public static let shared = LiquidGlassManager()
    
    private init() {}
    
    /// Делает snapshot в текущих границах view.
    public func createSnapshot(for view: UIView) -> UIImage? {
        guard view.bounds.width > 0, view.bounds.height > 0 else {
            return nil
        }
        
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        view.layer.render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// Применяет blur через CoreImage, учитывая конфиг и пресет производительности.
    public func applyBlur(to image: UIImage, with config: LiquidGlassConfig) -> UIImage? {
        guard let ciImage = CIImage(image: image) else {
            return nil
        }
        
        let radius = config.blurRadius > 0 ? config.blurRadius : config.performance.blurRadius
        
        guard let filter = CIFilter(name: "CIGaussianBlur") else {
            return nil
        }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        
        guard let outputImage = filter.outputImage else {
            return nil
        }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Заглушка для дополнительной вибрации — оставляем картинку как есть.
    public func createVibrancyEffect(for image: UIImage, with config: LiquidGlassConfig) -> UIImage? {
        return image
    }
    
    public func supportsMetal() -> Bool {
        return MTLCreateSystemDefaultDevice() != nil
    }
    
    public func applyMetalEffect(to image: UIImage, with config: LiquidGlassConfig) -> UIImage? {
        guard supportsMetal() else {
            return applyBlur(to: image, with: config)
        }
        // Здесь можно добавить Metal-процессинг; пока используем CI-блюр как fallback.
        return applyBlur(to: image, with: config)
    }
    
    /// Маппинг производительности по модели.
    public func getPerformanceLevel() -> PerformancePreset {
        let model = UIDevice.current.modelName
        
        // Простая эвристика: новые модели -> high, средние -> balanced, остальное -> low.
        let high: [String] = [
            "iPhone16", "iPhone15", "iPhone14", "iPhone13,4", "iPhone14,2", "iPhone14,3", "iPhone14,5"
        ]
        let balanced: [String] = [
            "iPhone12", "iPhone11", "iPhone12,8", "iPhone13,1", "iPhone13,2", "iPhone13,3", "iPhone14,4"
        ]
        
        if high.contains(where: { model.hasPrefix($0) }) {
            return .highPerformance
        } else if balanced.contains(where: { model.hasPrefix($0) }) {
            return .balanced
        } else {
            return .lowPower
        }
    }
}

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
}
