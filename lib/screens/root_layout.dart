import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class RootLayout extends StatefulWidget {
  final Widget child;
  final int selectedIndex;

  const RootLayout({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  @override
  State<RootLayout> createState() => _RootLayoutState();
}

class _RootLayoutState extends State<RootLayout> {
  void _onItemTapped(int index) {
    // Navigate based on index
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/videos');
        break;
      case 2:
        context.go('/create');
        break;
      case 3:
        context.go('/models');
        break;
      case 4:
        context.go('/profile');
        break;
      // Add other cases as needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Stack(
        alignment: Alignment.center,
        children: [
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.black,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.grey,
            currentIndex: widget.selectedIndex,
            onTap: _onItemTapped,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.video_library),
                label: 'My Videos',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  height: 27,
                  width: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.black,
                    size: 25,
                  ),
                ),
                label: '',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.face),
                label: 'Models',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
} 