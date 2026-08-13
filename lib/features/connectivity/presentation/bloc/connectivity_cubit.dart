import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/connectivity/domain/entities/connectivity_status.dart';
import 'package:pdp_todo_app/features/connectivity/domain/usecases/watch_connectivity.dart';
import 'package:pdp_todo_app/features/connectivity/presentation/bloc/connectivity_state.dart';

class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit(this._watchConnectivity)
    : super(const ConnectivityInitial());

  final WatchConnectivity _watchConnectivity;
  StreamSubscription<ConnectivityStatus>? _subscription;

  void watch() {
    unawaited(_subscription?.cancel());
    emit(const ConnectivityLoading());
    _subscription = _watchConnectivity().listen(
      (status) {
        if (!isClosed) {
          emit(ConnectivityLoaded(status));
        }
      },
      onError: (Object error) {
        if (isClosed) {
          return;
        }
        final message = error is Failure ? error.message : error.toString();
        emit(ConnectivityError(message));
      },
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
