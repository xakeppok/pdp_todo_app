import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdp_todo_app/core/widgets/snack_bar_listener.dart';
import 'package:pdp_todo_app/features/native_map/presentation/bloc/map_cubit.dart';
import 'package:pdp_todo_app/features/native_map/presentation/bloc/map_state.dart';
import 'package:pdp_todo_app/features/native_map/presentation/native_map_keys.dart';

class NativeMapPage extends StatelessWidget {
  const NativeMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SnackBarListener<MapCubit, MapState>(
      messageOf: (state) => state is MapError ? state.error : null,
      child: Scaffold(
        key: NativeMapKeys.page,
        appBar: AppBar(
          title: const Text('Native map'),
        ),
        body: const Stack(
          children: [
            _NativeMapView(),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _ClickBanner(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NativeMapView extends StatelessWidget {
  const _NativeMapView();

  static final Set<Factory<OneSequenceGestureRecognizer>> _gestureRecognizers =
      <Factory<OneSequenceGestureRecognizer>>{
        const Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
      };

  @override
  Widget build(BuildContext context) {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidView(
        viewType: 'native-map',
        gestureRecognizers: _gestureRecognizers,
      ),
      TargetPlatform.iOS => UiKitView(
        viewType: 'native-map',
        gestureRecognizers: _gestureRecognizers,
      ),
      _ => const Center(
        child: Text('Native map is only available on Android and iOS'),
      ),
    };
  }
}

class _ClickBanner extends StatelessWidget {
  const _ClickBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: BlocBuilder<MapCubit, MapState>(
          builder: (context, state) {
            final text = switch (state) {
              MapClicked(:final click) => click.label,
              MapError() => 'Map click stream unavailable',
              MapInitial() => 'Tap the map',
            };
            return Text(
              text,
              key: NativeMapKeys.clickLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            );
          },
        ),
      ),
    );
  }
}
