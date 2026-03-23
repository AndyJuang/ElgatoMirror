import AppKit
import QuartzCore

/// A full-screen view that renders captured frames horizontally mirrored.
class MirrorView: NSView {
    private var displayLayer = CALayer()

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = CGColor(gray: 0, alpha: 1)

        displayLayer.backgroundColor = CGColor(gray: 0, alpha: 1)
        displayLayer.frame = bounds
        displayLayer.contentsGravity = .resizeAspect
        displayLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

        // Horizontal flip: scale X by -1 around the layer's centre
        displayLayer.transform = CATransform3DMakeScale(-1, 1, 1)

        layer?.addSublayer(displayLayer)
    }

    /// Call from the main thread to push a new captured frame.
    func display(image: CGImage) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        displayLayer.contents = image
        CATransaction.commit()
    }

    override var isOpaque: Bool { true }
}
