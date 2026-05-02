// Social tab is visible but disabled until later feats.
//   0 — Diary (Phase 1)
//   1 — Betting (Phase 1)
//   2 — Social (disabled until later)
//   3 — More / Profile (Phase 1)
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/routes.dart';

class MatchLogBottomNav extends StatelessWidget {
  const MatchLogBottomNav({super.key});

  static int _locationToIndex(String location) {
    if (location.startsWith(Routes.betting)) {
      return 1;
    }
    if (location.startsWith(Routes.feed)) {
      return 2;
    }
    if (location.startsWith(Routes.profile) ||
        location.startsWith(Routes.settings)) {
      return 3;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    // Colors and style are fully inherited from BottomNavigationBarThemeData
    // defined in AppTheme — no hardcoded values needed here.
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go(Routes.diary);
            break;
          case 1:
            context.go(Routes.betting);
            break;
          case 2:
            context.go(Routes.feed);
            break;
          case 3:
            context.go(Routes.profile);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.book_outlined),
          activeIcon: Icon(Icons.book),
          label: 'Diary',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.track_changes_outlined),
          activeIcon: Icon(Icons.track_changes),
          label: 'Betting',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline_rounded),
          activeIcon: Icon(Icons.people_rounded),
          label: 'Social',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
          label: 'More',
        ),
      ],
    );
  }
}
