import 'package:pdp_todo_app/features/native_map/domain/entities/map_click.dart';
import 'package:pdp_todo_app/features/native_map/domain/repositories/map_repository.dart';

class WatchMapClicks {
  const WatchMapClicks(this._repository);

  final MapRepository _repository;

  Stream<MapClick> call() => _repository.mapClicks;
}
