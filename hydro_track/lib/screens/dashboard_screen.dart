import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hydro_track/services/auth_service.dart';
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
  List<FlSpot> chartData = [];
  double currentConductivity = 2500.0; // Filtrelenmiş iletkenlik değeri
  int timeCounter = 0;
  Timer? _timer;
  int _saveCounter = 0;

  // Veri işlemci servisi ve enum durum yönetimi
  final DataProcessor _processor = DataProcessor();
  DehydrationRisk _currentRisk = DehydrationRisk.normal;

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onAuthStateChanged);

    // İlk grafiği doldurmak için başlangıç verileri
    for (int i = 0; i < 10; i++) {
      chartData.add(FlSpot(i.toDouble(), 2400.0 + Random().nextDouble() * 200));
    }
    timeCounter = 9;
    
    // ESP32'den veri geliyormuş gibi her 2 saniyede bir çalışan simülatör
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _simulateSensorData();
    });
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    _timer?.cancel();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // Veri İşleme ve Filtreleme Algoritması
  void _simulateSensorData() {
    // Sadece cihaz bağlıysa verileri güncelle ve simüle et
    if (_authService.connectedDevice == null) {
      return;
    }

    setState(() {
      timeCounter++;
      // Donanımdan gelen gürültülü ham veri simülasyonu
      double rawInflow = currentConductivity + (Random().nextDouble() * 400) - 150;
      
      // Sizin yazdığınız hareketli ortalama filtresinden geçiyor
      currentConductivity = _processor.filterData(rawInflow);
      
      // Sınır kontrolleri
      if (currentConductivity < 500) currentConductivity = 500;
      if (currentConductivity > 9500) currentConductivity = 9500;

      // Risk hesaplaması merkezi işleyiciye devredildi
      _currentRisk = _processor.calculateRisk(currentConductivity);

      // Grafik verisini güncelle (Son 15 veriyi tut)
      chartData.add(FlSpot(timeCounter.toDouble(), currentConductivity));
      if (chartData.length > 15) {
        chartData.removeAt(0);
      }

      // Her 10 saniyede bir (5 * 2s) veriyi seansa kaydet
      _saveCounter++;
      if (_saveCounter >= 5) {
        _saveCounter = 0;
        _authService.saveDataPoint(currentConductivity, _processor.getRiskString(_currentRisk));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _authService.connectedDevice != null;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'NemSens - HydroTrack',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled, 
              color: isConnected ? Colors.green : Colors.redAccent,
            ),
            onPressed: () async {
              // Bluetooth ekranına geçiş
              final messenger = ScaffoldMessenger.of(context);
              final selectedDevice = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (context) => const BluetoothScreen()),
              );
              
              if (selectedDevice != null) {
                messenger.showSnackBar(
                  SnackBar(content: Text('$selectedDevice cihazına başarıyla bağlanıldı!')),
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
            // Cihaz Bilgi Kartı
            _buildDeviceStatusCard(isConnected),
            const SizedBox(height: 20),
            
            // Canlı Risk Durumu Göstergesi veya Bağlantı Uyarısı
            if (isConnected)
              _buildLiveStatusIndicator()
            else
              _buildConnectionWarningCard(),
              
            const SizedBox(height: 20),
            
            // Dinamik Grafik Başlığı
            const Text(
              "Ter İletkenlik Trendi (μS/cm)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            
            // Grafik Kartı
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
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
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
                      ? "Bağlı Cihaz: ${_authService.connectedDevice}" 
                      : "Bağlı Cihaz: Yok",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  isConnected 
                      ? "Sensör Durumu: Aktif Veri Akışı (THS 4)" 
                      : "Sensör Durumu: Bağlantı Kesildi",
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _processor.getRiskColor(_currentRisk).withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          const Text(
            "ANLIK DURUM",
            style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                currentConductivity.toStringAsFixed(1),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 6),
              const Text(
                "μS/cm",
                style: TextStyle(fontSize: 18, color: Colors.grey),
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
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          const Text(
            "CİHAZ BAĞLANTISI GEREKLİ",
            style: TextStyle(fontSize: 15, color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          const Text(
            "NemSens biosensörünüz bağlı değil. Canlı dehidratasyon takibini başlatmak için lütfen cihazınızı eşleştirin.",
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
                  SnackBar(content: Text('$selectedDevice cihazına başarıyla bağlanıldı!')),
                );
              }
            },
            icon: const Icon(Icons.bluetooth),
            label: const Text("Sensöre Bağlan", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(bool isConnected) {
    return Stack(
      children: [
        Container(
          height: 260,
          padding: const EdgeInsets.only(right: 20, left: 10, top: 24, bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: const FlTitlesData(
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: chartData.isEmpty ? 0 : chartData.first.x,
              maxX: chartData.isEmpty ? 0 : chartData.last.x,
              minY: 500,
              maxY: 10000,
              lineBarsData: [
                LineChartBarData(
                  spots: chartData,
                  isCurved: true,
                  color: isConnected ? const Color(0xFF00ADB5) : Colors.grey,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: isConnected 
                        ? const Color(0xFF00ADB5).withOpacity(0.1) 
                        : Colors.grey.withOpacity(0.05),
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
                      "Canlı Veri Bekleniyor...",
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
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
