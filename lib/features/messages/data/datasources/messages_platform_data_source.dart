import 'package:flutter/services.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/messages/data/datasources/messages_data_source.dart';

class MessagesPlatformDataSource implements MessagesDataSource {
  MessagesPlatformDataSource({
    BasicMessageChannel<Object?>? channel,
  }) : _channel =
           channel ??
           const BasicMessageChannel<Object?>(
             channelName,
             StandardMessageCodec(),
           );

  static const channelName = 'pdp.flutter.app/messages';

  final BasicMessageChannel<Object?> _channel;

  @override
  Future<Map<String, Object?>> sendPing({
    required String id,
    required String payload,
  }) async {
    try {
      final reply = await _channel.send(<String, Object?>{
        'type': 'ping',
        'id': id,
        'payload': payload,
      });

      if (reply == null) {
        throw const PlatformFailure('Messages channel returned null');
      }
      if (reply is! Map) {
        throw const PlatformFailure('Message has unexpected type');
      }

      final map = <String, Object?>{
        for (final entry in reply.entries) '${entry.key}': entry.value,
      };
      final type = map['type']?.toString() ?? '';
      final replyId = map['id']?.toString() ?? '';
      final replyPayload = map['payload']?.toString() ?? '';

      if (type != 'pong') {
        throw const PlatformFailure('Expected pong reply');
      }
      if (replyId != id) {
        throw const PlatformFailure('Reply id does not match request');
      }

      return <String, Object?>{
        'type': type,
        'id': replyId,
        'payload': replyPayload,
      };
    } on PlatformException catch (e) {
      throw PlatformFailure(e.message ?? 'Failed to send ping');
    } on MissingPluginException catch (e) {
      throw PlatformFailure(
        e.message ?? 'Messages channel is not implemented',
      );
    }
  }
}
