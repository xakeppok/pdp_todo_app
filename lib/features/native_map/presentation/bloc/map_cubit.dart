import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/native_map/domain/entities/map_click.dart';
import 'package:pdp_todo_app/features/native_map/domain/usecases/watch_map_clicks.dart';
import 'package:pdp_todo_app/features/native_map/presentation/bloc/map_state.dart';

class MapCubit extends Cubit<MapState> {
  MapCubit(this._watchMapClicks) : super(const MapInitial());

  final WatchMapClicks _watchMapClicks;
  StreamSubscription<MapClick>? _subscription;

  void watch() {
    unawaited(_subscription?.cancel());
    _subscription = _watchMapClicks().listen(
      (click) {
        if (!isClosed) {
          emit(MapClicked(click));
        }
      },
      onError: (Object error) {
        if (isClosed) {
          return;
        }
        final message = error is Failure ? error.message : error.toString();
        emit(MapError(message));
      },
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
