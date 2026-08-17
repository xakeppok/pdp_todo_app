import 'package:pdp_todo_app/features/todos/data/models/todo_model.dart';
import 'package:pdp_todo_app/features/todos/data/services/home_widget_todo_service.dart';

class FakeHomeWidgetTodoService extends HomeWidgetTodoService {
  FakeHomeWidgetTodoService([this.json]);

  String? json;
  String? widgetJson;
  int? total;
  int saveCount = 0;

  @override
  Future<String?> load() async => json;

  @override
  Future<void> save(List<TodoModel> todos) async {
    json = TodoModel.listToJsonString(todos);
    widgetJson = TodoModel.widgetListToJsonString(
      todos,
      limit: HomeWidgetTodoService.widgetLimit,
    );
    total = todos.length;
    saveCount += 1;
  }
}
