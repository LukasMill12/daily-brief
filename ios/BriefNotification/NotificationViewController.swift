import SwiftUI
import UIKit
import UserNotifications
import UserNotificationsUI

/// Shows the custom design when the morning notification is long-pressed.
/// The design is rendered once into a still image at the view's real width, so no live SwiftUI layout
/// runs inside the notification (which froze the system UI when it was laid out at zero width).
final class NotificationViewController: UIViewController, UNNotificationContentExtension {
    private let imageView = UIImageView()
    private var brief = BriefLoader.cached() ?? .sample
    private var renderedWidth: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        DebugLog.write("viewDidLoad bounds=\(view.bounds.size)")
        view.backgroundColor = UIColor(Theme.blue)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.frame = view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(imageView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = view.bounds.width
        guard width > 50, abs(width - renderedWidth) > 1 else { return }
        render(width: width)
    }

    func didReceive(_ notification: UNNotification) {
        DebugLog.write("didReceive")
        Task { @MainActor in
            async let loaded = BriefLoader.load()
            async let weather = WeatherLoader.load()
            guard var fresh = await loaded else { DebugLog.write("load failed, keeping cached"); return }
            if let weather = await weather { fresh.weather = weather }
            brief = fresh
            DebugLog.write("loaded \(fresh.date)")
            if view.bounds.width > 50 { render(width: view.bounds.width) }
        }
    }

    private func render(width: CGFloat) {
        renderedWidth = width
        DebugLog.write("render width=\(width)")
        let renderer = ImageRenderer(content: NotificationFace(brief: brief).frame(width: width))
        renderer.scale = view.window?.screen.scale ?? 3
        imageView.image = renderer.uiImage
        DebugLog.write("rendered \(imageView.image?.size ?? .zero)")
    }
}
