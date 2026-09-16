import 'package:flutter/material.dart';
import 'package:hydro_track/services/auth_service.dart';
import 'package:hydro_track/services/theme_service.dart';
import 'package:hydro_track/screens/profile_screen.dart';
import 'package:hydro_track/screens/bluetooth_screen.dart';
import 'package:hydro_track/screens/login_screen.dart';
import 'package:hydro_track/screens/history_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final _themeService = ThemeService();

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final connectedDevice = authService.connectedDevice;
    final isDark = _themeService.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final iconColor = const Color(0xFF00ADB5);
    final drawerBg = isDark ? const Color(0xFF121212) : Colors.white;
    final headerBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F6F8);

    return Drawer(
      backgroundColor: drawerBg,
      child: Column(
        children: [
          // Drawer Header
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: const Color(0xFF00ADB5).withOpacity(0.1),
              child: const Icon(Icons.person, size: 40, color: Color(0xFF00ADB5)),
            ),
            accountName: Text(
              authService.username ?? 'Kullanıcı',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
            ),
            accountEmail: Text(
              authService.email ?? 'e-posta yok',
              style: const TextStyle(color: Colors.grey),
            ),
          ),

          // Ana Ekran
          ListTile(
            leading: Icon(Icons.dashboard_outlined, color: iconColor),
            title: Text('Ana Ekran', style: TextStyle(color: textColor)),
            onTap: () => Navigator.of(context).pop(),
          ),

          // Profilim
          ListTile(
            leading: Icon(Icons.person_outline, color: iconColor),
            title: Text('Profilim', style: TextStyle(color: textColor)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),

          // Geçmiş
          ListTile(
            leading: Icon(Icons.history_outlined, color: iconColor),
            title: Text('Geçmiş Ölçümlerim', style: TextStyle(color: textColor)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),

          // Cihaz Bağlantısı
          ListTile(
            leading: Icon(
              Icons.bluetooth_connected,
              color: connectedDevice != null ? Colors.green : iconColor,
            ),
            title: Text('Cihaz Bağlantısı', style: TextStyle(color: textColor)),
            subtitle: Text(
              connectedDevice ?? 'Cihaz Bağlı Değil',
              style: TextStyle(
                color: connectedDevice != null ? Colors.green : Colors.grey,
                fontSize: 11,
              ),
            ),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const BluetoothScreen()),
              );
            },
          ),

          const Spacer(),
          Divider(color: isDark ? Colors.white10 : Colors.black12),

          // Gece / Gündüz Modu Toggle
          ValueListenableBuilder<ThemeMode>(
            valueListenable: _themeService,
            builder: (context, themeMode, _) {
              final isCurrentlyDark = themeMode == ThemeMode.dark;
              return ListTile(
                leading: Icon(
                  isCurrentlyDark ? Icons.dark_mode : Icons.light_mode,
                  color: isCurrentlyDark ? Colors.amber : const Color(0xFF00ADB5),
                ),
                title: Text(
                  isCurrentlyDark ? 'Gece Modu' : 'Gündüz Modu',
                  style: TextStyle(color: textColor),
                ),
                trailing: Switch(
                  value: isCurrentlyDark,
                  activeColor: Colors.amber,
                  inactiveThumbColor: const Color(0xFF00ADB5),
                  inactiveTrackColor: const Color(0xFF00ADB5).withOpacity(0.3),
                  onChanged: (_) => _themeService.toggleTheme(),
                ),
                onTap: () => _themeService.toggleTheme(),
              );
            },
          ),

          Divider(color: isDark ? Colors.white10 : Colors.black12),

          // Çıkış Yap
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text('Çıkış Yap', style: TextStyle(color: textColor.withOpacity(0.7))),
            onTap: () {
              authService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
