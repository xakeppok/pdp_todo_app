import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:pdp_todo_app/core/home_widget/todo_widget_contract.dart';
import 'package:pdp_todo_app/features/todos/data/models/todo_model.dart';

class HomeWidgetTodoService {
  static const String appGroupId = TodoWidgetContract.appGroupId;
  static const String iosName = TodoWidgetContract.widgetName;
  static const String todosKey = TodoWidgetContract.todosKey;
  static const String widgetTodosKey = TodoWidgetContract.widgetTodosKey;
  static const String todosTotalKey = TodoWidgetContract.todosTotalKey;
  static const int widgetLimit = TodoWidgetContract.widgetLimit;
  static const String _androidWidgetName = TodoWidgetContract.widgetName;
  static const String _qualifiedAndroidName =
      TodoWidgetContract.qualifiedAndroidName;
  static const String _androidGlanceName = TodoWidgetContract.glanceWidgetName;
  static const String _qualifiedAndroidGlanceName =
      TodoWidgetContract.qualifiedAndroidGlanceName;

  bool _appGroupReady = false;

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
    await HomeWidget.updateWidget(
      name: _androidGlanceName,
      androidName: _androidGlanceName,
      qualifiedAndroidName: _qualifiedAndroidGlanceName,
    );
  }

  Future<void> _ensureIosAppGroup() async {
    if (_appGroupReady) {
      return;
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      _appGroupReady = true;
      return;
    }
    await HomeWidget.setAppGroupId(appGroupId);
    _appGroupReady = true;
  }
}
