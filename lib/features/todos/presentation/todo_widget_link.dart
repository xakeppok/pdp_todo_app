import 'package:pdp_todo_app/core/home_widget/todo_widget_contract.dart';
import 'package:pdp_todo_app/core/router/app_routes.dart';

final class TodoWidgetLink {
  const TodoWidgetLink({this.id});

  static const scheme = TodoWidgetContract.scheme;
  static const host = TodoWidgetContract.host;

  final String? id;

  String get location => id == null ? AppRoutes.todos : AppRoutes.details(id!);

  static TodoWidgetLink? tryParse(Uri? uri) {
    if (uri == null || uri.scheme != scheme) return null;

    final segments = [
      if (uri.host.isNotEmpty && uri.host != host) uri.host,
      ...uri.pathSegments,
    ];
    if (segments.isEmpty || segments.first != 'todos') return null;
    if (segments.length == 1) return const TodoWidgetLink();
    if (segments[1].isNotEmpty) return TodoWidgetLink(id: segments[1]);
    return null;
  }
}
