import 'package:flutter/material.dart';

import 'controllers/preference_controller.dart';

class PreferenceScope extends InheritedNotifier<PreferenceController> {
  const PreferenceScope({
    super.key,
    required PreferenceController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  PreferenceController get controller => notifier!;

  static PreferenceController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<PreferenceScope>();
    assert(scope != null, 'PreferenceScope is missing in the widget tree');
    return scope!.controller;
  }
}
