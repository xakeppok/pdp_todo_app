import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/features/messages/domain/entities/channel_message.dart';
import 'package:pdp_todo_app/features/messages/presentation/bloc/messages_cubit.dart';
import 'package:pdp_todo_app/features/messages/presentation/messages_keys.dart';
import 'package:pdp_todo_app/features/messages/presentation/pages/messages_page.dart';

import '../helpers/pump_app.dart';

void main() {
  late MockSendPing sendPing;
  late MessagesCubit cubit;

  Future<void> pumpMessages(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const MessagesPage(),
        ),
      ),
    );
  }

  setUp(() {
    sendPing = MockSendPing();
    cubit = MessagesCubit(
      sendPing: sendPing,
      idFactory: () => 'id-1',
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  testWidgets('shows channel page and ping controls', (tester) async {
    await pumpMessages(tester);

    expect(find.byKey(MessagesKeys.page), findsOneWidget);
    expect(find.text('Messages channel'), findsOneWidget);
    expect(find.byKey(MessagesKeys.pingButton), findsOneWidget);
    expect(find.byKey(MessagesKeys.payloadField), findsOneWidget);
  });

  testWidgets('ping button sends payload and shows pong', (tester) async {
    when(
      () => sendPing(id: 'id-1', payload: 'hello'),
    ).thenAnswer(
      (_) async => const ChannelMessage(
        type: ChannelMessageType.pong,
        id: 'id-1',
        payload: 'android:hello',
      ),
    );

    await pumpMessages(tester);
    await tester.tap(find.byKey(MessagesKeys.pingButton));
    await tester.pumpAndSettle();

    expect(find.text('ping'), findsOneWidget);
    expect(find.text('pong'), findsOneWidget);
    expect(find.text('android:hello'), findsOneWidget);
    verify(() => sendPing(id: 'id-1', payload: 'hello')).called(1);
  });
}
