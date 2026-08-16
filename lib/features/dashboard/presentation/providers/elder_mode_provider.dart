import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Elder-Friendly Mode: a high-contrast, large-button dashboard for elderly
/// users (spec "Special Feature"). Toggled from the dashboard header.
final elderModeProvider = NotifierProvider<ElderModeNotifier, bool>(
  ElderModeNotifier.new,
);

class ElderModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}
