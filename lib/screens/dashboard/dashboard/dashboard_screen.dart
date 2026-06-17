import 'package:flutter/material.dart';

import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/stripe_service.dart';
import '../../../utils/responsive_utils.dart';
import '../../../widgets/common/wave_bottom_nav.dart';
import '../../../widgets/dialog/login_required_dialog.dart';
import '../book_appointment/book_location_screen.dart';
import 'dashboard_tab_screen.dart';
import 'myfiles_tab_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String? matterId;

  const DashboardScreen({super.key, required this.matterId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoadingUser = true;
  String? userName;
  bool isAuthenticated = false;

  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadUnreadNotificationCount();
  }

  Future<void> _loadUser() async {
    isAuthenticated = AuthService.isAuthenticated;

    if (isAuthenticated) {
      final name = await AuthManager.getUserName();
      setState(() {
        userName = name;
        isLoadingUser = false;
      });
    } else {
      setState(() {
        isLoadingUser = false;
      });
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    if (!AuthService.isAuthenticated) return;

    try {
      final response = await ApiService.getUnreadNotificationCount();

      if (response['success'] == true) {
        final count = response['data']?['unread_count'] ?? 0;
        if (mounted) {
          setState(() {
            _unreadNotificationCount = count;
          });
        }
      }
    } catch (e) {
      debugPrint("Unread count error: $e");
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 10,
      shadowColor: const Color(0xFFF9B000).withValues(alpha: 0.35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFCA28), Color(0xFFF9B000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
      ),
      title: isLoadingUser
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAuthenticated && userName != null && userName!.isNotEmpty
                      ? "Welcome, $userName"
                      : "Welcome, Guest",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Bansal Immigration",
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () async {
                if (AuthService.isAuthenticated) {
                  await Navigator.pushNamed(context, '/notifications');
                  _loadUnreadNotificationCount();
                } else {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (_) => LoginRequiredDialog(parentContext: context),
                  );
                }
              },
            ),
            if (_unreadNotificationCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    _unreadNotificationCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.person_outline, color: Colors.white),
          onPressed: () {
            if (AuthService.isAuthenticated) {
              Navigator.pushNamed(context, '/profile');
            } else {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) => LoginRequiredDialog(parentContext: context),
              );
            }
          },
        ),
      ],
    );
  }

  void _openProtected(VoidCallback action) {
    if (AuthService.isAuthenticated) {
      action();
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => LoginRequiredDialog(parentContext: context),
      );
    }
  }

  Widget _buildBottomNav() {
    return Container(
      color: Colors.white,
      child: Builder(
        builder: (navContext) {
          final controller = DefaultTabController.of(navContext);
          return AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return WaveBottomNav(
                // Only Home & Files are tabs; the rest open as full pages.
                currentIndex: controller.index,
                tabCount: 2,
                barColor: Colors.white,
                unselectedColor: const Color(0xFF94A3B8),
                onTap: (i) {
                  switch (i) {
                    case 0:
                    case 1:
                      controller.animateTo(i);
                      break;
                    case 2:
                      _openProtected(() => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BookLocationScreen(),
                            ),
                          ));
                      break;
                    case 3:
                      _openProtected(() =>
                          Navigator.pushNamed(context, '/claude-chat-bot'));
                      break;
                    case 4:
                      _openProtected(
                          () => Navigator.pushNamed(context, '/profile'));
                      break;
                  }
                },
                items: const [
                  WaveNavItem(icon: Icons.home_rounded, label: 'Home'),
                  WaveNavItem(icon: Icons.folder_rounded, label: 'Files'),
                  WaveNavItem(
                      icon: Icons.event_available_rounded, label: 'Appts'),
                  WaveNavItem(
                      icon: Icons.chat_bubble_rounded, label: 'Chat'),
                  WaveNavItem(icon: Icons.person_rounded, label: 'Profile'),
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppResponsive.isDesktop(context);

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (tabContext) {
          if (isDesktop) {
            // Desktop: side navigation rail + content
            return Scaffold(
              backgroundColor: const Color(0xFFF5F7FA),
              appBar: _buildAppBar(),
              body: SafeArea(
                bottom: false,
                child: AnimatedBuilder(
                  animation: DefaultTabController.of(tabContext),
                  builder: (context, _) {
                    final tabIndex = DefaultTabController.of(tabContext).index;
                    return Row(
                      children: [
                        NavigationRail(
                          backgroundColor: const Color(0xFFF9B000),
                          selectedIndex: tabIndex,
                          onDestinationSelected: (index) {
                            DefaultTabController.of(tabContext).animateTo(index);
                          },
                          labelType: NavigationRailLabelType.all,
                          selectedIconTheme: const IconThemeData(color: Colors.white),
                          unselectedIconTheme: const IconThemeData(color: Colors.white70),
                          selectedLabelTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          unselectedLabelTextStyle: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          indicatorColor: Colors.white24,
                          destinations: const [
                            NavigationRailDestination(
                              icon: Icon(Icons.home_outlined),
                              selectedIcon: Icon(Icons.home),
                              label: Text('Home'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.folder_outlined),
                              selectedIcon: Icon(Icons.folder),
                              label: Text('Files'),
                            ),
                          ],
                        ),
                        const VerticalDivider(thickness: 1, width: 1),
                        Expanded(
                          child: TabBarView(
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              DashboardTabScreen(matterId: widget.matterId),
                              const MyFilesTabScreen(),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          }

          // Mobile / Tablet: bottom tab bar
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            appBar: _buildAppBar(),
            body: SafeArea(
              bottom: false,
              child: TabBarView(
                children: [
                  DashboardTabScreen(matterId: widget.matterId),
                  const MyFilesTabScreen(),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomNav(),
          );
        },
      ),
    );
  }
}
