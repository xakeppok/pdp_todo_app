import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/messages/domain/entities/channel_message.dart';
import 'package:pdp_todo_app/features/messages/domain/usecases/send_ping.dart';
import 'package:pdp_todo_app/features/messages/presentation/bloc/messages_state.dart';

class MessagesCubit extends Cubit<MessagesState> {
  MessagesCubit({
    required SendPing sendPing,
    String Function()? idFactory,
  }) : _sendPing = sendPing,
       _idFactory = idFactory ?? _defaultIdFactory,
       super(const MessagesInitial());

  static String _defaultIdFactory() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  final SendPing _sendPing;
  final String Function() _idFactory;

  Future<void> sendPing(String payload) async {
    final trimmed = payload.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final id = _idFactory();
    emit(
      MessagesActive(
        entries: [
          ...state.entries,
          ChannelMessage(
            type: ChannelMessageType.ping,
            id: id,
            payload: trimmed,
          ),
        ],
        isSending: true,
      ),
    );

    try {
      final pong = await _sendPing(id: id, payload: trimmed);
      if (isClosed) {
        return;
      }
      emit(
        MessagesActive(
          entries: [...state.entries, pong],
        ),
      );
    } on Failure catch (e) {
      if (isClosed) {
        return;
      }
      emit(
        MessagesActive(
          entries: state.entries,
          error: e.message,
        ),
      );
    }
  }
}
