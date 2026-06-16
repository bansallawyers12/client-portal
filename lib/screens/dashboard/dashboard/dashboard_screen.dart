import 'package:flutter/material.dart';

import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/stripe_service.dart';
import '../../../utils/responsive_utils.dart';
import '../../../widgets/dialog/login_required_dialog.dart';
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

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF101722),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.20),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TabBar(
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: const Color(0xFFF9B000),
                borderRadius: BorderRadius.circular(30),
              ),
              indicatorPadding: const EdgeInsets.all(4),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              splashFactory: NoSplash.splashFactory,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_outlined, size: 20),
                      SizedBox(width: 6),
                      Text("Home"),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_outlined, size: 20),
                      SizedBox(width: 6),
                      Text("Files"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
              backgroundColor: const Color(0xFF223344),
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
            backgroundColor: const Color(0xFF223344),
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
            bottomNavigationBar: SafeArea(
              child: _buildBottomNav(),
            ),
          );
        },
      ),
    );
  }
}
