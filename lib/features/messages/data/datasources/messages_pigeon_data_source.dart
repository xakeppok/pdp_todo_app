import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/core/pigeon/platform_apis.g.dart';
import 'package:pdp_todo_app/core/platform/platform_error_mapper.dart';
import 'package:pdp_todo_app/features/messages/data/datasources/messages_data_source.dart';

class MessagesPigeonDataSource implements MessagesDataSource {
  MessagesPigeonDataSource({
    MessagesHostApi? api,
  }) : _api = api ?? MessagesHostApi();

  final MessagesHostApi _api;

  @override
  Future<Map<String, Object?>> sendPing({
    required String id,
    required String payload,
  }) {
    return mapPlatformErrors(
      () async {
        final reply = await _api.sendPing(
          ApiChannelMessage(
            type: ApiMessageType.ping,
            id: id,
            payload: payload,
          ),
        );

        if (reply.type != ApiMessageType.pong) {
          throw const PlatformFailure('Expected pong reply');
        }
        if (reply.id != id) {
          throw const PlatformFailure('Reply id does not match request');
        }

        return <String, Object?>{
          'type': 'pong',
          'id': reply.id,
          'payload': reply.payload,
        };
      },
      fallback: 'Failed to send ping',
      missingPlugin: 'Messages pigeon API is not implemented',
    );
  }
}
