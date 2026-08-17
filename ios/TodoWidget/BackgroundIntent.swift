import AppIntents
import Foundation
import WidgetKit

enum TodoWidgetConfig {
    static let appGroupId = "group.com.example.pdpTodoApp"
    static let kind = "TodoWidget"
    static let todosKey = "todos"
    static let widgetTodosKey = "widget_todos"
    static let todosTotalKey = "todos_total"
    static let widgetLimit = 8
}

enum TodoWidgetStore {
    static func jsonBool(_ value: Any?) -> Bool {
        if let bool = value as? Bool { return bool }
        if let number = value as? NSNumber { return number.boolValue }
        if let string = value as? String {
            return string == "true" || string == "1"
        }
        return false
    }

    static func toggleCompleted(id: String, appGroup: String) {
        let defaults = UserDefaults(suiteName: appGroup)
        toggleTodosJson(id: id, defaults: defaults)
    }

    private static func toggleTodosJson(id: String, defaults: UserDefaults?) {
        guard let json = defaults?.string(forKey: TodoWidgetConfig.todosKey),
              let data = json.data(using: .utf8),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else {
            return
        }

        let updated: [[String: Any]] = raw.map { item in
            var item = item
            if item["id"] as? String == id {
                item["completed"] = !jsonBool(item["completed"])
            }
            return item
        }

        guard let payload = try? JSONSerialization.data(withJSONObject: updated),
              let text = String(data: payload, encoding: .utf8)
        else {
            return
        }
        defaults?.set(text, forKey: TodoWidgetConfig.todosKey)
        writeWidgetProjection(updated, defaults: defaults)
        WidgetCenter.shared.reloadTimelines(ofKind: TodoWidgetConfig.kind)
    }

    private static func writeWidgetProjection(_ todos: [[String: Any]], defaults: UserDefaults?) {
        let slice: [[String: Any]] = todos.prefix(TodoWidgetConfig.widgetLimit).map { item in
            [
                "id": item["id"] as? String ?? "",
                "title": item["title"] as? String ?? "",
                "completed": jsonBool(item["completed"]),
            ]
        }
        guard let payload = try? JSONSerialization.data(withJSONObject: slice),
              let text = String(data: payload, encoding: .utf8)
        else {
            return
        }
        defaults?.set(text, forKey: TodoWidgetConfig.widgetTodosKey)
        defaults?.set(todos.count, forKey: TodoWidgetConfig.todosTotalKey)
    }
}

@available(iOS 17, *)
public struct BackgroundIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle Todo"
    public static var isDiscoverable = false

    @Parameter(title: "Todo ID")
    var todoId: String

    @Parameter(title: "App Group")
    var appGroup: String

    @Parameter(title: "Slot")
    var slot: Int

    public init() {
        todoId = ""
        appGroup = TodoWidgetConfig.appGroupId
        slot = 0
    }

    public init(todoId: String, appGroup: String, slot: Int) {
        self.todoId = todoId
        self.appGroup = appGroup
        self.slot = slot
    }

    public func perform() async throws -> some IntentResult {
        guard !todoId.isEmpty else {
            return .result()
        }
        TodoWidgetStore.toggleCompleted(id: todoId, appGroup: appGroup)
        return .result()
    }
}

@available(iOS 17, *)
@available(iOSApplicationExtension, unavailable)
extension BackgroundIntent: ForegroundContinuableIntent {}
