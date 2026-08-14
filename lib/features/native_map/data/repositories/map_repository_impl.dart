import 'package:pdp_todo_app/features/native_map/data/datasources/map_data_source.dart';
import 'package:pdp_todo_app/features/native_map/domain/entities/map_click.dart';
import 'package:pdp_todo_app/features/native_map/domain/repositories/map_repository.dart';

class MapRepositoryImpl implements MapRepository {
  MapRepositoryImpl(this._dataSource);

  final MapDataSource _dataSource;

  @override
  Stream<MapClick> get mapClicks => _dataSource.mapClicks;
}
