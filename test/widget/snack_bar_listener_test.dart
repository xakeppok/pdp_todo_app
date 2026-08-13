import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdp_todo_app/core/widgets/snack_bar_listener.dart';

class _SnackState {
  const _SnackState(this.message);

  final String? message;
}

class _MessageCubit extends Cubit<_SnackState> {
  _MessageCubit() : super(const _SnackState(null));

  void setMessage(String? value) => emit(_SnackState(value));
}

void main() {
  late _MessageCubit cubit;

  Future<void> pumpListener(
    WidgetTester tester, {
    void Function(BuildContext context, _SnackState state)? onShown,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: SnackBarListener<_MessageCubit, _SnackState>(
            messageOf: (state) => state.message,
            onShown: onShown,
            child: const Scaffold(body: SizedBox()),
          ),
        ),
      ),
    );
  }

  setUp(() {
    cubit = _MessageCubit();
  });

  tearDown(() async {
    await cubit.close();
  });

  testWidgets('shows a snackbar when a new message appears', (tester) async {
    await pumpListener(tester);

    cubit.setMessage('boom');
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('boom'), findsOneWidget);
  });

  testWidgets('does not show the same message twice in a row', (tester) async {
    await pumpListener(tester);

    cubit.setMessage('boom');
    await tester.pump();
    cubit.setMessage('boom');
    await tester.pump();

    expect(find.text('boom'), findsOneWidget);
  });

  testWidgets('shows the same message again after it is cleared', (
    tester,
  ) async {
    await pumpListener(tester);

    cubit
      ..setMessage('boom')
      ..setMessage(null)
      ..setMessage('boom');
    await tester.pump();

    expect(find.text('boom'), findsOneWidget);
  });

  testWidgets('calls onShown after the snackbar is presented', (tester) async {
    var shown = 0;
    await pumpListener(
      tester,
      onShown: (_, _) => shown += 1,
    );

    cubit.setMessage('boom');
    await tester.pump();

    expect(shown, 1);
  });
}
