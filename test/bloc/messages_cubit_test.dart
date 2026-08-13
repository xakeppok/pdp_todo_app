import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/messages/domain/entities/channel_message.dart';
import 'package:pdp_todo_app/features/messages/presentation/bloc/messages_cubit.dart';
import 'package:pdp_todo_app/features/messages/presentation/bloc/messages_state.dart';

import '../helpers/pump_app.dart';

void main() {
  late MockSendPing sendPing;

  setUp(() {
    sendPing = MockSendPing();
  });

  MessagesCubit buildCubit({String Function()? idFactory}) {
    return MessagesCubit(
      sendPing: sendPing,
      idFactory: idFactory ?? () => 'id-1',
    );
  }

  test('starts in initial state', () {
    expect(buildCubit().state, const MessagesInitial());
  });

  blocTest<MessagesCubit, MessagesState>(
    'sendPing appends ping then pong',
    build: buildCubit,
    seed: () => const MessagesActive(),
    setUp: () {
      when(
        () => sendPing(id: 'id-1', payload: 'hello'),
      ).thenAnswer(
        (_) async => const ChannelMessage(
          type: ChannelMessageType.pong,
          id: 'id-1',
          payload: 'android:hello',
        ),
      );
    },
    act: (cubit) => cubit.sendPing('hello'),
    expect: () => [
      const MessagesActive(
        entries: [
          ChannelMessage(
            type: ChannelMessageType.ping,
            id: 'id-1',
            payload: 'hello',
          ),
        ],
        isSending: true,
      ),
      const MessagesActive(
        entries: [
          ChannelMessage(
            type: ChannelMessageType.ping,
            id: 'id-1',
            payload: 'hello',
          ),
          ChannelMessage(
            type: ChannelMessageType.pong,
            id: 'id-1',
            payload: 'android:hello',
          ),
        ],
      ),
    ],
  );

  blocTest<MessagesCubit, MessagesState>(
    'sendPing emits error on PlatformFailure',
    build: buildCubit,
    seed: () => const MessagesActive(),
    setUp: () {
      when(
        () => sendPing(id: 'id-1', payload: 'hello'),
      ).thenThrow(const PlatformFailure('Messages channel returned null'));
    },
    act: (cubit) => cubit.sendPing('hello'),
    expect: () => [
      const MessagesActive(
        entries: [
          ChannelMessage(
            type: ChannelMessageType.ping,
            id: 'id-1',
            payload: 'hello',
          ),
        ],
        isSending: true,
      ),
      const MessagesActive(
        entries: [
          ChannelMessage(
            type: ChannelMessageType.ping,
            id: 'id-1',
            payload: 'hello',
          ),
        ],
        error: 'Messages channel returned null',
      ),
    ],
  );
}
