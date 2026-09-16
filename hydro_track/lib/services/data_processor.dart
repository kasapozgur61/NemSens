import 'package:flutter/material.dart';

enum DehydrationRisk { normal, risk, critical }

class DataProcessor {
  // Hareketli ortalama için son 5 veriyi hafızada tutacağız
  final List<double> _window = [];
  final int windowSize = 5;

  // 1. Filtreleme Algoritması: Gürültüleri temizler
  double filterData(double rawValue) {
    _window.add(rawValue);
    if (_window.length > windowSize) {
      _window.removeAt(0);
    }
    // Penceredeki değerlerin ortalamasını al
    double sum = _window.reduce((a, b) => a + b);
    return sum / _window.length;
  }

  // 2. Risk Analizi — Tonik SCL (μS) bazlı GSR eşikleri
  // scl < 0.5 → sensör bağlı değil / kritik kuru
  // 0.5–1.0  → çok düşük (muhtemelen çok düşük temas)
  // 1.0–8.0  → Normal hidrasyon
  // 8.0–20.0 → Hafif dehidrasyon / stres
  // > 20.0   → Ciddi dehidrasyon
  DehydrationRisk calculateRisk(double conductivity) {
    if (conductivity < 0.5 || conductivity > 20.0) {
      return DehydrationRisk.critical;
    } else if (conductivity >= 8.0) {
      return DehydrationRisk.risk;
    } else {
      return DehydrationRisk.normal;
    }
  }

  // UI için yardımcı metotlar (Renk ve Yazı yönetimi)
  String getRiskString(DehydrationRisk risk) {
    switch (risk) {
      case DehydrationRisk.normal:
        return "Normal";
      case DehydrationRisk.risk:
        return "Dehidratasyon (Risk)";
      case DehydrationRisk.critical:
        return "Kritik Dehidratasyon (Tehlike)";
    }
  }

  Color getRiskColor(DehydrationRisk risk) {
    switch (risk) {
      case DehydrationRisk.normal:
        return Colors.green;
      case DehydrationRisk.risk:
        return Colors.orange;
      case DehydrationRisk.critical:
        return Colors.red;
    }
  }
}