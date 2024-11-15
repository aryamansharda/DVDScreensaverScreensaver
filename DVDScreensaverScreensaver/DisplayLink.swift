//
//  DisplayLink.swift
//  DVDScreensaverScreensaver
//
//  Created by Aryaman Sharda on 11/14/24.
//

import CoreVideo

@MainActor
final class DisplayLink {
    private var displayLink: CVDisplayLink?
    private var update: (() -> Void)?

    func start(update: @escaping () -> Void) {
        self.update = update

        // Create a CVDisplayLink and set its output callback
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        CVDisplayLinkSetOutputCallback(displayLink!, { (_, _, _, _, _, userInfo) -> CVReturn in
            let displayLink = unsafeBitCast(userInfo, to: DisplayLink.self)
            DispatchQueue.main.async {
                displayLink.frame()
            }
            return kCVReturnSuccess
        }, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))

        // Start the display link
        CVDisplayLinkStart(displayLink!)
    }

    func stop() {
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
        update = nil
    }

    @objc private func frame() {
        update?()
    }
}
