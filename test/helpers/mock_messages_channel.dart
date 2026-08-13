import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdp_todo_app/features/messages/data/datasources/messages_platform_data_source.dart';

const messagesMessageChannel = BasicMessageChannel<Object?>(
  MessagesPlatformDataSource.channelName,
  StandardMessageCodec(),
);

void setMockMessagesChannel(
  Future<Object?> Function(Object? message)? handler,
) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockDecodedMessageHandler<Object?>(
        messagesMessageChannel,
        handler,
      );
}

void mockMessagesPingPong({String prefix = 'android'}) {
  setMockMessagesChannel((message) async {
    final map = Map<String, Object?>.from(message! as Map);
    return <String, Object?>{
      'type': 'pong',
      'id': map['id'],
      'payload': '$prefix:${map['payload']}',
    };
  });
}

void mockMessagesChannelReply(Object? reply) {
  setMockMessagesChannel((message) async => reply);
}
