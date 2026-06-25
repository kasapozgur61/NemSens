import 'package:flutter/material.dart';
import 'package:hydro_track/services/auth_service.dart';
import 'package:hydro_track/screens/profile_screen.dart';
import 'package:hydro_track/screens/bluetooth_screen.dart';
import 'package:hydro_track/screens/login_screen.dart';
import 'package:hydro_track/screens/history_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final connectedDevice = authService.connectedDevice;

    return Drawer(
      backgroundColor: const Color(0xFF121212),
      child: Column(
        children: [
          // Drawer Header with User Info
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: const Color(0xFF00ADB5).withOpacity(0.1),
              child: const Icon(Icons.person, size: 40, color: Color(0xFF00ADB5)),
            ),
            accountName: Text(
              authService.username ?? 'Kullanıcı',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(
              authService.email ?? 'e-posta yok',
              style: const TextStyle(color: Colors.grey),
            ),
          ),

          // Drawer Body Menu Items
          ListTile(
            leading: const Icon(Icons.dashboard_outlined, color: Color(0xFF00ADB5)),
            title: const Text('Ana Ekran', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Color(0xFF00ADB5)),
            title: const Text('Profilim', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_outlined, color: Color(0xFF00ADB5)),
            title: const Text('Geçmiş Ölçümlerim', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.bluetooth_connected,
              color: connectedDevice != null ? Colors.green : const Color(0xFF00ADB5),
            ),
            title: const Text('Cihaz Bağlantısı', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              connectedDevice ?? 'Cihaz Bağlı Değil',
              style: TextStyle(color: connectedDevice != null ? Colors.green : Colors.grey, fontSize: 11),
            ),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const BluetoothScreen()),
              );
            },
          ),
          
          const Spacer(),
          const Divider(color: Colors.white10),
          
          // Logout Item
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Çıkış Yap', style: TextStyle(color: Colors.white70)),
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
