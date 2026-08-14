import 'package:pdp_todo_app/features/native_map/domain/entities/map_click.dart';

abstract class MapDataSource {
  Stream<MapClick> get mapClicks;
}
