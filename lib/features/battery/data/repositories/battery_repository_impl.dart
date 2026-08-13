import 'package:pdp_todo_app/features/battery/data/datasources/battery_data_source.dart';
import 'package:pdp_todo_app/features/battery/domain/repositories/battery_repository.dart';

class BatteryRepositoryImpl implements BatteryRepository {
  BatteryRepositoryImpl(this.dataSource);
  final BatteryDataSource dataSource;

  @override
  Future<int> getBatteryLevel() async {
    return dataSource.getBatteryLevel();
  }
}
