import 'package:flutter/foundation.dart';

import 'package:pdp_todo_app/features/todos/domain/entities/todo_filter.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_priority.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_sort.dart';

/// Shared [Key]s for todos UI and tests.
abstract final class TodosKeys {
  static const page = Key('todos_page');
  static const createFab = Key('todos_create_fab');
  static const list = Key('todos_list');
  static const loadingView = Key('todos_loading_view');
  static const emptyView = Key('todos_empty_view');
  static const emptyCreateButton = Key('todos_empty_create_button');
  static const errorView = Key('todos_error_view');
  static const errorMessage = Key('todos_error_message');
  static const retryButton = Key('todos_retry_button');

  static const filterBar = Key('todo_filter_bar');
  static const sortMenu = Key('todo_sort_menu');
  static const themeToggle = Key('theme_toggle');

  static const createPage = Key('create_todo_page');
  static const editPage = Key('edit_todo_page');
  static const titleField = Key('todo_title_field');
  static const descriptionField = Key('todo_description_field');
  static const dueDateField = Key('todo_due_date_field');
  static const priorityField = Key('todo_priority_field');
  static const tagsField = Key('todo_tags_field');
  static const formError = Key('todo_form_error');
  static const submitButton = Key('todo_submit_button');

  static const detailsPage = Key('todo_details_page');
  static const editButton = Key('todo_edit_button');
  static const detailsError = Key('todo_details_error');
  static const detailsTitle = Key('todo_details_title');
  static const detailsDescription = Key('todo_details_description');
  static const detailsToggleButton = Key('todo_details_toggle_button');
  static const detailsDeleteButton = Key('todo_details_delete_button');

  static Key filter(TodoFilter filter) => Key('filter_${filter.name}');

  static Key sort(TodoSort sort) => Key('sort_${sort.name}');

  static Key item(String id) => Key('todo_item_$id');

  static Key toggle(String id) => Key('todo_toggle_$id');

  static Key title(String id) => Key('todo_title_$id');

  static Key due(String id) => Key('todo_due_$id');

  static Key overdue(String id) => Key('todo_overdue_$id');

  static Key delete(String id) => Key('todo_delete_$id');

  static Key priority(TodoPriority priority) =>
      Key('todo_priority_${priority.name}');

  static Key tag(String tag) => Key('todo_tag_$tag');

  /// Keys used by the stub routes in widget tests.
  static const createRouteStub = Key('create_route_stub');

  static Key detailsRouteStub(String id) => Key('details_route_stub_$id');
}
