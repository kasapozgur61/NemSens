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

  // 2. Risk Analizi ve Eşik Değer Algoritması
  DehydrationRisk calculateRisk(double conductivity) {
    if (conductivity < 220) {
      return DehydrationRisk.normal;
    } else if (conductivity >= 220 && conductivity < 340) {
      return DehydrationRisk.risk;
    } else {
      return DehydrationRisk.critical;
    }
  }

  // UI için yardımcı metotlar (Renk ve Yazı yönetimi)
  String getRiskString(DehydrationRisk risk) {
    switch (risk) {
      case DehydrationRisk.normal:
        return "Normal";
      case DehydrationRisk.risk:
        return "Hafif Dehidratasyon (Risk)";
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