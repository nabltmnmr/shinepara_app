import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_screen_fixed.dart';
import '../../features/wishlist/wishlist_screen.dart';
import '../../features/account/account_screen.dart';
import '../../features/skin_scan/skin_scan_home.dart';
import '../theme/colors.dart';
import '../widgets/floating_bottom_nav.dart';

/// Root shell that owns the Shine bottom navigation bar and primary tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeScreen(),
      const WishlistScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      // Let the active page paint its own background behind the floating pill.
      // This avoids any full-width "bar" feeling behind the nav.
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: pages[_index],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: FloatingBottomNav(
              currentIndex: _index,
              onTabSelected: (i) {
                setState(() {
                  _index = i;
                });
              },
              onScanPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SkinScanHomeScreen(),
                  ),
                );
              },
              onAiPressed: () {
                context.push('/ai-assistant');
              },
            ),
          ),
        ),
      ),
    );
  }
}

