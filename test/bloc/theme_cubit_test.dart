import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdp_todo_app/app/theme_cubit.dart';

void main() {
  group('ThemeCubit', () {
    test('starts with system by default', () {
      expect(ThemeCubit().state, ThemeMode.system);
    });

    test('starts with provided mode', () {
      expect(ThemeCubit(ThemeMode.dark).state, ThemeMode.dark);
    });

    blocTest<ThemeCubit, ThemeMode>(
      'setMode emits the given mode',
      build: ThemeCubit.new,
      act: (cubit) => cubit.setMode(ThemeMode.light),
      expect: () => [ThemeMode.light],
    );

    blocTest<ThemeCubit, ThemeMode>(
      'cycle goes system → light → dark → system',
      build: ThemeCubit.new,
      act: (cubit) {
        cubit
          ..cycle()
          ..cycle()
          ..cycle();
      },
      expect: () => [
        ThemeMode.light,
        ThemeMode.dark,
        ThemeMode.system,
      ],
    );
  });
}
