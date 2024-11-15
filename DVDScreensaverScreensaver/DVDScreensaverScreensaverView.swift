import Foundation
import ScreenSaver
import SwiftUI
import Cocoa

class DVDScreensaverScreensaverView: ScreenSaverView {
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)

        // Enable layer-backed view for better rendering compatibility with SwiftUI
        wantsLayer = true

        let timeView = ContentView()
        let hostingController = NSHostingController(rootView: timeView)

        // Set frame directly to bounds and enable autoresizing
        hostingController.view.frame = bounds
        hostingController.view.autoresizingMask = [.width, .height]
        addSubview(hostingController.view)
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        fatalError("Not implemented.")
    }
}


@MainActor
struct ContentView: View {
    @State private var position: CGPoint = .zero
    @State private var velocity: CGVector = CGVector(dx: 5, dy: 5)
    @State private var imageColor: Color = .green
    @State private var displayLink = DisplayLink()

    // Dynamically set the image
    private let baseImage: NSImage = {
        if let imagePath = Bundle(for: DVDScreensaverScreensaverView.self).path(forResource: "dvd_logo", ofType: "png"),
           let nsImage = NSImage(contentsOfFile: imagePath) {
            return nsImage
        } else {
            fatalError("Image not found in bundle.")
        }
    }()

    var body: some View {
        GeometryReader { geometry in
            let canvasSize = geometry.size // Get the dynamic canvas size
            let scaledWidth = canvasSize.width * 0.1
            let scaledHeight = scaledWidth * 0.6
            let imageSize: CGSize = CGSize(width: scaledWidth, height: scaledHeight)

            Canvas { [position] context, size in
                // Set the background color to .black
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))

                // Draw image at current position
                let nsTintedImage = baseImage.tinted(with: NSColor(imageColor))
                let image = context.resolve(Image(nsImage: nsTintedImage))

                context.draw(
                    image,
                    in: CGRect(x: position.x, y: position.y, width: imageSize.width, height: imageSize.height)
                )
            }
            .onAppear {
                // Set initial position to the center of the canvas after the view appears
                position = CGPoint(
                    x: (canvasSize.width - imageSize.width) / 2,
                    y: (canvasSize.height - imageSize.height) / 2
                )

                displayLink.start {
                    // Update position based on velocity
                    position.x += velocity.dx
                    position.y += velocity.dy

                    // Check if image hits an edge
                    if position.x + imageSize.width >= canvasSize.width || position.x <= 0  {
                        // Flip horizontal direction
                        velocity.dx *= -1
                        imageColor = Color.random()
                    }

                    if position.y + imageSize.height >= canvasSize.height || position.y <= 0 {
                        // Flip vertical direction
                        velocity.dy *= -1
                        imageColor = Color.random()
                    }
                }
            }
            .onDisappear {
                displayLink.stop()
            }
        }
    }
}

extension Color {
    static func random() -> Color {
        let red = Double.random(in: 0...1)
        let green = Double.random(in: 0...1)
        let blue = Double.random(in: 0...1)
        return Color(red: red, green: green, blue: blue)
    }
}
extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()
        color.set()
        let imageRect = NSRect(origin: .zero, size: image.size)
        imageRect.fill(using: .sourceAtop)
        image.unlockFocus()
        return image
    }
}
