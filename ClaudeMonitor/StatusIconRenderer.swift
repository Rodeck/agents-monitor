import AppKit

enum StatusIconRenderer {
    static func makeIcon(color: NSColor, size: CGFloat = 18) -> NSImage {
        let image = NSImage(
            size: NSSize(width: size, height: size),
            flipped: false
        ) { rect in
            color.setFill()
            NSBezierPath(ovalIn: rect).fill()
            return true
        }
        image.isTemplate = false
        return image
    }
}
