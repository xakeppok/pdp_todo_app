import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pdp_todo_app/core/clock/clock.dart';
import 'package:pdp_todo_app/core/router/app_routes.dart';
import 'package:pdp_todo_app/features/messages/presentation/pages/messages_page.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todo_details_cubit.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todo_form_cubit.dart';
import 'package:pdp_todo_app/features/todos/presentation/pages/create_todo_page.dart';
import 'package:pdp_todo_app/features/todos/presentation/pages/todo_details_page.dart';
import 'package:pdp_todo_app/features/todos/presentation/pages/todos_page.dart';

typedef TodoFormCubitFactory = TodoFormCubit Function({Todo? initialTodo});
typedef TodoDetailsCubitFactory = TodoDetailsCubit Function(String todoId);

GoRouter createAppRouter({
  required Clock clock,
  required TodoFormCubitFactory createFormCubit,
  required TodoDetailsCubitFactory createDetailsCubit,
  String initialLocation = AppRoutes.todos,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.root,
        redirect: (context, state) => AppRoutes.todos,
      ),
      GoRoute(
        path: AppRoutes.todos,
        builder: (context, state) => TodosPage(clock: clock),
        routes: [
          GoRoute(
            path: AppRoutes.createRelative,
            builder: (context, state) => BlocProvider(
              create: (_) => createFormCubit(),
              child: const CreateTodoPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.idRelative,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return BlocProvider(
                create: (_) => createDetailsCubit(id),
                child: TodoDetailsPage(clock: clock),
              );
            },
            routes: [
              GoRoute(
                path: AppRoutes.editRelative,
                builder: (context, state) {
                  final todo = state.extra;
                  if (todo is! Todo) {
                    return const Scaffold(
                      body: Center(
                        child: Text('Todo is required to open edit'),
                      ),
                    );
                  }
                  return BlocProvider(
                    create: (_) => createFormCubit(initialTodo: todo),
                    child: const EditTodoPage(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.messages,
        builder: (context, state) => const MessagesPage(),
      ),
    ],
  );
}
