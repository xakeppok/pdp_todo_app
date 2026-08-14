import 'package:equatable/equatable.dart';
import 'package:pdp_todo_app/features/native_map/domain/entities/map_click.dart';

sealed class MapState extends Equatable {
  const MapState();

  @override
  List<Object?> get props => [];
}

final class MapInitial extends MapState {
  const MapInitial();
}

final class MapClicked extends MapState {
  const MapClicked(this.click);

  final MapClick click;

  @override
  List<Object?> get props => [click];
}

final class MapError extends MapState {
  const MapError(this.error);

  final String error;

  @override
  List<Object?> get props => [error];
}
