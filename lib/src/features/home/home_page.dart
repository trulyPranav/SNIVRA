import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';
import '../auth/bloc/auth_state.dart';
import '../auth/data/models/auth_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavItem(
      label: 'Bookings',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
    ),
    _NavItem(
      label: 'Slots',
      icon: Icons.settings_suggest_outlined,
      activeIcon: Icons.settings_suggest_rounded,
    ),
  ];

  static const List<Widget> _pages = [
    _PlaceholderPage(label: 'Home'),
    _PlaceholderPage(label: 'Bookings'),
    _PlaceholderPage(label: 'Slots'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial || state is AuthFailure) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (_) => false);
        }
      },
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = state.user;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            scrolledUnderElevation: 1,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            title: Text(_navItems[_currentIndex].label),
            centerTitle: false,
          ),
          drawer: _AppDrawer(user: user),
          body: _pages[_currentIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) =>
                setState(() => _currentIndex = i),
            backgroundColor: Colors.white,
            indicatorColor: AppColors.primary.withAlpha(20),
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            labelBehavior:
                NavigationDestinationLabelBehavior.alwaysShow,
            destinations: _navItems
                .map(
                  (item) => NavigationDestination(
                    icon: Icon(item.icon,
                        color: AppColors.textSecondary),
                    selectedIcon: Icon(item.activeIcon,
                        color: AppColors.primary),
                    label: item.label,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$label — coming soon',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
        ),
      ),
    );
  }
}

// ─────────────────────────────── App Drawer ─────────────────────────────────

class _AppDrawer extends StatefulWidget {
  const _AppDrawer({required this.user});

  final AuthUser user;

  @override
  State<_AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<_AppDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _avatarScale;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    _avatarScale = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );
    _fadeIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    ));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.barber:
        return 'Barber';
      case UserRole.customer:
        return 'Customer';
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final initials = _initials(user.name);
    final roleLabel = _roleLabel(user.role);
    final isOwner = user.role == UserRole.owner;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Animated header ─────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryDark, AppColors.primaryLight],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar with scale animation
                  ScaleTransition(
                    scale: _avatarScale,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(30),
                        border: Border.all(
                            color: Colors.white.withAlpha(120), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name + phone fade+slide
                  FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideUp,
                      child: Column(
                        children: [
                          Text(
                            user.name.isNotEmpty ? user.name : 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          if (user.phone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              user.phone,
                              style: TextStyle(
                                color: Colors.white.withAlpha(190),
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 12),
                          // Role chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withAlpha(80),
                                  width: 1),
                            ),
                            child: Text(
                              roleLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.divider),

            // ── Current saloon card ─────────────────────────────────────────
            if (user.saloons.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.saloons.first.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(
                  height: 1,
                  color: AppColors.divider,
                  indent: 16,
                  endIndent: 16),
            ],

            // ── Menu items ──────────────────────────────────────────────────
            const SizedBox(height: 8),

            _DrawerTile(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              trailing: _ComingSoonBadge(),
              onTap: () {},
            ),

            if (isOwner)
              _DrawerTile(
                icon: Icons.storefront_outlined,
                label: 'Edit Saloon',
                trailing: _ComingSoonBadge(),
                onTap: () {},
              ),

            const Spacer(),

            // ── Sign out ────────────────────────────────────────────────────
            const Divider(height: 1, color: AppColors.divider),
            _DrawerTile(
              icon: Icons.logout_outlined,
              label: 'Sign Out',
              iconColor: AppColors.textSecondary,
              labelColor: AppColors.textSecondary,
              onTap: () {
                Navigator.of(context).pop();
                context
                    .read<AuthBloc>()
                    .add(const AuthSignOutRequested());
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Shared drawer tile ───────────────────────────────────────────────────────

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.primary,
    this.labelColor = AppColors.textPrimary,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final Color labelColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

// ── "Coming soon" badge ──────────────────────────────────────────────────────

class _ComingSoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Text(
        'Soon',
        style: TextStyle(
          color: AppColors.textHint,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
