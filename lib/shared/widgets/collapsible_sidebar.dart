import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/domain/entities/app_user.dart';

/// Provider reaktif untuk menyimpan status pelipatan side bar
final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

/// Widget Sidebar Navigasi Kiri yang Premium & Collapsible
class CollapsibleSidebar extends ConsumerWidget {
  final bool isDrawer;

  const CollapsibleSidebar({
    super.key,
    this.isDrawer = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCollapsed = ref.watch(sidebarCollapsedProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull ?? AppUser.guest;
    
    // Mendapatkan rute aktif dari GoRouter
    final String location = GoRouterState.of(context).uri.path;

    final theme = Theme.of(context);
    final double width = isDrawer
        ? double.infinity
        : (isCollapsed ? 82.0 : 260.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xff161920) // Deep Dark Slate Surface
            : theme.colorScheme.surface,
        border: isDrawer
            ? null
            : Border(
                right: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.08),
                  width: 1.5,
                ),
              ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 1. Header (Logo & Toggle Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: isCollapsed && !isDrawer
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceBetween,
                children: [
                  // Logo + Teks
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.spa_rounded,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      if (!isCollapsed || isDrawer) ...[
                        const SizedBox(width: 12),
                        const Text(
                          'Dailio',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Tombol Toggle Collapse (Hanya tampil jika bukan di Drawer mobile)
                  if (!isDrawer && !isCollapsed)
                    IconButton(
                      icon: const Icon(Icons.keyboard_double_arrow_left_rounded, size: 20),
                      onPressed: () {
                        ref.read(sidebarCollapsedProvider.notifier).state = true;
                      },
                      style: IconButton.styleFrom(
                        hoverColor: theme.colorScheme.primary.withOpacity(0.08),
                      ),
                    ),
                  if (!isDrawer && isCollapsed)
                    IconButton(
                      icon: const Icon(Icons.keyboard_double_arrow_right_rounded, size: 20),
                      onPressed: () {
                        ref.read(sidebarCollapsedProvider.notifier).state = false;
                      },
                      style: IconButton.styleFrom(
                        hoverColor: theme.colorScheme.primary.withOpacity(0.08),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Daftar Menu Navigasi (Body)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                children: [
                  _SidebarMenuItem(
                    icon: Icons.check_box_outlined,
                    activeIcon: Icons.check_box_rounded,
                    label: 'Kebiasaan',
                    route: '/home',
                    isActive: location == '/home',
                    isCollapsed: isCollapsed && !isDrawer,
                    onTap: () {
                      context.go('/home');
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 8),
                  _SidebarMenuItem(
                    icon: Icons.playlist_add_check_outlined,
                    activeIcon: Icons.playlist_add_check_rounded,
                    label: 'Tugas Harian',
                    route: '/tasks',
                    isActive: location == '/tasks',
                    isCollapsed: isCollapsed && !isDrawer,
                    onTap: () {
                      context.go('/tasks');
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 8),
                  _SidebarMenuItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profil Saya',
                    route: '/profile',
                    isActive: location == '/profile',
                    isCollapsed: isCollapsed && !isDrawer,
                    onTap: () {
                      context.go('/profile');
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 8),
                  _SidebarMenuItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    label: 'Pengaturan',
                    route: '/settings',
                    isActive: location == '/settings',
                    isCollapsed: isCollapsed && !isDrawer,
                    onTap: () {
                      context.go('/settings');
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),

            // 3. User Info Card (Footer)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: EdgeInsets.all(isCollapsed && !isDrawer ? 8 : 12),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xff1c202a)
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.06),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: isCollapsed && !isDrawer
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    // Avatar Pengguna
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                      backgroundImage: user.photoUrl != null
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? Icon(
                              Icons.person_rounded,
                              size: 16,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    ),
                    // Detail Nama (Hilang jika collapsed)
                    if (!isCollapsed || isDrawer) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user.isGuest ? 'Tamu' : (user.displayName ?? 'Pejuang Dailio'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user.isGuest ? 'Lokal' : 'Google Sync',
                              style: TextStyle(
                                fontSize: 10,
                                color: user.isGuest ? Colors.grey : AppTheme.statusDone,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item Menu Kustom Sidebar
class _SidebarMenuItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarMenuItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.isActive,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeBgColor = theme.colorScheme.primary.withOpacity(0.12);
    final activeTextColor = theme.colorScheme.primary;
    final inactiveTextColor = theme.colorScheme.onSurface.withOpacity(0.6);

    Widget itemContent = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? activeTextColor : inactiveTextColor,
              size: 22,
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? activeTextColor : inactiveTextColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // Gunakan Tooltip jika side bar dalam kondisi melipat (collapsed)
    if (isCollapsed) {
      return Tooltip(
        message: label,
        preferBelow: false,
        margin: const EdgeInsets.only(left: 20),
        child: itemContent,
      );
    }

    return itemContent;
  }
}
