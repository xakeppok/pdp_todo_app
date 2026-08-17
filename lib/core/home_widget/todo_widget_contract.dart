/// Shared contract between Flutter, Android App Widget, and iOS WidgetKit.
///
/// Keep native copies in sync:
/// - Android `TodoWidgetStore`
/// - iOS `TodoWidgetConfig`
abstract final class TodoWidgetContract {
  static const scheme = 'todowidget';
  static const host = 'app';
  static const appGroupId = 'group.com.example.pdpTodoApp';
  static const widgetName = 'TodoWidget';
  static const qualifiedAndroidName = 'com.example.pdp_todo_app.TodoWidget';
  static const todosKey = 'todos';
  static const widgetTodosKey = 'widget_todos';
  static const todosTotalKey = 'todos_total';
  static const widgetLimit = 8;
}
