import 'package:pdp_todo_app/features/messages/domain/entities/channel_message.dart';
import 'package:pdp_todo_app/features/messages/domain/repositories/messages_repository.dart';

class SendPing {
  SendPing(this.repository);

  final MessagesRepository repository;

  Future<ChannelMessage> call({
    required String id,
    required String payload,
  }) {
    return repository.sendPing(id: id, payload: payload);
  }
}
