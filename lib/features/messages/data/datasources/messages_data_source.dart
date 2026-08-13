abstract class MessagesDataSource {
  Future<Map<String, Object?>> sendPing({
    required String id,
    required String payload,
  });
}
