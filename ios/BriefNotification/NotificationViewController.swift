import SwiftUI
import UIKit
import UserNotifications
import UserNotificationsUI

/// Shows the custom design when the morning notification is long-pressed.
final class NotificationViewController: UIViewController, UNNotificationContentExtension {
    private var host: UIHostingController<AnyView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(Theme.blue)
        // The height comes from UNNotificationExtensionInitialContentSizeRatio in Info.plist (matching NotificationFace).
        show(BriefLoader.cached() ?? .sample)
    }

    func didReceive(_ notification: UNNotification) {
        Task { @MainActor in
            async let loaded = BriefLoader.load()
            async let weather = WeatherLoader.load()
            guard var brief = await loaded else { return }
            if let weather = await weather { brief.weather = weather }
            show(brief)
        }
    }

    private func show(_ brief: Brief) {
        let root = AnyView(NotificationFace(brief: brief))
        if let host {
            host.rootView = root
            return
        }
        let host = UIHostingController(rootView: root)
        host.view.backgroundColor = .clear
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
        self.host = host
    }
}
