import Foundation
import WidgetKit

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

enum TodoWidgetTimeline {
    static var listURL: URL {
        widgetURL(path: "/todos")
    }

    static func detailsURL(id: String) -> URL {
        widgetURL(path: "/todos/\(id)")
    }

    private static func widgetURL(path: String) -> URL {
        var components = URLComponents()
        components.scheme = "todowidget"
        components.host = "app"
        components.path = path
        components.queryItems = [URLQueryItem(name: "homeWidget", value: nil)]
        return components.url ?? URL(string: "todowidget://app/todos")!
    }

    static func visibleTodoCount(family: WidgetFamily, total: Int) -> Int {
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

    static func loadEntry() -> TodoEntry {
        let todos = loadTodos()
        return TodoEntry(date: Date(), todos: todos, total: loadTotal(fallback: todos.count))
    }

    private static func loadTodos() -> [WidgetTodo] {
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

    private static func loadTotal(fallback: Int) -> Int {
        let defaults = UserDefaults(suiteName: TodoWidgetConfig.appGroupId)
        if let number = defaults?.object(forKey: TodoWidgetConfig.todosTotalKey) as? NSNumber {
            return number.intValue
        }
        return fallback
    }
}
