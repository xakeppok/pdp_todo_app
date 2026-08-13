import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/battery/domain/usecases/get_battery_level.dart';
import 'package:pdp_todo_app/features/battery/presentation/bloc/battery_state.dart';

class BatteryCubit extends Cubit<BatteryState> {
  BatteryCubit(this._getBatteryLevel) : super(const BatteryInitial());

  final GetBatteryLevel _getBatteryLevel;

  Future<void> getBatteryLevel() async {
    emit(const BatteryLoading());
    try {
      final batteryLevel = await _getBatteryLevel();
      emit(BatteryLoaded(batteryLevel));
    } on Failure catch (e) {
      emit(BatteryError(e.message));
    }
  }
}
