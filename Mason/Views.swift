import SwiftUI
import UIKit

// MARK: - Root: iOS 26 glass tab bar, classic tab bar on iOS 13–18

struct RootView: View {
    @ObservedObject var store: Store
    @ObservedObject var settings: AppSettings
    @State private var tab: AppTab = AppTab(rawValue: Launch.value("-tab") ?? "") ?? .home
    @State private var showNewTask = Launch.flag("-sheet")

    init(store: Store, settings: AppSettings) {
        self.store = store
        self.settings = settings
    }

    var body: some View {
        tabs
            .sheet(isPresented: $showNewTask) {
                NewTaskSheet(store: self.store, isPresented: self.$showNewTask)
                    .sheetDetents()
            }
    }

    @ViewBuilder
    private var tabs: some View {
        if #available(iOS 26.0, *) {
            TabView(selection: $tab) {
                Tab("Home", systemImage: "house.fill", value: AppTab.home) {
                    HomeView(store: store, showNewTask: $showNewTask)
                }
                Tab("Tasks", systemImage: "list.bullet", value: AppTab.tasks) {
                    TasksView(store: store, showNewTask: $showNewTask)
                }
                Tab("Settings", systemImage: "gear", value: AppTab.settings) {
                    SettingsView(settings: settings)
                }
                Tab("Search", systemImage: "magnifyingglass", value: AppTab.search, role: .search) {
                    SearchView(store: store)
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
        } else {
            TabView(selection: $tab) {
                HomeView(store: store, showNewTask: $showNewTask)
                    .tabItem { Image(systemName: "house.fill"); Text("Home") }
                    .tag(AppTab.home)
                TasksView(store: store, showNewTask: $showNewTask)
                    .tabItem { Image(systemName: "list.bullet"); Text("Tasks") }
                    .tag(AppTab.tasks)
                SettingsView(settings: settings)
                    .tabItem { Image(systemName: "gear"); Text("Settings") }
                    .tag(AppTab.settings)
                SearchView(store: store)
                    .tabItem { Image(systemName: "magnifyingglass"); Text("Search") }
                    .tag(AppTab.search)
            }
        }
    }
}

// MARK: - Shared background

struct Backdrop: View {
    @Environment(\.colorScheme) private var scheme

    private static func rgb(_ r: Double, _ g: Double, _ b: Double) -> Color {
        Color(red: r / 255, green: g / 255, blue: b / 255)
    }

    private var palette: [Color] {
        let c = Backdrop.rgb
        return scheme == .dark
            ? [c(52, 44, 140), c(110, 40, 150), c(20, 60, 170), c(8, 8, 20), c(20, 110, 130),
               c(52, 44, 140), c(20, 60, 170), c(8, 8, 20), c(110, 40, 150)]
            : [c(255, 160, 60), c(255, 90, 140), c(170, 90, 230), c(255, 215, 80), c(90, 220, 190),
               c(60, 140, 255), c(40, 180, 200), c(90, 200, 250), c(90, 90, 220)]
    }

    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                MeshGradient(
                    width: 3, height: 3,
                    points: [
                        [0, 0], [0.5, 0], [1, 0],
                        [0, 0.5], [0.6, 0.45], [1, 0.5],
                        [0, 1], [0.5, 1], [1, 1],
                    ],
                    colors: palette
                )
            } else {
                LinearGradient(gradient: Gradient(colors: [palette[0], palette[1], palette[5], palette[7]]),
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
        .fullBleed()
    }
}

// MARK: - Home

struct HomeView: View {
    @ObservedObject var store: Store
    @Binding var showNewTask: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    GlassGroup {
                        HStack(spacing: 16) {
                            StatCard(title: "Today", value: store.remaining, caption: "tasks left", symbol: "sun.max.fill")
                            StatCard(title: "Done", value: store.doneCount, caption: "completed", symbol: "checkmark.seal.fill")
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Projects").font(.headline)
                        ForEach(Store.projects, id: \.self) { project in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(project)
                                    Spacer()
                                    Text(verbatim: "\(Int((self.store.progress(for: project) * 100).rounded()))%")
                                        .foregroundColor(.secondary)
                                }
                                ProgressBar(value: self.store.progress(for: project))
                            }
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Up next").font(.headline)
                        ForEach(Array(store.tasks.filter { !$0.done }.prefix(4))) { task in
                            TaskRow(task: task) { self.store.toggle(task.id) }
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()

                    HStack(spacing: 12) {
                        Button(action: { self.showNewTask = true }) {
                            HStack { Image(systemName: "plus"); Text("New Task") }
                        }
                        .glassButton(prominent: true)

                        Button(action: { withAnimation { self.store.tasks.shuffle() } }) {
                            HStack { Image(systemName: "shuffle"); Text("Shuffle") }
                        }
                        .glassButton(prominent: false)
                    }
                }
                .padding()
            }
            .background(Backdrop())
            .navTitle("Mason")
            .navButtons(leading: EmptyView(),
                        trailing: Button(action: { self.showNewTask = true }) { Image(systemName: "plus") })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct StatCard: View {
    let title: String
    let value: Int
    let caption: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                Text(title)
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            Text("\(value)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
            Text(caption).font(.footnote).foregroundColor(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(interactive: true)
    }
}

struct TaskRow: View {
    let task: TaskItem
    let toggle: () -> Void

    var body: some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { self.toggle() } }) {
            HStack(spacing: 12) {
                Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(task.done ? .green : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .strikethrough(task.done)
                        .foregroundColor(task.done ? .secondary : .primary)
                    Text(task.project).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tasks

struct TasksView: View {
    @ObservedObject var store: Store
    @Binding var showNewTask: Bool

    var body: some View {
        NavigationView {
            List {
                ForEach(Store.projects, id: \.self) { project in
                    Section(header: Text(project)) {
                        ForEach(self.store.tasks.filter { $0.project == project }) { task in
                            TaskRow(task: task) { self.store.toggle(task.id) }
                        }
                        .onDelete { offsets in
                            let ids = self.store.tasks.filter { $0.project == project }
                                .enumerated()
                                .filter { offsets.contains($0.offset) }
                                .map { $0.element.id }
                            self.store.tasks.removeAll { ids.contains($0.id) }
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .clearListBackground()
            .navTitle("Tasks")
            .navButtons(leading: EmptyView(),
                        trailing: Button(action: { self.showNewTask = true }) { Image(systemName: "plus") })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Search

struct SearchView: View {
    @ObservedObject var store: Store
    @State private var query = ""

    private var results: [TaskItem] {
        store.tasks.filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationView {
            searchList.navTitle("Search")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    @ViewBuilder
    private var searchList: some View {
        if #available(iOS 15.0, *) {
            List {
                ForEach(results) { task in
                    TaskRow(task: task) { self.store.toggle(task.id) }
                }
            }
            .searchable(text: $query, prompt: "Search tasks")
        } else {
            List {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search tasks", text: $query)
                }
                ForEach(results) { task in
                    TaskRow(task: task) { self.store.toggle(task.id) }
                }
            }
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $settings.appearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                Section(header: Text("About")) {
                    InfoRow(label: "App", value: "Mason 1.0")
                    InfoRow(label: UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS" : "iOS",
                            value: UIDevice.current.systemVersion)
                    InfoRow(label: "Device", value: UIDevice.current.model)
                    InfoRow(label: "Design", value: liquidGlass ? "Liquid Glass" : "Blur (pre-iOS 26)")
                }
            }
            .navTitle("Settings")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var liquidGlass: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }
}

// MARK: - New task window (glass sheet on iOS 26)

struct NewTaskSheet: View {
    @ObservedObject var store: Store
    @Binding var isPresented: Bool
    @State private var title = ""
    @State private var project = Store.projects[0]

    private var canAdd: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationView {
            Form {
                TextField("What needs doing?", text: $title)
                Picker("Project", selection: $project) {
                    ForEach(Store.projects, id: \.self) { Text($0).tag($0) }
                }
            }
            .navTitle("New Task", inline: true)
            .navButtons(
                leading: Button("Cancel") { self.isPresented = false },
                trailing: Button("Add") {
                    self.store.add(self.title, project: self.project)
                    self.isPresented = false
                }
                .disabled(!canAdd)
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
