import AppKit

extension NSScreen {
    var displayID: CGDirectDisplayID {
        let key = NSDeviceDescriptionKey(rawValue: "NSScreenNumber")
        return deviceDescription[key] as? CGDirectDisplayID ?? 0
    }
}
