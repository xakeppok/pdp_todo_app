import 'package:pdp_todo_app/features/battery/domain/repositories/battery_repository.dart';

class GetBatteryLevel {
  GetBatteryLevel(this.repository);
  final BatteryRepository repository;

  Future<int> call() async {
    return repository.getBatteryLevel();
  }
}
