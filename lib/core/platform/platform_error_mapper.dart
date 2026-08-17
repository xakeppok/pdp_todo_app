import 'package:flutter/services.dart';
import 'package:pdp_todo_app/core/error/failures.dart';

Future<T> mapPlatformErrors<T>(
  Future<T> Function() action, {
  required String fallback,
  required String missingPlugin,
}) async {
  try {
    return await action();
  } on PlatformFailure {
    rethrow;
  } on PlatformException catch (error) {
    throw PlatformFailure(error.message ?? fallback);
  } on MissingPluginException catch (error) {
    throw PlatformFailure(error.message ?? missingPlugin);
  }
}

Stream<T> mapPlatformStreamErrors<T>(
  Stream<T> stream, {
  required String fallback,
  required String missingPlugin,
}) {
  return stream.handleError((Object error, StackTrace stackTrace) {
    if (error is PlatformException) {
      throw PlatformFailure(error.message ?? fallback);
    }
    if (error is MissingPluginException) {
      throw PlatformFailure(error.message ?? missingPlugin);
    }
    Error.throwWithStackTrace(error, stackTrace);
  });
}
