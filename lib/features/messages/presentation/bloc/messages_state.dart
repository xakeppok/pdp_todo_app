import 'package:equatable/equatable.dart';
import 'package:pdp_todo_app/features/messages/domain/entities/channel_message.dart';

sealed class MessagesState extends Equatable {
  const MessagesState({
    this.entries = const [],
    this.isSending = false,
    this.error,
  });

  final List<ChannelMessage> entries;
  final bool isSending;
  final String? error;

  @override
  List<Object?> get props => [entries, isSending, error];
}

final class MessagesInitial extends MessagesState {
  const MessagesInitial() : super();
}

final class MessagesActive extends MessagesState {
  const MessagesActive({
    super.entries,
    super.isSending,
    super.error,
  });
}
