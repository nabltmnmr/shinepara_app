import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension SafeNavigation on BuildContext {
  void safeGoBack() {
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}
