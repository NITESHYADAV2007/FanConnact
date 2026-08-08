import 'package:flutter/widgets.dart';

// App-wide accessibility/behavior preferences (Compact Mode, Reduce
// Animations, Large Text). Placed above the Navigator (via MaterialApp's
// builder) so pushed routes like Settings can read and change them without
// having to thread callbacks through every screen constructor.
class AppPrefs extends InheritedWidget {
  final bool compactMode;
  final bool reduceAnimations;
  final bool largeText;
  final ValueChanged<bool> onCompactModeChanged;
  final ValueChanged<bool> onReduceAnimationsChanged;
  final ValueChanged<bool> onLargeTextChanged;

  const AppPrefs({
    super.key,
    required this.compactMode,
    required this.reduceAnimations,
    required this.largeText,
    required this.onCompactModeChanged,
    required this.onReduceAnimationsChanged,
    required this.onLargeTextChanged,
    required super.child,
  });

  // For use inside build() (registers dependency so widgets rebuild on change).
  static AppPrefs of(BuildContext context) {
    final prefs = context.dependOnInheritedWidgetOfExactType<AppPrefs>();
    assert(prefs != null, 'AppPrefs not found above this widget');
    return prefs!;
  }

  // For use inside event handlers (no dependency registration).
  static AppPrefs? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppPrefs>();

  @override
  bool updateShouldNotify(AppPrefs oldWidget) =>
      compactMode != oldWidget.compactMode ||
      reduceAnimations != oldWidget.reduceAnimations ||
      largeText != oldWidget.largeText;
}
