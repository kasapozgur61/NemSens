import 'package:flutter/material.dart';

class SessionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> session;

  const SessionDetailScreen({super.key, required this.session});

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final months = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"];
      return "${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString;
    }
  }

  String _formatTimeOnly(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString;
    }
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'normal':
        return Colors.green;
      case 'risk':
      case 'dehidratasyon (risk)':
      case 'hafif dehidratasyon (risk)':
        return Colors.orange;
      case 'critical':
      case 'kritik':
      case 'kritik dehidratasyon (tehlike)':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getRiskText(String risk) {
    switch (risk.toLowerCase()) {
      case 'normal':
        return "Normal";
      case 'risk':
      case 'dehidratasyon (risk)':
      case 'hafif dehidratasyon (risk)':
        return "Dehidratasyon";
      case 'critical':
      case 'kritik':
      case 'kritik dehidratasyon (tehlike)':
        return "Kritik Dehidratasyon";
      default:
        return risk;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dataPoints = session["dataPoints"] as List? ?? [];
    final deviceName = session["deviceName"] ?? "Bilinmeyen Cihaz";
    final startTime = session["startTime"] ?? "";

    // İletkenlik ortalamasını hesapla
    double avgConductivity = 0.0;
    if (dataPoints.isNotEmpty) {
      double sum = 0.0;
      for (var p in dataPoints) {
        sum += (p["conductivity"] as num).toDouble();
      }
      avgConductivity = sum / dataPoints.length;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Seans Detayları'),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Session Header Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.developer_board, color: Color(0xFF00ADB5)),
                    const SizedBox(width: 8),
                    Text(
                      deviceName,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Tarih/Saat: ${_formatDateTime(startTime)}",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Statistics
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Ortalama İletkenlik", style: TextStyle(color: Colors.grey, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(
                              "${avgConductivity.toStringAsFixed(1)} μS/cm",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Kayıt Sayısı", style: TextStyle(color: Colors.grey, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(
                              "${dataPoints.length} Ölçüm",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00ADB5)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Data Points List Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text("ZAMAN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                Expanded(
                  flex: 3,
                  child: Text("İLETKENLİK", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
              ],
            ),
          ),

          // Data Points ListView
          Expanded(
            child: dataPoints.isEmpty
                ? const Center(child: Text("Seansa ait veri noktası bulunamadı.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: dataPoints.length,
                    itemBuilder: (context, index) {
                      final point = dataPoints[index];
                      final timestamp = point["timestamp"] ?? "";
                      final conductivity = (point["conductivity"] as num).toDouble();

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                _formatTimeOnly(timestamp),
                                style: TextStyle(color: cs.onSurface.withOpacity(0.7), fontSize: 13),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                "${conductivity.toStringAsFixed(1)} μS/cm",
                                style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
