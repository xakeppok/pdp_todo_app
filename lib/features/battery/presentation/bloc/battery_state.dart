import 'package:equatable/equatable.dart';

sealed class BatteryState extends Equatable {
  const BatteryState();

  @override
  List<Object?> get props => [];
}

final class BatteryInitial extends BatteryState {
  const BatteryInitial();
}

final class BatteryLoading extends BatteryState {
  const BatteryLoading();
}

final class BatteryLoaded extends BatteryState {
  const BatteryLoaded(this.batteryLevel);

  final int batteryLevel;

  @override
  List<Object?> get props => [batteryLevel];
}

final class BatteryError extends BatteryState {
  const BatteryError(this.error);

  final String error;

  @override
  List<Object?> get props => [error];
}
