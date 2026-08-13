import 'package:pdp_todo_app/features/messages/domain/entities/channel_message.dart';

abstract class MessagesRepository {
  Future<ChannelMessage> sendPing({
    required String id,
    required String payload,
  });
}
