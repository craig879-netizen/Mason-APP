import SwiftUI
import UIKit

// UIKit app lifecycle so the app launches on iOS 13 (SwiftUI's `App` needs iOS 14).
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        true
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let settings = AppSettings.shared
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: RootView(store: Store(), settings: settings))
        window.overrideUserInterfaceStyle = settings.interfaceStyle
        settings.onChange = { [weak window] in
            window?.overrideUserInterfaceStyle = AppSettings.shared.interfaceStyle
        }
        self.window = window
        window.makeKeyAndVisible()
    }
}

/// Launch arguments let the simulator script open a specific screen,
/// e.g. `xcrun simctl launch <udid> com.mason.app -tab tasks -sheet`.
enum Launch {
    static let args = ProcessInfo.processInfo.arguments

    static func value(_ key: String) -> String? {
        guard let i = args.firstIndex(of: key), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    static func flag(_ key: String) -> Bool { args.contains(key) }
}

enum AppTab: String, Hashable {
    case home, tasks, settings, search
}

struct TaskItem: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var project: String
    var done: Bool = false
}

final class Store: ObservableObject {
    static let projects = ["Home", "Work", "School"]

    @Published var tasks: [TaskItem] = [
        TaskItem(title: "Pick up groceries", project: "Home"),
        TaskItem(title: "Call the plumber", project: "Home", done: true),
        TaskItem(title: "Send weekly update", project: "Work"),
        TaskItem(title: "Review design mockups", project: "Work"),
        TaskItem(title: "Finish science project", project: "School"),
        TaskItem(title: "Read chapter 7", project: "School", done: true),
    ]

    var remaining: Int { tasks.filter { !$0.done }.count }
    var doneCount: Int { tasks.filter { $0.done }.count }

    func toggle(_ id: UUID) {
        guard let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[i].done.toggle()
    }

    func add(_ title: String, project: String) {
        tasks.insert(TaskItem(title: title, project: project), at: 0)
    }

    func progress(for project: String) -> Double {
        let items = tasks.filter { $0.project == project }
        guard !items.isEmpty else { return 0 }
        return Double(items.filter { $0.done }.count) / Double(items.count)
    }
}

final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    var onChange: (() -> Void)?

    @Published var appearance: String {
        didSet {
            UserDefaults.standard.set(appearance, forKey: "appearance")
            onChange?()
        }
    }

    init() {
        appearance = UserDefaults.standard.string(forKey: "appearance") ?? "system"
    }

    var interfaceStyle: UIUserInterfaceStyle {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return .unspecified
        }
    }
}
