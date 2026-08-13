import 'package:equatable/equatable.dart';
import 'package:pdp_todo_app/features/connectivity/domain/entities/connectivity_status.dart';

sealed class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object?> get props => [];
}

final class ConnectivityInitial extends ConnectivityState {
  const ConnectivityInitial();
}

final class ConnectivityLoading extends ConnectivityState {
  const ConnectivityLoading();
}

final class ConnectivityLoaded extends ConnectivityState {
  const ConnectivityLoaded(this.status);

  final ConnectivityStatus status;

  @override
  List<Object?> get props => [status];
}

final class ConnectivityError extends ConnectivityState {
  const ConnectivityError(this.error);

  final String error;

  @override
  List<Object?> get props => [error];
}
