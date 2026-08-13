import 'package:pdp_todo_app/features/messages/data/datasources/messages_data_source.dart';
import 'package:pdp_todo_app/features/messages/domain/entities/channel_message.dart';
import 'package:pdp_todo_app/features/messages/domain/repositories/messages_repository.dart';

class MessagesRepositoryImpl implements MessagesRepository {
  MessagesRepositoryImpl(this.dataSource);

  final MessagesDataSource dataSource;

  @override
  Future<ChannelMessage> sendPing({
    required String id,
    required String payload,
  }) async {
    final raw = await dataSource.sendPing(id: id, payload: payload);
    return ChannelMessage(
      type: ChannelMessageType.pong,
      id: raw['id']! as String,
      payload: (raw['payload'] as String?) ?? '',
    );
  }
}
