import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension SnackBarMessenger on BuildContext {
  void showSnackBarMessage(String message) {
    ScaffoldMessenger.of(this)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class SnackBarListener<B extends StateStreamable<S>, S>
    extends BlocListener<B, S> {
  SnackBarListener({
    required String? Function(S state) messageOf,
    void Function(BuildContext context, S state)? onShown,
    super.key,
    super.bloc,
    super.child,
  }) : super(
         listenWhen: (previous, current) {
           final message = messageOf(current);
           return message != null && message != messageOf(previous);
         },
         listener: (context, state) {
           final message = messageOf(state);
           if (message == null) {
             return;
           }
           context.showSnackBarMessage(message);
           onShown?.call(context, state);
         },
       );
}
