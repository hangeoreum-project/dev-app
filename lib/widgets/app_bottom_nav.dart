import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex; // 0 Explore, 1 Postcard, 2 SNS, 3 Settings
  const AppBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Postcard'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'SNS Search'),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Settings'),
      ],
      onTap: (i) {
        switch (i) {
          case 0:
            if (currentIndex != 0) Navigator.popUntil(context, (r) => r.isFirst);
            break;
          case 1:
            if (currentIndex != 1) Navigator.pushNamed(context, '/postcard');
            break;
          case 2:
            if (currentIndex != 2) Navigator.pushNamed(context, '/sns');
            break;
          case 3:
            if (currentIndex != 3) Navigator.pushNamed(context, '/settings');
            break;
        }
      },
    );
  }
}