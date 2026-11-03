// Draws Datograph's app icon and writes Resources/AppIcon.icns.
// Run from the repository root: swift scripts/make-icon.swift
import AppKit
import SwiftUI

struct AppIcon: View {
    private let indigoTop = Color(red: 0.40, green: 0.45, blue: 1.00)
    private let indigoBottom = Color(red: 0.22, green: 0.17, blue: 0.66)
    private let coral = Color(red: 1.00, green: 0.42, blue: 0.36)

    var body: some View {
        ZStack {
            // The macOS icon grid: an 824pt rounded square centered on a 1024pt canvas.
            RoundedRectangle(cornerRadius: 185, style: .continuous)
                .fill(LinearGradient(colors: [indigoTop, indigoBottom], startPoint: .top, endPoint: .bottom))
                .frame(width: 824, height: 824)
                .shadow(color: .black.opacity(0.25), radius: 10, y: 6)

            // A calendar page: a grid of days with today highlighted.
            VStack(spacing: 0) {
                coral.frame(height: 130)
                Grid(horizontalSpacing: 26, verticalSpacing: 26) {
                    ForEach(0..<4, id: \.self) { row in
                        GridRow {
                            ForEach(0..<5, id: \.self) { column in
                                Circle()
                                    .fill(row == 1 && column == 2 ? coral : Color(white: 0.82))
                                    .frame(width: 58, height: 58)
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .frame(width: 520, height: 540)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 64, style: .continuous))
            .compositingGroup() // shadow the card as a whole, not each dot inside it
            .shadow(color: .black.opacity(0.25), radius: 20, y: 12)
        }
        .frame(width: 1024, height: 1024)
    }
}

let sizes: [(name: String, pixels: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32), ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256), ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

try MainActor.assumeIsolated {
    for (name, pixels) in sizes {
        // Each size is drawn from the vector view rather than downscaled, so small sizes stay sharp.
        let renderer = ImageRenderer(content: AppIcon())
        renderer.scale = CGFloat(pixels) / 1024
        guard let image = renderer.cgImage,
              let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
        else { fatalError("Couldn't render \(name)") }
        try png.write(to: iconset.appendingPathComponent("\(name).png"))
    }
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else { fatalError("iconutil failed") }
print("Wrote Resources/AppIcon.icns")
