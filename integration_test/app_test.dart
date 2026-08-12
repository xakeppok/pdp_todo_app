import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdp_todo_app/features/todos/data/datasources/todo_data_source.dart';
import 'package:pdp_todo_app/features/todos/data/models/todo_model.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_filter.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_sort.dart';
import 'package:pdp_todo_app/features/todos/presentation/todos_keys.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create todo then open details and complete', (tester) async {
    final app = await IntegrationHarness.createApp();
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.byKey(TodosKeys.page), findsOneWidget);

    await tester.tap(find.byKey(TodosKeys.createFab));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(TodosKeys.titleField),
      'Integration todo',
    );
    await tester.enterText(
      find.byKey(TodosKeys.dueDateField),
      '2026-08-20',
    );
    await tester.tap(find.byKey(TodosKeys.submitButton));
    await tester.pumpAndSettle();

    expect(find.text('Integration todo'), findsOneWidget);

    await tester.tap(find.text('Integration todo'));
    await tester.pumpAndSettle();
    expect(find.byKey(TodosKeys.detailsPage), findsOneWidget);

    await tester.tap(find.byKey(TodosKeys.detailsToggleButton));
    await tester.pumpAndSettle();
    expect(find.text('Mark as active'), findsOneWidget);
  });

  testWidgets('filter sort edit save delete flow', (tester) async {
    final app = await IntegrationHarness.createApp();
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(TodosKeys.filter(TodoFilter.active)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(TodosKeys.sortMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(TodosKeys.sort(TodoSort.priority)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Write unit tests'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(TodosKeys.editButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(TodosKeys.titleField),
      'Updated unit tests',
    );
    await tester.tap(find.byKey(TodosKeys.submitButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(TodosKeys.detailsDeleteButton));
    await tester.pumpAndSettle();
    expect(find.text('Updated unit tests'), findsNothing);
  });

  testWidgets('empty seed create first todo', (tester) async {
    final app = await IntegrationHarness.createApp(seed: const []);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.byKey(TodosKeys.emptyView), findsOneWidget);
    await tester.tap(find.byKey(TodosKeys.emptyCreateButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(TodosKeys.titleField),
      'First todo',
    );
    await tester.enterText(
      find.byKey(TodosKeys.dueDateField),
      '2026-08-15',
    );
    await tester.tap(find.byKey(TodosKeys.submitButton));
    await tester.pumpAndSettle();

    expect(find.byKey(TodosKeys.emptyView), findsNothing);
    expect(find.text('First todo'), findsOneWidget);
  });

  testWidgets('open seeded details and verify fields', (tester) async {
    final app = await IntegrationHarness.createApp();
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add widget tests'));
    await tester.pumpAndSettle();

    expect(find.byKey(TodosKeys.detailsTitle), findsOneWidget);
    expect(find.text('Add widget tests'), findsWidgets);
    expect(find.textContaining('Cover loading'), findsOneWidget);
  });

  testWidgets('forced failure then retry succeeds via harness API',
      (tester) async {
    final app = await IntegrationHarness.createApp(
      failureMode: FailureMode.throwOnGet,
    );
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    expect(find.byKey(TodosKeys.errorView), findsOneWidget);

    IntegrationHarness.setFailureMode(FailureMode.none);
    await tester.tap(find.byKey(TodosKeys.retryButton));
    await tester.pumpAndSettle();
    expect(find.byKey(TodosKeys.list), findsOneWidget);
  });

  testWidgets('complete then filter completed', (tester) async {
    final app = await IntegrationHarness.createApp(
      seed: [
        const TodoModel(
          id: 'solo',
          title: 'Completable',
          description: 'Toggle me',
          priority: 'medium',
          dueDate: '2026-08-15',
          completed: false,
          tags: ['flow'],
        ),
      ],
    );
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(TodosKeys.toggle('solo')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(TodosKeys.filter(TodoFilter.completed)));
    await tester.pumpAndSettle();
    expect(find.text('Completable'), findsOneWidget);

    await tester.tap(find.byKey(TodosKeys.toggle('solo')));
    await tester.pumpAndSettle();
    expect(find.text('Completable'), findsNothing);
  });
}
