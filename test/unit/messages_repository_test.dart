import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/features/messages/data/datasources/messages_data_source.dart';
import 'package:pdp_todo_app/features/messages/data/repositories/messages_repository_impl.dart';
import 'package:pdp_todo_app/features/messages/domain/entities/channel_message.dart';
import 'package:pdp_todo_app/features/messages/domain/usecases/send_ping.dart';

class MockMessagesDataSource extends Mock implements MessagesDataSource {}

void main() {
  late MockMessagesDataSource dataSource;
  late MessagesRepositoryImpl repository;

  setUp(() {
    dataSource = MockMessagesDataSource();
    repository = MessagesRepositoryImpl(dataSource);
  });

  test('maps pong reply to ChannelMessage', () async {
    when(
      () => dataSource.sendPing(id: '7', payload: 'hi'),
    ).thenAnswer(
      (_) async => {
        'type': 'pong',
        'id': '7',
        'payload': 'android:hi',
      },
    );

    await expectLater(
      repository.sendPing(id: '7', payload: 'hi'),
      completion(
        const ChannelMessage(
          type: ChannelMessageType.pong,
          id: '7',
          payload: 'android:hi',
        ),
      ),
    );
  });

  test('SendPing delegates to repository', () async {
    when(
      () => dataSource.sendPing(id: '1', payload: 'x'),
    ).thenAnswer(
      (_) async => {
        'type': 'pong',
        'id': '1',
        'payload': 'android:x',
      },
    );

    await expectLater(
      SendPing(repository)(id: '1', payload: 'x'),
      completion(
        const ChannelMessage(
          type: ChannelMessageType.pong,
          id: '1',
          payload: 'android:x',
        ),
      ),
    );
  });
}
