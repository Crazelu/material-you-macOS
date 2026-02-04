import Cocoa
import FlutterMacOS
import ScreenCaptureKit
import UniformTypeIdentifiers

@main
class AppDelegate: FlutterAppDelegate {
  private let channelName = "wallpaper/imageStream"
  private var eventSink: FlutterEventSink?
  private var pollTimer: Timer?
  private var lastImage: CGImage?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    guard
      let controller = mainFlutterWindow?.contentViewController
        as? FlutterViewController
    else { return }

    let eventChannel = FlutterEventChannel(
      name: channelName,
      binaryMessenger: controller.engine.binaryMessenger
    )

    eventChannel.setStreamHandler(self)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(
    _ sender: NSApplication
  ) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication)
    -> Bool
  {
    return true
  }
}

extension AppDelegate: FlutterStreamHandler {

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {

    self.eventSink = events
    startPolling()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    pollTimer?.invalidate()
    pollTimer = nil
    eventSink = nil
    return nil
  }
}

extension AppDelegate {

  private func startPolling() {
    pollTimer?.invalidate()

    pollTimer = Timer.scheduledTimer(
      withTimeInterval: 1.0,
      repeats: true
    ) { [weak self] _ in
      self?.pollWallpaper()
    }
  }

  private func pollWallpaper() {
    Task {
      if let image = await captureWallpaper(maxPixelSize: 64) {
        await handleCapturedImage(image)
      }
    }
  }

  @MainActor
  private func handleCapturedImage(_ image: CGImage) {
    if lastImage != nil && image.isEquivalentTo(lastImage!) {
      return
    }

    lastImage = image

    let bitmap = NSBitmapImageRep(cgImage: image)
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
      return
    }

    eventSink?(FlutterStandardTypedData(bytes: data))
  }

  private func captureWallpaper(maxPixelSize: CGFloat) async -> CGImage? {
    do {

      let availableContent: SCShareableContent
      do {
        availableContent = try await SCShareableContent.excludingDesktopWindows(
          false,
          onScreenWindowsOnly: true
        )
      } catch {
        return nil
      }

      guard let display = availableContent.displays.first else {
        return nil
      }

      let excludedApps = availableContent.applications.filter {
        $0.bundleIdentifier != "com.apple.wallpaper.agent"
      }

      let contentFilter = SCContentFilter(
        display: display,
        excludingApplications: excludedApps,
        exceptingWindows: []
      )

      let configuration = SCStreamConfiguration()
      if let screen = NSScreen.main {
        configuration.width = Int(
          screen.frame.width * screen.backingScaleFactor
        )
        configuration.height = Int(
          screen.frame.height * screen.backingScaleFactor
        )
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.showsCursor = true
      } else {
        return nil
      }

      let image: CGImage = try await SCScreenshotManager.captureImage(
        contentFilter: contentFilter,
        configuration: configuration
      )

      return image.cropped()?.scaled(maxPixelSize)

    } catch {
      return nil
    }
  }
}

extension CGImage {
  func rgbaBytes() -> [UInt8]? {
    let width = self.width
    let height = self.height
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel

    var buffer = [UInt8](
      repeating: 0,
      count: height * bytesPerRow
    )

    guard
      let context = CGContext(
        data: &buffer,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else {
      return nil
    }

    context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
    return buffer
  }

  func scaled(_ maxPixelSize: CGFloat) -> CGImage? {
    let data = NSMutableData()
    guard
      let dest = CGImageDestinationCreateWithData(
        data,
        UTType.png.identifier as CFString,
        1,
        nil
      )
    else { return nil }

    CGImageDestinationAddImage(dest, self, nil)
    CGImageDestinationFinalize(dest)

    guard let source = CGImageSourceCreateWithData(data, nil) else {
      return nil
    }

    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
    ]

    return CGImageSourceCreateThumbnailAtIndex(
      source,
      0,
      options as CFDictionary
    )
  }

  func cropped() -> CGImage? {
    let rect = CGRect(
      x: 0,
      y: 60,
      width: CGFloat(self.width),
      height: CGFloat(self.height) - 60
    )

    return self.cropping(to: rect)
  }

  func isEquivalentTo(
    _ other: CGImage,
    varianceThreshold: Double = 2.0,
  ) -> Bool {
    guard
      self.width == other.width,
      self.height == other.height,
      let imageBytes = self.rgbaBytes(),
      let otherImageBytes = other.rgbaBytes()
    else {
      return false
    }

    let pixelCount = self.width * self.height
    let channelCount = 4
    let totalChannels = pixelCount * channelCount

    var sumSquaredDiff: Double = 0

    for i in 0..<totalChannels {
      let diff = Double(imageBytes[i]) - Double(otherImageBytes[i])
      sumSquaredDiff += diff * diff
    }

    let variance = sumSquaredDiff / Double(totalChannels)
    return variance < varianceThreshold
  }
}
