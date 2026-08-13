import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdp_todo_app/core/widgets/fade_switcher.dart';
import 'package:pdp_todo_app/core/widgets/snack_bar_listener.dart';
import 'package:pdp_todo_app/features/battery/presentation/bloc/battery_cubit.dart';
import 'package:pdp_todo_app/features/battery/presentation/bloc/battery_state.dart';

class BatteryWidget extends StatefulWidget {
  const BatteryWidget({super.key});

  @override
  State<BatteryWidget> createState() => _BatteryWidgetState();
}

class _BatteryWidgetState extends State<BatteryWidget> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onStateChange: _onLifecycleStateChange,
    );
  }

  void _onLifecycleStateChange(AppLifecycleState state) {
    if (!mounted) {
      return;
    }
    context.read<BatteryCubit>().handleAppLifecycle(state);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SnackBarListener<BatteryCubit, BatteryState>(
      messageOf: (state) => state is BatteryError ? state.error : null,
      child: BlocBuilder<BatteryCubit, BatteryState>(
        builder: (context, state) {
          return FadeSwitcher(
            child: switch (state) {
              BatteryInitial() || BatteryLoading() => const _BatteryCard(
                key: ValueKey('loading'),
              ),
              BatteryLoaded(:final batteryLevel) => _BatteryCard(
                key: const ValueKey('loaded'),
                level: batteryLevel,
                onRefresh: () => context.read<BatteryCubit>().getBatteryLevel(),
              ),
              BatteryError() => _BatteryCard(
                key: const ValueKey('error'),
                hasError: true,
                onRefresh: () => context.read<BatteryCubit>().getBatteryLevel(),
              ),
            },
          );
        },
      ),
    );
  }
}

class _BatteryCard extends StatelessWidget {
  const _BatteryCard({
    super.key,
    this.level,
    this.hasError = false,
    this.onRefresh,
  });

  final int? level;
  final bool hasError;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLoading = level == null && !hasError;
    final color = hasError
        ? scheme.error
        : isLoading
        ? scheme.outline
        : _colorForLevel(scheme, level!);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: Material(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onRefresh,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: isLoading
                ? _LoadingRow(color: color)
                : hasError
                ? _ErrorRow(color: color)
                : _LoadedRow(level: level!, color: color),
          ),
        ),
      ),
    );
  }
}

class _LoadedRow extends StatelessWidget {
  const _LoadedRow({required this.level, required this.color});

  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = level.clamp(0, 100);

    return Row(
      children: [
        _BatteryGlyph(level: clamped, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$clamped%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Battery',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  _StatusPill(label: _labelForLevel(clamped), color: color),
                ],
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: clamped / 100),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.18),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _BatteryGlyph(level: 0, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reading battery…',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  color: color.withValues(alpha: 0.55),
                  backgroundColor: color.withValues(alpha: 0.16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(Icons.battery_unknown_rounded, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Battery unavailable',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        Text(
          'Tap to retry',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _BatteryGlyph extends StatelessWidget {
  const _BatteryGlyph({required this.level, required this.color});

  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 18,
      child: CustomPaint(
        painter: _BatteryPainter(level: level, color: color),
      ),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  const _BatteryPainter({required this.level, required this.color});

  final int level;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const capWidth = 3.2;
    const stroke = 1.7;
    const inset = 2.2;
    final bodyWidth = size.width - capWidth - 1.5;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, bodyWidth, size.height),
      const Radius.circular(4),
    );

    canvas.drawRRect(
      body.deflate(stroke / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color,
    );

    final capTop = size.height * 0.28;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          bodyWidth + 0.6,
          capTop,
          capWidth,
          size.height - capTop * 2,
        ),
        const Radius.circular(1.2),
      ),
      Paint()..color = color,
    );

    final inner = Rect.fromLTWH(
      inset,
      inset,
      bodyWidth - inset * 2,
      size.height - inset * 2,
    );
    final fillWidth = inner.width * (level.clamp(0, 100) / 100);
    if (fillWidth <= 0) {
      return;
    }

    canvas
      ..save()
      ..clipRRect(RRect.fromRectAndRadius(inner, const Radius.circular(2)))
      ..drawRect(
        Rect.fromLTWH(inner.left, inner.top, fillWidth, inner.height),
        Paint()..color = color,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.color != color;
  }
}

Color _colorForLevel(ColorScheme scheme, int level) {
  if (level <= 20) {
    return scheme.error;
  }
  if (level <= 50) {
    return const Color(0xFFD4A017);
  }
  return scheme.primary;
}

String _labelForLevel(int level) {
  if (level <= 20) {
    return 'Low';
  }
  if (level <= 50) {
    return 'Fair';
  }
  if (level <= 80) {
    return 'Good';
  }
  return 'Full';
}
