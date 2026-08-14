import 'package:equatable/equatable.dart';

enum ChannelMessageType {
  ping('ping'),
  pong('pong');

  const ChannelMessageType(this.label);

  final String label;
}

class ChannelMessage extends Equatable {
  const ChannelMessage({
    required this.type,
    required this.id,
    required this.payload,
  });

  final ChannelMessageType type;
  final String id;
  final String payload;

  @override
  List<Object?> get props => [type, id, payload];
}
