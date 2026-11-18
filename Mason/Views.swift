import SwiftUI

// MARK: - Root: iOS 26 tab bar (Liquid Glass, minimizes on scroll)

struct RootView: View {
    @State private var store = Store()
    @State private var tab: AppTab = AppTab(rawValue: Launch.value("-tab") ?? "") ?? .home
    @State private var showNewTask = Launch.flag("-sheet")
    @AppStorage("appearance") private var appearance = "system"

    var body: some View {
        TabView(selection: $tab) {
            Tab("Home", systemImage: "house.fill", value: AppTab.home) {
                HomeView(store: store, showNewTask: $showNewTask)
            }
            Tab("Tasks", systemImage: "checklist", value: AppTab.tasks) {
                TasksView(store: store, showNewTask: $showNewTask)
            }
            Tab("Settings", systemImage: "gearshape.fill", value: AppTab.settings) {
                SettingsView()
            }
            Tab("Search", systemImage: "magnifyingglass", value: AppTab.search, role: .search) {
                SearchView(store: store)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .sheet(isPresented: $showNewTask) {
            NewTaskSheet(store: store)
                .presentationDetents([.medium, .large])
        }
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
    }
}

// MARK: - Shared background

struct Backdrop: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.6, 0.45], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1],
            ],
            colors: scheme == .dark
                ? [.indigo, .purple, .blue, .black, .teal, .indigo, .blue, .black, .purple]
                : [.orange, .pink, .purple, .yellow, .mint, .blue, .teal, .cyan, .indigo]
        )
        .ignoresSafeArea()
    }
}

// MARK: - Home

struct HomeView: View {
    var store: Store
    @Binding var showNewTask: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    GlassEffectContainer(spacing: 16) {
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
                                    Text(store.progress(for: project), format: .percent.precision(.fractionLength(0)))
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }
                                ProgressView(value: store.progress(for: project))
                            }
                        }
                    }
                    .padding(18)
                    .glassEffect(.regular, in: .rect(cornerRadius: 26))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Up next").font(.headline)
                        ForEach(store.tasks.filter { !$0.done }.prefix(4)) { task in
                            TaskRow(task: task) { store.toggle(task.id) }
                        }
                    }
                    .padding(18)
                    .glassEffect(.regular, in: .rect(cornerRadius: 26))

                    HStack(spacing: 12) {
                        Button("New Task", systemImage: "plus") { showNewTask = true }
                            .buttonStyle(.glassProminent)
                        Button("Shuffle", systemImage: "shuffle") { store.tasks.shuffle() }
                            .buttonStyle(.glass)
                    }
                    .controlSize(.large)
                }
                .padding()
            }
            .background { Backdrop() }
            .navigationTitle("Mason")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New Task", systemImage: "plus") { showNewTask = true }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: Int
    let caption: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
            Text(caption).font(.footnote).foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 26))
    }
}

struct TaskRow: View {
    let task: TaskItem
    let toggle: () -> Void

    var body: some View {
        Button(action: { withAnimation(.snappy) { toggle() } }) {
            HStack(spacing: 12) {
                Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.done ? Color.green : Color.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .strikethrough(task.done)
                        .foregroundStyle(task.done ? .secondary : .primary)
                    Text(task.project).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tasks

struct TasksView: View {
    var store: Store
    @Binding var showNewTask: Bool

    var body: some View {
        NavigationStack {
            List {
                ForEach(Store.projects, id: \.self) { project in
                    Section(project) {
                        ForEach(store.tasks.filter { $0.project == project }) { task in
                            TaskRow(task: task) { store.toggle(task.id) }
                        }
                        .onDelete { offsets in
                            let ids = store.tasks.filter { $0.project == project }.enumerated()
                                .filter { offsets.contains($0.offset) }.map(\.element.id)
                            store.tasks.removeAll { ids.contains($0.id) }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background { Backdrop() }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New Task", systemImage: "plus") { showNewTask = true }
                }
            }
        }
    }
}

// MARK: - Search

struct SearchView: View {
    var store: Store
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.tasks.filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) }) { task in
                    TaskRow(task: task) { store.toggle(task.id) }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Search tasks")
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @AppStorage("appearance") private var appearance = "system"

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }
                Section("About") {
                    LabeledContent("App", value: "Mason 1.0")
                    LabeledContent("iOS", value: UIDevice.current.systemVersion)
                    LabeledContent("Device", value: UIDevice.current.name)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - New task window (iOS 26 glass sheet)

struct NewTaskSheet: View {
    var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var project = Store.projects[0]

    var body: some View {
        NavigationStack {
            Form {
                TextField("What needs doing?", text: $title)
                Picker("Project", selection: $project) {
                    ForEach(Store.projects, id: \.self) { Text($0) }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", systemImage: "checkmark") {
                        store.add(title, project: project)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
