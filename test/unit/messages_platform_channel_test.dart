import 'package:flutter_test/flutter_test.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/messages/data/datasources/messages_platform_data_source.dart';

import '../helpers/mock_messages_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MessagesPlatformDataSource dataSource;
  late List<Object?> log;

  setUp(() {
    log = <Object?>[];
    setMockMessagesChannel((message) async {
      log.add(message);
      final map = Map<String, Object?>.from(message! as Map);
      return <String, Object?>{
        'type': 'pong',
        'id': map['id'],
        'payload': 'android:${map['payload']}',
      };
    });
    dataSource = MessagesPlatformDataSource();
  });

  tearDown(() => setMockMessagesChannel(null));

  test('channel name matches Android and iOS native hosts', () {
    expect(MessagesPlatformDataSource.channelName, 'pdp.flutter.app/messages');
  });

  test('sends ping and returns pong reply', () async {
    final pong = await dataSource.sendPing(id: '1', payload: 'hello');

    expect(pong, {
      'type': 'pong',
      'id': '1',
      'payload': 'android:hello',
    });
    expect(log, [
      {
        'type': 'ping',
        'id': '1',
        'payload': 'hello',
      },
    ]);
  });

  test('maps null reply to PlatformFailure', () async {
    mockMessagesChannelReply(null);

    expect(
      () => dataSource.sendPing(id: '1', payload: 'x'),
      throwsA(
        isA<PlatformFailure>().having(
          (failure) => failure.message,
          'message',
          'Messages channel returned null',
        ),
      ),
    );
  });

  test('maps unexpected reply type to PlatformFailure', () async {
    mockMessagesChannelReply({
      'type': 'ack',
      'id': '1',
      'payload': 'nope',
    });

    expect(
      () => dataSource.sendPing(id: '1', payload: 'x'),
      throwsA(
        isA<PlatformFailure>().having(
          (failure) => failure.message,
          'message',
          'Expected pong reply',
        ),
      ),
    );
  });
}
