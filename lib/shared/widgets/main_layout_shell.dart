import 'package:flutter/material.dart';
import 'collapsible_sidebar.dart';

/// Shell Tata Letak Utama (Main Layout Shell)
/// Membungkus halaman utama dengan sidebar menetap di layar lebar (tablet/desktop)
/// dan membiarkan halaman dirender full-screen di mobile agar halaman dapat mengelola Drawer-nya sendiri.
class MainLayoutShell extends StatelessWidget {
  final Widget child;

  const MainLayoutShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Anggap layar lebar (desktop/tablet) jika lebar >= 600px
        final isLargeScreen = constraints.maxWidth >= 600;

        if (isLargeScreen) {
          return Scaffold(
            body: Row(
              children: [
                const CollapsibleSidebar(isDrawer: false),
                Expanded(
                  child: child,
                ),
              ],
            ),
          );
        } else {
          // Di layar kecil (mobile), tampilkan child secara langsung.
          // Drawer akan dipasang di dalam masing-masing Scaffold halaman utama.
          return child;
        }
      },
    );
  }
}
