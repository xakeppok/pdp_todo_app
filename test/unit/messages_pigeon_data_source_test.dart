import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/core/pigeon/platform_apis.g.dart';
import 'package:pdp_todo_app/features/messages/data/datasources/messages_pigeon_data_source.dart';

class MockMessagesHostApi extends Mock implements MessagesHostApi {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMessagesHostApi api;
  late MessagesPigeonDataSource dataSource;

  setUpAll(() {
    registerFallbackValue(
      ApiChannelMessage(
        type: ApiMessageType.ping,
        id: '',
        payload: '',
      ),
    );
  });

  setUp(() {
    api = MockMessagesHostApi();
    dataSource = MessagesPigeonDataSource(api: api);
  });

  test('sends ping and returns pong reply', () async {
    when(() => api.sendPing(any())).thenAnswer(
      (invocation) async {
        final ping = invocation.positionalArguments.first as ApiChannelMessage;
        return ApiChannelMessage(
          type: ApiMessageType.pong,
          id: ping.id,
          payload: 'android:${ping.payload}',
        );
      },
    );

    final pong = await dataSource.sendPing(id: '1', payload: 'hello');

    expect(pong, {
      'type': 'pong',
      'id': '1',
      'payload': 'android:hello',
    });
    verify(
      () => api.sendPing(
        ApiChannelMessage(
          type: ApiMessageType.ping,
          id: '1',
          payload: 'hello',
        ),
      ),
    ).called(1);
  });

  test('maps unexpected reply type to PlatformFailure', () async {
    when(() => api.sendPing(any())).thenAnswer(
      (_) async => ApiChannelMessage(
        type: ApiMessageType.ping,
        id: '1',
        payload: 'nope',
      ),
    );

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

  test('maps mismatched reply id to PlatformFailure', () async {
    when(() => api.sendPing(any())).thenAnswer(
      (_) async => ApiChannelMessage(
        type: ApiMessageType.pong,
        id: 'other',
        payload: 'android:x',
      ),
    );

    expect(
      () => dataSource.sendPing(id: '1', payload: 'x'),
      throwsA(
        isA<PlatformFailure>().having(
          (failure) => failure.message,
          'message',
          'Reply id does not match request',
        ),
      ),
    );
  });

  test('maps missing host implementation to PlatformFailure', () async {
    final unregistered = MessagesPigeonDataSource();

    expect(
      () => unregistered.sendPing(id: '1', payload: 'x'),
      throwsA(
        isA<PlatformFailure>().having(
          (failure) => failure.message,
          'message',
          contains('Unable to establish connection'),
        ),
      ),
    );
  });
}
