import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hydro_track/services/auth_service.dart';
import 'package:hydro_track/services/ble_service.dart';
import 'package:hydro_track/services/data_processor.dart';
import 'package:hydro_track/widgets/app_drawer.dart';
import 'bluetooth_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _bleService  = BleService();
  final _processor   = DataProcessor();

  List<FlSpot> chartData       = [];
  double currentG              = 0.0;   // Ham iletkenlik (muS)
  double currentScl            = 0.0;   // Tonik bazal (muS)
  bool   lastScrFlag           = false;
  int    timeCounter           = 0;
  int    _saveCounter          = 0;
  bool   _isConnected          = false;

  DehydrationRisk _currentRisk = DehydrationRisk.normal;

  StreamSubscription<SensorData>? _dataSub;
  StreamSubscription<bool>?       _connSub;

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onAuthStateChanged);
    _isConnected = _bleService.isConnected;

    // BLE baglanti durumu degisince UI guncelle
    _connSub = _bleService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
          if (!connected) {
            chartData.clear();
            currentG   = 0.0;
            currentScl = 0.0;
          }
        });
      }
    });

    // Sensor verisini dinle
    _dataSub = _bleService.dataStream.listen(_onSensorData);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    _dataSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) setState(() {});
  }

  void _onSensorData(SensorData data) {
    if (!mounted) return;

    // Hareketli ortalama filtresi (g degerine uygula)
    final filtered = _processor.filterData(data.g);

    setState(() {
      timeCounter++;
      currentG   = filtered;
      currentScl = data.scl;

      // Risk hesapla (tonik SCL bazli)
      _currentRisk = _processor.calculateRisk(data.scl);

      // Grafik guncelle (son 60 noktayi tut — 8 Hz, ~7.5 sn)
      chartData.add(FlSpot(timeCounter.toDouble(), filtered));
      if (chartData.length > 60) chartData.removeAt(0);

      // SCR olayi bildirimi
      if (data.scrFlag && !lastScrFlag) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.bolt, color: Colors.amber),
                SizedBox(width: 8),
                Text('Stres/SCR olayi algilandi!'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF393E46),
          ),
        );
      }
      lastScrFlag = data.scrFlag;

      // Her 24 ornekte bir (~3 sn) seansa kaydet
      _saveCounter++;
      if (_saveCounter >= 24) {
        _saveCounter = 0;
        _authService.saveDataPoint(
          data.g,
          _processor.getRiskString(_currentRisk),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _isConnected || _authService.connectedDevice != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'NemSens - HydroTrack',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: isConnected ? Colors.green : Colors.redAccent,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final selectedDevice = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (context) => const BluetoothScreen()),
              );
              if (selectedDevice != null) {
                messenger.showSnackBar(
                  SnackBar(content: Text('$selectedDevice cihazina basariyla baglaniidi!')),
                );
              }
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeviceStatusCard(isConnected),
            const SizedBox(height: 20),
            if (isConnected)
              _buildLiveStatusIndicator()
            else
              _buildConnectionWarningCard(),
            const SizedBox(height: 20),
            Text(
              'Ter Iletkenlik Trendi (muS)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 10),
            _buildChartCard(isConnected),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceStatusCard(bool isConnected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isConnected ? const Color(0xFF00ADB5) : Colors.grey).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.developer_board,
              color: isConnected ? const Color(0xFF00ADB5) : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected
                      ? 'Bagli Cihaz: ${_bleService.connectedDeviceName ?? _authService.connectedDevice}'
                      : 'Bagli Cihaz: Yok',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isConnected
                      ? 'Sensor Durumu: Aktif Veri Akisi (8 Hz)'
                      : 'Sensor Durumu: Baglanti Kesildi',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatusIndicator() {
    final riskColor = _processor.getRiskColor(_currentRisk);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        children: [
          const Text(
            'ANLIK DURUM',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Ham iletkenlik (g)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                currentG.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              const Text('muS', style: TextStyle(fontSize: 18, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          // Tonik + Risk durumu
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Tonik: ${currentScl.toStringAsFixed(2)} muS',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: riskColor.withOpacity(0.4)),
                ),
                child: Text(
                  _processor.getRiskString(_currentRisk),
                  style: TextStyle(
                    fontSize: 12,
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionWarningCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          const Text(
            'CIHAZ BAGLANTISI GEREKLI',
            style: TextStyle(
              fontSize: 15,
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'NemSens biosensorunuz bagli degil. Canli dehidratasyon takibini baslatmak icin lutfen cihazinizi eslestirin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00ADB5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final selectedDevice = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (context) => const BluetoothScreen()),
              );
              if (selectedDevice != null) {
                messenger.showSnackBar(
                  SnackBar(content: Text('$selectedDevice cihazina basariyla baglaniidi!')),
                );
              }
            },
            icon: const Icon(Icons.bluetooth),
            label: const Text('Sensore Baglan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(bool isConnected) {
    final minY = 0.0;
    final maxY = 50.0;
    return Stack(
      children: [
        Container(
          height: 260,
          padding: const EdgeInsets.only(right: 20, left: 10, top: 24, bottom: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: chartData.isEmpty
              ? const Center(
                  child: Text(
                    'Veri bekleniyor...',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                    titlesData: const FlTitlesData(
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: chartData.first.x,
                    maxX: chartData.last.x,
                    minY: minY,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: chartData,
                        isCurved: true,
                        color: const Color(0xFF00ADB5),
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF00ADB5).withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        if (!isConnected)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_clock, color: Colors.white54, size: 36),
                    SizedBox(height: 8),
                    Text(
                      'Canli Veri Bekleniyor...',
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
