import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdp_todo_app/core/widgets/snack_bar_listener.dart';
import 'package:pdp_todo_app/features/messages/domain/entities/channel_message.dart';
import 'package:pdp_todo_app/features/messages/presentation/bloc/messages_cubit.dart';
import 'package:pdp_todo_app/features/messages/presentation/bloc/messages_state.dart';
import 'package:pdp_todo_app/features/messages/presentation/messages_keys.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _controller = TextEditingController(text: 'hello');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SnackBarListener<MessagesCubit, MessagesState>(
      messageOf: (state) => state.error,
      child: Scaffold(
        key: MessagesKeys.page,
        appBar: AppBar(
          title: const Text('Messages channel'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'BasicMessageChannel: ping → pong',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: MessagesKeys.payloadField,
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'ping payload',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<MessagesCubit, MessagesState>(
                    buildWhen: (previous, current) =>
                        previous.isSending != current.isSending,
                    builder: (context, state) {
                      return FilledButton(
                        key: MessagesKeys.pingButton,
                        onPressed: state.isSending
                            ? null
                            : () => _send(context),
                        child: state.isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Ping'),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Log',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<MessagesCubit, MessagesState>(
                  builder: (context, state) {
                    if (state.entries.isEmpty) {
                      return Text(
                        'Press Ping',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      );
                    }

                    final entries = state.entries.reversed.toList();
                    return ListView.separated(
                      key: MessagesKeys.logList,
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        return _MessageTile(message: entries[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _send(BuildContext context) {
    unawaited(context.read<MessagesCubit>().sendPing(_controller.text));
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.message});

  final ChannelMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (message.type) {
      ChannelMessageType.ping => theme.colorScheme.tertiary,
      ChannelMessageType.pong => theme.colorScheme.primary,
    };

    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                message.type.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.payload.isEmpty ? '—' : message.payload,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'id: ${message.id}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
