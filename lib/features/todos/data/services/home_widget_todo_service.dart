import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:pdp_todo_app/features/todos/data/models/todo_model.dart';

class HomeWidgetTodoService {
  static const appGroupId = 'group.com.example.pdpTodoApp';
  static const iosName = 'TodoWidget';
  static const todosKey = 'todos';
  static const widgetTodosKey = 'widget_todos';
  static const todosTotalKey = 'todos_total';
  static const widgetLimit = 8;
  static const _androidWidgetName = 'TodoWidget';
  static const _qualifiedAndroidName = 'com.example.pdp_todo_app.TodoWidget';

  Future<String?> load() async {
    await _ensureIosAppGroup();
    return HomeWidget.getWidgetData<String>(todosKey);
  }

  Future<void> save(List<TodoModel> todos) async {
    await _ensureIosAppGroup();
    await HomeWidget.saveWidgetData<String>(
      todosKey,
      TodoModel.listToJsonString(todos),
    );
    await HomeWidget.saveWidgetData<String>(
      widgetTodosKey,
      TodoModel.widgetListToJsonString(todos, limit: widgetLimit),
    );
    await HomeWidget.saveWidgetData<int>(todosTotalKey, todos.length);
    await HomeWidget.updateWidget(
      name: _androidWidgetName,
      androidName: _androidWidgetName,
      iOSName: iosName,
      qualifiedAndroidName: _qualifiedAndroidName,
    );
  }

  Future<void> _ensureIosAppGroup() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    await HomeWidget.setAppGroupId(appGroupId);
  }
}
