import 'package:flutter/material.dart';

/// Uygulamanin tema durumunu yoneten singleton servis.
/// ValueNotifier kullanarak tum dinleyicileri aninda gunceller.
class ThemeService extends ValueNotifier<ThemeMode> {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal() : super(ThemeMode.dark);

  bool get isDark => value == ThemeMode.dark;

  void toggleTheme() {
    value = isDark ? ThemeMode.light : ThemeMode.dark;
  }
}
