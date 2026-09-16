import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hydro_track/services/ble_service.dart';
import 'package:hydro_track/services/auth_service.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final _bleService  = BleService();
  final _authService = AuthService();

  bool isScanning   = false;
  bool isConnecting = false;
  String? connectingId;

  final List<ScanResult> _scanResults = [];
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _connSub;

  @override
  void initState() {
    super.initState();
    _connSub = _bleService.connectionStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      isScanning = true;
      _scanResults.clear();
    });

    _scanSub?.cancel();
    _scanSub = _bleService.startScan(timeout: 5).listen((results) {
      if (mounted) {
        setState(() {
          _scanResults.clear();
          _scanResults.addAll(results);
        });
      }
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => isScanning = false);
    });
  }

  Future<void> _connect(ScanResult result) async {
    setState(() {
      isConnecting = true;
      connectingId = result.device.remoteId.str;
    });

    await _bleService.stopScan();
    final error = await _bleService.connect(result.device);

    if (!mounted) return;
    setState(() {
      isConnecting  = false;
      connectingId  = null;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      _authService.connectDevice(result.device.platformName);
      Navigator.pop(context, result.device.platformName);
    }
  }

  Future<void> _disconnect() async {
    await _bleService.disconnect();
    _authService.disconnectDevice();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final connected = _bleService.isConnected;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Cihaz Tara ve Baglan'),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagli cihaz gostergesi
            if (connected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bluetooth_connected, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bagli: ${_bleService.connectedDeviceName ?? "NemSens-GSR"}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: _disconnect,
                      child: const Text('Kes', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),

            Text(
              'Biyosensr Baglantisi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            const Text(
              'NemSens-GSR cihazinizi bulmak icin taramayi baslatın.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

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
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search),
                label: Text(isScanning ? 'Cihazlar Aranıyor...' : 'Taramayi Baslat'),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Bulunan Cihazlar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: _scanResults.isEmpty
                  ? Center(
                      child: Text(
                        isScanning
                            ? 'Taranıyor...'
                            : 'Henuz cihaz bulunamadi.\nTaramayi baslatın.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _scanResults.length,
                      itemBuilder: (context, index) {
                        final result      = _scanResults[index];
                        final name        = result.device.platformName.isNotEmpty
                            ? result.device.platformName
                            : 'Bilinmeyen Cihaz';
                        final isTarget    = name.contains('NemSens');
                        final isConn      = _bleService.connectedDeviceName == name;
                        final thisConnecting = connectingId == result.device.remoteId.str;

                        return Card(
                          color: Theme.of(context).cardColor,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isConn
                                  ? Colors.green.withOpacity(0.5)
                                  : (isTarget
                                      ? const Color(0xFF00ADB5).withOpacity(0.5)
                                      : Theme.of(context).dividerColor),
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.bluetooth,
                              color: isConn
                                  ? Colors.green
                                  : (isTarget ? const Color(0xFF00ADB5) : Colors.grey),
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  result.device.remoteId.str,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.signal_cellular_alt,
                                    size: 13,
                                    color: isConn ? Colors.green : Colors.grey),
                                Text(
                                  ' ${result.rssi} dBm',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: isConn
                                ? ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent.withOpacity(0.15),
                                      side: const BorderSide(color: Colors.redAccent),
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                    onPressed: _disconnect,
                                    child: const Text('Kes',
                                        style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                  )
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isTarget
                                          ? const Color(0xFF00ADB5)
                                          : Colors.transparent,
                                      side: BorderSide(
                                          color: isTarget ? Colors.transparent : Colors.grey),
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                    onPressed: (isConnecting || isConn)
                                        ? null
                                        : () => _connect(result),
                                    child: thisConnecting
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2, color: Colors.white))
                                        : Text(
                                            isTarget ? 'Baglan' : 'Esle',
                                            style: const TextStyle(
                                                color: Colors.white, fontSize: 12),
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
