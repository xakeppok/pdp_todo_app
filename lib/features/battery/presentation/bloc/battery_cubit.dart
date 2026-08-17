import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/battery/domain/usecases/get_battery_level.dart';
import 'package:pdp_todo_app/features/battery/presentation/bloc/battery_state.dart';

class BatteryCubit extends Cubit<BatteryState> {
  BatteryCubit(this._getBatteryLevel) : super(const BatteryInitial());

  final GetBatteryLevel _getBatteryLevel;

  void handleAppLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(getBatteryLevel());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> getBatteryLevel() async {
    if (isClosed) {
      return;
    }
    if (state is! BatteryLoaded) {
      emit(const BatteryLoading());
    }
    try {
      final batteryLevel = await _getBatteryLevel();
      if (isClosed) {
        return;
      }
      emit(BatteryLoaded(batteryLevel));
    } on Failure catch (e) {
      if (isClosed) {
        return;
      }
      emit(BatteryError(e.message));
    }
  }
}
