import 'package:flutter/material.dart';
import '../main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class UserNav extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String avatarUrl;

  const UserNav({
    super.key,
    this.userName = "Jane Doe",
    this.userEmail = "jane.doe@example.com",
    this.avatarUrl = "https://placehold.co/100x100.png",
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(avatarUrl),
        child:
            avatarUrl.isEmpty
                ? Text(
                  userName.isNotEmpty
                      ? userName.split(' ').map((e) => e[0]).take(2).join()
                      : 'JD',
                  style: const TextStyle(color: Colors.white),
                )
                : null,
      ),
      itemBuilder:
          (context) => [
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    userEmail,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 1,
              child: Row(
                children: const [
                  Icon(Icons.person, size: 18),
                  SizedBox(width: 8),
                  Text('Profile'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 2,
              child: Row(
                children: const [
                  Icon(Icons.settings, size: 18),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 3,
              child: Row(
                children: const [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 8),
                  Text('Log out'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(enabled: false, child: Center(child: ThemeToggle())),
          ],
      onSelected: (value) async {
        // Handle menu actions here
        if (value == 1) {
          // Navigate to Profile
        } else if (value == 2) {
          // Navigate to Settings
        } else if (value == 3) {
          // Log out
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');

          if (token != null) {
            try {
              final response = await http.post(
                Uri.parse('http://localhost:8000/api/logout'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              );

              if (response.statusCode == 200) {
                // Clear all stored data
                await prefs.clear();

                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } else {
                // Even if API call fails, clear local data and redirect
                await prefs.clear();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            } catch (e) {
              // Even if API call fails, clear local data and redirect
              await prefs.clear();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            }
          } else {
            // No token found, just redirect to login
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          }
        }
      },
    );
  }
}

// Dummy ThemeToggle widget for demonstration
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      onPressed: () {
        themeModeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
      },
    );
  }
}
