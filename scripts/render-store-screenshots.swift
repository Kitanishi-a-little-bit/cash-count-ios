import AppKit

// Compose store artwork around unmodified simulator captures.
let input = URL(fileURLWithPath: "screenshots/iphone-cash-count.png")
guard let screenshot = NSImage(contentsOf: input) else { fatalError("Missing simulator screenshot") }
let output = URL(fileURLWithPath: "screenshots/store-iphone", isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let width = 1206
let height = 2622
let ink = NSColor(red: 0.15, green: 0.22, blue: 0.20, alpha: 1)
let muted = NSColor(red: 0.38, green: 0.44, blue: 0.40, alpha: 1)
let designs: [(String, String, String, String)] = [
    ("01-count", "枚数を入れるだけ。", "紙幣・硬貨の小計と合計を、すぐに。", "紙幣も、小銭も。まとめて計算"),
    ("02-rolls", "棒金も、そのまま。", "バラの枚数とロール数をまとめて計算。", "1ロール＝50枚で自動計算"),
    ("03-accounts", "レジと金庫を、別々に。", "切り替えて入力。内容は端末に自動保存。", "ログイン不要・オフラインで使える")
]

func text(_ value: String, top: CGFloat, size: CGFloat, color: NSColor, bold: Bool = false) {
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    let font = NSFont.systemFont(ofSize: size, weight: bold ? .bold : .regular)
    let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: style]
    let rect = NSRect(x: 50, y: CGFloat(height) - top - size * 1.7, width: CGFloat(width) - 100, height: size * 1.7)
    (value as NSString).draw(in: rect, withAttributes: attributes)
}

for (name, title, subtitle, footer) in designs {
    // Core Graphics drawing requires a supported 32-bit RGB layout. A 24-bit
    // NSBitmapImageRep may exist but cannot provide an NSGraphicsContext.
    guard let canvas = CGContext(data: nil, width: width, height: height,
                                 bitsPerComponent: 8, bytesPerRow: width * 4,
                                 space: CGColorSpaceCreateDeviceRGB(),
                                 bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
    else { fatalError("Cannot create opaque 32-bit RGB canvas") }
    let context = NSGraphicsContext(cgContext: canvas, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    NSColor(red: 0.97, green: 0.96, blue: 0.92, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))).fill()
    text("レジと金庫", top: 105, size: 34, color: muted, bold: true)
    text(title, top: 205, size: 68, color: ink, bold: true)
    text(subtitle, top: 320, size: 34, color: muted)

    // Retain the entire real app screen; do not recreate UI or stretch it.
    let area = NSRect(x: 105, y: 205, width: 996, height: 1960)
    let scale = min(area.width / screenshot.size.width, area.height / screenshot.size.height)
    let size = NSSize(width: screenshot.size.width * scale, height: screenshot.size.height * scale)
    let rect = NSRect(x: area.midX - size.width / 2, y: area.midY - size.height / 2, width: size.width, height: size.height)
    ink.setFill()
    NSBezierPath(roundedRect: rect.insetBy(dx: -8, dy: -8), xRadius: 28, yRadius: 28).fill()
    screenshot.draw(in: rect, from: .zero, operation: .copy, fraction: 1)
    text(footer, top: 2460, size: 34, color: ink, bold: true)
    NSGraphicsContext.restoreGraphicsState()
    guard let image = canvas.makeImage() else { fatalError("Cannot export rendered image") }
    let bitmap = NSBitmapImageRep(cgImage: image)
    guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("PNG encoding failed") }
    try png.write(to: output.appendingPathComponent(name + ".png"))
    print("Created \(name).png: \(width)x\(height), RGB")
}
