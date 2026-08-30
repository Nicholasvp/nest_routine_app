import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

  static void goToTab(int index) {
    tabIndex.value = index;
  }

  static void goToHome() => tabIndex.value = 0;
  static void goToHistory() => tabIndex.value = 1;
  static void goToInsights() => tabIndex.value = 2;
  static void goToProfile() => tabIndex.value = 3;
}
