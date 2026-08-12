import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_priority.dart';
import 'package:pdp_todo_app/features/todos/domain/services/todo_validator.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/create_todo.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/update_todo.dart';

class TodoFormCubit extends Cubit<TodoFormState> {
  TodoFormCubit({
    required this._createTodo,
    required this._updateTodo,
    Todo? initialTodo,
    String Function()? idGenerator,
  })  : _initialTodo = initialTodo,
        _idGenerator = idGenerator ?? _defaultId,
        super(
          TodoFormState(
            title: initialTodo?.title ?? '',
            description: initialTodo?.description ?? '',
            priority: initialTodo?.priority ?? TodoPriority.medium,
            dueDateInput: initialTodo == null
                ? ''
                : _formatDate(initialTodo.dueDate),
            tagsInput: initialTodo?.tags.join(', ') ?? '',
            isEditing: initialTodo != null,
          ),
        );

  final CreateTodo _createTodo;
  final UpdateTodo _updateTodo;
  final Todo? _initialTodo;
  final String Function() _idGenerator;

  void titleChanged(String value) => emit(state.copyWith(title: value));

  void descriptionChanged(String value) =>
      emit(state.copyWith(description: value));

  void priorityChanged(TodoPriority value) =>
      emit(state.copyWith(priority: value));

  void dueDateChanged(String value) =>
      emit(state.copyWith(dueDateInput: value));

  void tagsChanged(String value) => emit(state.copyWith(tagsInput: value));

  Future<void> submit() async {
    emit(
      state.copyWith(
        status: TodoFormStatus.submitting,
        clearFieldErrors: true,
        clearErrorMessage: true,
        clearSuccess: true,
      ),
    );

    final input = TodoInput(
      title: state.title,
      description: state.description,
      priority: state.priority.name,
      dueDateInput: state.dueDateInput,
      tags: state.tagsInput
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(),
    );

    try {
      final Todo result;
      if (_initialTodo == null) {
        result = await _createTodo(id: _idGenerator(), input: input);
      } else {
        result = await _updateTodo(existing: _initialTodo, input: input);
      }
      emit(
        state.copyWith(
          status: TodoFormStatus.success,
          savedTodo: result,
        ),
      );
    } on ValidationFailure catch (failure) {
      emit(
        state.copyWith(
          status: TodoFormStatus.failure,
          fieldErrors: _fieldErrorsFrom(failure.message),
          errorMessage: failure.message,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: TodoFormStatus.failure,
          errorMessage: failure.message,
        ),
      );
    } on Object catch (error) {
      emit(
        state.copyWith(
          status: TodoFormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Map<String, String> _fieldErrorsFrom(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('title')) {
      return {'title': message};
    }
    if (lower.contains('due date') || lower.contains('date')) {
      return {'dueDate': message};
    }
    if (lower.contains('priority')) {
      return {'priority': message};
    }
    return {};
  }

  static String _defaultId() =>
      'todo-${DateTime.now().microsecondsSinceEpoch}';

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

enum TodoFormStatus { idle, submitting, success, failure }

class TodoFormState extends Equatable {
  const TodoFormState({
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDateInput,
    required this.tagsInput,
    required this.isEditing,
    this.status = TodoFormStatus.idle,
    this.fieldErrors = const {},
    this.errorMessage,
    this.savedTodo,
  });

  final String title;
  final String description;
  final TodoPriority priority;
  final String dueDateInput;
  final String tagsInput;
  final bool isEditing;
  final TodoFormStatus status;
  final Map<String, String> fieldErrors;
  final String? errorMessage;
  final Todo? savedTodo;

  TodoFormState copyWith({
    String? title,
    String? description,
    TodoPriority? priority,
    String? dueDateInput,
    String? tagsInput,
    bool? isEditing,
    TodoFormStatus? status,
    Map<String, String>? fieldErrors,
    String? errorMessage,
    Todo? savedTodo,
    bool clearFieldErrors = false,
    bool clearErrorMessage = false,
    bool clearSuccess = false,
  }) {
    return TodoFormState(
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDateInput: dueDateInput ?? this.dueDateInput,
      tagsInput: tagsInput ?? this.tagsInput,
      isEditing: isEditing ?? this.isEditing,
      status: status ?? this.status,
      fieldErrors:
          clearFieldErrors ? const {} : fieldErrors ?? this.fieldErrors,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      savedTodo: clearSuccess ? null : savedTodo ?? this.savedTodo,
    );
  }

  @override
  List<Object?> get props => [
        title,
        description,
        priority,
        dueDateInput,
        tagsInput,
        isEditing,
        status,
        fieldErrors,
        errorMessage,
        savedTodo,
      ];
}
