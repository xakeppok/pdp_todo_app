import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable implements Exception {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => switch (this) {
        ValidationFailure() => 'ValidationFailure: $message',
        NotFoundFailure() => 'NotFoundFailure: $message',
        ServerFailure() => 'ServerFailure: $message',
        DomainFailure() => 'DomainFailure: $message',
      };
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

final class DomainFailure extends Failure {
  const DomainFailure(super.message);
}
