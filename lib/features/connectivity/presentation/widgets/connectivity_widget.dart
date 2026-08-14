import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdp_todo_app/core/widgets/fade_switcher.dart';
import 'package:pdp_todo_app/core/widgets/snack_bar_listener.dart';
import 'package:pdp_todo_app/features/connectivity/domain/entities/connectivity_status.dart';
import 'package:pdp_todo_app/features/connectivity/presentation/bloc/connectivity_cubit.dart';
import 'package:pdp_todo_app/features/connectivity/presentation/bloc/connectivity_state.dart';

class ConnectivityWidget extends StatelessWidget {
  const ConnectivityWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SnackBarListener<ConnectivityCubit, ConnectivityState>(
      messageOf: (state) => state is ConnectivityError ? state.error : null,
      child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, state) {
          return FadeSwitcher(
            child: switch (state) {
              ConnectivityInitial() ||
              ConnectivityLoading() => const _ConnectivityCard(
                key: ValueKey('loading'),
              ),
              ConnectivityLoaded(:final status) => _ConnectivityCard(
                key: ValueKey(status.name),
                status: status,
                onRetry: () => context.read<ConnectivityCubit>().watch(),
              ),
              ConnectivityError() => _ConnectivityCard(
                key: const ValueKey('error'),
                hasError: true,
                onRetry: () => context.read<ConnectivityCubit>().watch(),
              ),
            },
          );
        },
      ),
    );
  }
}

class _ConnectivityCard extends StatelessWidget {
  const _ConnectivityCard({
    super.key,
    this.status,
    this.hasError = false,
    this.onRetry,
  });

  final ConnectivityStatus? status;
  final bool hasError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLoading = status == null && !hasError;
    final color = hasError
        ? scheme.error
        : isLoading
        ? scheme.outline
        : _colorForStatus(scheme, status!);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: Material(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onRetry,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: isLoading
                ? _LoadingRow(color: color)
                : hasError
                ? _ErrorRow(color: color)
                : _LoadedRow(status: status!, color: color),
          ),
        ),
      ),
    );
  }
}

class _LoadedRow extends StatelessWidget {
  const _LoadedRow({required this.status, required this.color});

  final ConnectivityStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final online = status.isOnline;

    return Row(
      children: [
        Icon(_iconForStatus(status), color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            status.label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: color,
            ),
          ),
        ),
        _StatusPill(
          label: online ? 'Online' : 'Offline',
          color: color,
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
        Icon(Icons.wifi_find_rounded, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Checking connection…',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
        Icon(Icons.wifi_off_rounded, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Connectivity unavailable',
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

IconData _iconForStatus(ConnectivityStatus status) {
  return switch (status) {
    ConnectivityStatus.wifi => Icons.wifi_rounded,
    ConnectivityStatus.mobile => Icons.signal_cellular_alt_rounded,
    ConnectivityStatus.none => Icons.wifi_off_rounded,
  };
}

Color _colorForStatus(ColorScheme scheme, ConnectivityStatus status) {
  return switch (status) {
    ConnectivityStatus.none => scheme.error,
    ConnectivityStatus.wifi || ConnectivityStatus.mobile => scheme.primary,
  };
}
