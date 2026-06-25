import 'package:flutter/material.dart';
import 'package:hydro_track/services/auth_service.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final _authService = AuthService();
  bool isScanning = false;
  
  // Çevrede bulunan sahte cihaz listesi
  List<Map<String, String>> discoveredDevices = [
    {"name": "NemSens - HydroTrack", "id": "7C:9E:BD:45:66:A2", "rssi": "-54"},
    {"name": "Mevcut Değil (Bilinmeyen Cihaz)", "id": "4A:22:CC:11:05:BC", "rssi": "-82"},
    {"name": "Smart Watch v3", "id": "A4:C1:38:7A:11:D3", "rssi": "-70"},
  ];

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startScan() {
    setState(() {
      isScanning = true;
    });
    // 3 saniye sonra tarama bitmiş gibi davranalım
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          isScanning = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Cihaz Tara ve Bağlan'),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        key: const Key('bluetooth_padding'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Biyosensör Bağlantısı",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Lütfen çevredeki Seeed Xiao ESP32-C3 cihazınızı bulmak için taramayı başlatın.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            // Tarama Butonu
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isScanning ? Colors.grey : const Color(0xFF00ADB5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isScanning ? null : _startScan,
                icon: isScanning 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search),
                label: Text(isScanning ? "Cihazlar Aranıyor..." : "Taramayı Başlat"),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              "Bulunan Cihazlar",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            
            // Cihaz Listesi
            Expanded(
              child: ListView.builder(
                itemCount: discoveredDevices.length,
                itemBuilder: (context, index) {
                  final device = discoveredDevices[index];
                  final isTargetDevice = device["name"]!.contains("NemSens");
                  final isConnected = _authService.connectedDevice == device["name"];
                  
                  return Card(
                    color: const Color(0xFF1A1A1A),
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isConnected 
                            ? Colors.green.withOpacity(0.5) 
                            : (isTargetDevice ? const Color(0xFF00ADB5).withOpacity(0.5) : Colors.transparent),
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.bluetooth, 
                        color: isConnected 
                            ? Colors.green 
                            : (isTargetDevice ? const Color(0xFF00ADB5) : Colors.grey),
                      ),
                      title: Text(device["name"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Row(
                        children: [
                          Text(device["id"]!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.signal_cellular_alt, 
                            size: 14, 
                            color: isConnected 
                                ? Colors.green 
                                : (isTargetDevice ? const Color(0xFF00ADB5) : Colors.grey),
                          ),
                          const SizedBox(width: 2),
                          Text("${device["rssi"]} dBm", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isConnected 
                              ? Colors.redAccent.withOpacity(0.2) 
                              : (isTargetDevice ? const Color(0xFF00ADB5) : Colors.transparent),
                          side: BorderSide(
                            color: isConnected 
                                ? Colors.redAccent 
                                : (isTargetDevice ? Colors.transparent : Colors.grey),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () {
                          if (isConnected) {
                            // Bağlantıyı Kes
                            _authService.disconnectDevice();
                          } else {
                            // Cihaza Bağlan
                            _authService.connectDevice(device["name"]!);
                            Navigator.pop(context, device["name"]);
                          }
                        },
                        child: Text(
                          isConnected 
                              ? "Kes" 
                              : (isTargetDevice ? "Bağlan" : "Eşle"), 
                          style: TextStyle(
                            fontSize: 12, 
                            color: isConnected ? Colors.redAccent : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}