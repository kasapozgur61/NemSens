import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  File? _dbFile;
  Map<String, dynamic> _inMemoryDb = {
    "users": [],
    "history": []
  };
  bool _isInMemory = false;

  Future<void> init() async {
    if (_dbFile != null || _isInMemory) return;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _isInMemory = true;
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      _dbFile = File('${dir.path}/nemsens_db.json');
      if (await _dbFile!.exists()) {
        final content = await _dbFile!.readAsString();
        _inMemoryDb = jsonDecode(content);
      } else {
        await _saveToFile();
      }
    } catch (e) {
      // Test veya platform desteği yoksa in-memory çalışmaya devam et
      _isInMemory = true;
      debugPrint("Dosya veritabanı açılamadı, in-memory moda geçiliyor: $e");
    }
  }

  Future<void> _saveToFile() async {
    if (_isInMemory || _dbFile == null) return;
    try {
      await _dbFile!.writeAsString(jsonEncode(_inMemoryDb));
    } catch (e) {
      debugPrint("Veritabanı kaydedilemedi: $e");
    }
  }

  // Kullanıcı Kayıt
  Future<bool> registerUser(String email, String password, String username) async {
    await init();
    final users = _inMemoryDb["users"] as List;
    
    // E-posta eşleşme kontrolü
    if (users.any((u) => u["email"] == email)) {
      return false;
    }

    users.add({
      "email": email,
      "password": password,
      "username": username,
      "age": 22,
      "weight": 70.0,
      "dailyWaterTarget": 2.5
    });

    await _saveToFile();
    return true;
  }

  // Kullanıcı Giriş
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    await init();
    final users = _inMemoryDb["users"] as List;
    for (var u in users) {
      if (u["email"] == email && u["password"] == password) {
        return Map<String, dynamic>.from(u);
      }
    }
    return null;
  }

  // Profil Güncelleme
  Future<void> updateProfile(String email, {String? username, int? age, double? weight, double? dailyWaterTarget}) async {
    await init();
    final users = _inMemoryDb["users"] as List;
    for (var u in users) {
      if (u["email"] == email) {
        if (username != null) u["username"] = username;
        if (age != null) u["age"] = age;
        if (weight != null) u["weight"] = weight;
        if (dailyWaterTarget != null) u["dailyWaterTarget"] = dailyWaterTarget;
        break;
      }
    }
    await _saveToFile();
  }

  // Seansları Listeleme
  Future<List<Map<String, dynamic>>> getSessions(String email) async {
    await init();
    final history = _inMemoryDb["history"] as List;
    return history
        .where((s) => s["email"] == email)
        .map((s) => Map<String, dynamic>.from(s))
        .toList();
  }

  // Seans Kaydetme (Yeni ve güncellemeler için)
  Future<void> saveSession(String email, Map<String, dynamic> sessionData) async {
    await init();
    final history = _inMemoryDb["history"] as List;
    
    final index = history.indexWhere((s) => s["id"] == sessionData["id"] && s["email"] == email);
    if (index != -1) {
      history[index] = sessionData;
    } else {
      history.add(sessionData);
    }
    
    await _saveToFile();
  }
}
