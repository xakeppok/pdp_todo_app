import AppIntents
import SwiftUI
import WidgetKit

enum TodoWidgetStyle {
    static let accent = Color(red: 15 / 255, green: 107 / 255, blue: 92 / 255)
    static let accentDark = Color(red: 93 / 255, green: 207 / 255, blue: 184 / 255)
    static let canvas = Color(red: 243 / 255, green: 247 / 255, blue: 246 / 255)
    static let canvasDark = Color(red: 16 / 255, green: 24 / 255, blue: 22 / 255)

    static func accent(for scheme: ColorScheme) -> Color {
        scheme == .dark ? accentDark : accent
    }

    static func canvas(for scheme: ColorScheme) -> Color {
        scheme == .dark ? canvasDark : canvas
    }
}

struct WidgetTodo: Identifiable {
    let id: String
    let title: String
    let completed: Bool
}

struct TodoEntry: TimelineEntry {
    let date: Date
    let todos: [WidgetTodo]
    let total: Int
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(date: Date(), todos: [
            WidgetTodo(id: "1", title: "Write unit tests", completed: false),
            WidgetTodo(id: "2", title: "Add widget tests", completed: true),
        ], total: 2)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoEntry>) -> Void) {
        let timeline = Timeline(entries: [loadEntry()], policy: .never)
        completion(timeline)
    }
}

func loadEntry() -> TodoEntry {
    let todos = loadTodos()
    return TodoEntry(date: Date(), todos: todos, total: loadTotal(fallback: todos.count))
}

func loadTodos() -> [WidgetTodo] {
    let defaults = UserDefaults(suiteName: TodoWidgetConfig.appGroupId)
    guard let json = defaults?.string(forKey: TodoWidgetConfig.widgetTodosKey),
          let data = json.data(using: .utf8),
          let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else {
        return []
    }

    return raw.prefix(TodoWidgetConfig.widgetLimit).compactMap { item in
        guard let id = item["id"] as? String, !id.isEmpty,
              let title = item["title"] as? String, !title.isEmpty
        else {
            return nil
        }
        return WidgetTodo(
            id: id,
            title: title,
            completed: TodoWidgetStore.jsonBool(item["completed"])
        )
    }
}

func loadTotal(fallback: Int) -> Int {
    let defaults = UserDefaults(suiteName: TodoWidgetConfig.appGroupId)
    if let number = defaults?.object(forKey: TodoWidgetConfig.todosTotalKey) as? NSNumber {
        return number.intValue
    }
    return fallback
}

func listURL() -> URL {
    URL(string: "todowidget://app/todos")!
}

func visibleTodoCount(family: WidgetFamily, total: Int) -> Int {
    let maxVisible: Int
    switch family {
    case .systemSmall:
        maxVisible = 2
    case .systemMedium:
        maxVisible = 3
    case .systemLarge, .systemExtraLarge:
        maxVisible = 8
    default:
        maxVisible = 2
    }
    return min(total, maxVisible)
}

struct TodoWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    var entry: Provider.Entry

    private var accent: Color { TodoWidgetStyle.accent(for: colorScheme) }
    private var todos: [WidgetTodo] { entry.todos }
    private var openCount: Int { entry.todos.filter { !$0.completed }.count }

    var body: some View {
        let remaining = max(entry.total - visibleTodoCount(family: family, total: todos.count), 0)

        VStack(alignment: .leading, spacing: family == .systemSmall ? 8 : 10) {
            Link(destination: listURL()) {
                header(remaining: remaining)
            }

            if todos.isEmpty {
                Link(destination: listURL()) {
                    emptyState
                }
            } else {
                let visibleCount = visibleTodoCount(family: family, total: todos.count)
                VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 8) {
                    slot(0, count: visibleCount)
                    slot(1, count: visibleCount)
                    slot(2, count: visibleCount)
                    slot(3, count: visibleCount)
                    slot(4, count: visibleCount)
                    slot(5, count: visibleCount)
                    slot(6, count: visibleCount)
                    slot(7, count: visibleCount)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func slot(_ index: Int, count: Int) -> some View {
        if index < count && index < todos.count {
            TodoWidgetRow(todo: todos[index], accent: accent, slot: index)
        }
    }

    private func header(remaining: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(accent)
                .accessibilityHidden(true)

            Text("Todos")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 4)

            if !entry.todos.isEmpty {
                Text(headerBadgeTitle(remaining: remaining))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accent.opacity(0.14), in: Capsule())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func headerBadgeTitle(remaining: Int) -> String {
        if remaining > 0 {
            return "+\(remaining)"
        }
        if openCount == 0 {
            return "Done"
        }
        return "\(openCount) left"
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer(minLength: 0)
            Text("No todos yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Tap to add one")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            Spacer(minLength: 0)
        }
    }
}

struct TodoWidgetRow: View {
    let todo: WidgetTodo
    let accent: Color
    let slot: Int

    var body: some View {
        Button(
            intent: BackgroundIntent(
                todoId: todo.id,
                appGroup: TodoWidgetConfig.appGroupId,
                slot: slot
            )
        ) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: todo.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(todo.completed ? accent : Color.secondary.opacity(0.4))
                    .frame(width: 28, height: 28)

                Text(todo.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                    .foregroundStyle(todo.completed ? Color.secondary : Color.primary)
                    .overlay {
                        if todo.completed {
                            Rectangle()
                                .fill(Color.primary.opacity(0.55))
                                .frame(height: 1.5)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .invalidatableContent()
        .accessibilityLabel(todo.completed ? "Mark \(todo.title) incomplete" : "Mark \(todo.title) complete")
    }
}

struct TodoWidget: Widget {
    let kind: String = TodoWidgetConfig.kind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                TodoWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        TodoWidgetCanvas()
                    }
            } else {
                TodoWidgetEntryView(entry: entry)
                    .padding()
                    .background(TodoWidgetCanvas())
            }
        }
        .configurationDisplayName("My Todos")
        .description("Your todos at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

private struct TodoWidgetCanvas: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TodoWidgetStyle.canvas(for: colorScheme)
    }
}

#Preview(as: .systemMedium) {
    TodoWidget()
} timeline: {
    TodoEntry(
        date: .now,
        todos: [
            WidgetTodo(id: "1", title: "Write unit tests", completed: false),
            WidgetTodo(id: "2", title: "Add widget tests", completed: false),
            WidgetTodo(id: "3", title: "Buy milk", completed: true),
            WidgetTodo(id: "4", title: "Review pull request", completed: false),
            WidgetTodo(id: "5", title: "Walk the dog", completed: false),
        ],
        total: 12
    )
}
