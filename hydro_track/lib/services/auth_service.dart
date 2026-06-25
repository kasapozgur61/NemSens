import 'package:flutter/material.dart';
import 'package:hydro_track/services/database_helper.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isLoggedIn = false;
  String? _username;
  String? _email;
  String? _connectedDevice;
  int _age = 22;
  double _weight = 70.0;
  double _dailyWaterTarget = 2.5;

  Map<String, dynamic>? _currentSession;

  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  String? get email => _email;
  String? get connectedDevice => _connectedDevice;
  int get age => _age;
  double get weight => _weight;
  double get dailyWaterTarget => _dailyWaterTarget;
  Map<String, dynamic>? get currentSession => _currentSession;

  Future<bool> login(String email, String password) async {
    // Simüle edilmiş ağ gecikmesi
    await Future.delayed(const Duration(milliseconds: 500));
    final user = await DatabaseHelper().loginUser(email, password);
    if (user != null) {
      _isLoggedIn = true;
      _email = user["email"];
      _username = user["username"];
      _age = user["age"] ?? 22;
      _weight = (user["weight"] as num?)?.toDouble() ?? 70.0;
      _dailyWaterTarget = (user["dailyWaterTarget"] as num?)?.toDouble() ?? 2.5;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    if (_connectedDevice != null && _currentSession != null) {
      disconnectDevice();
    }
    _isLoggedIn = false;
    _username = null;
    _email = null;
    _connectedDevice = null;
    _currentSession = null;
    notifyListeners();
  }

  void updateProfile({String? username, int? age, double? weight, double? dailyWaterTarget}) {
    if (username != null) _username = username;
    if (age != null) _age = age;
    if (weight != null) _weight = weight;
    if (dailyWaterTarget != null) _dailyWaterTarget = dailyWaterTarget;
    
    if (_email != null) {
      DatabaseHelper().updateProfile(
        _email!,
        username: username,
        age: age,
        weight: weight,
        dailyWaterTarget: dailyWaterTarget,
      );
    }
    notifyListeners();
  }

  void connectDevice(String deviceName) {
    _connectedDevice = deviceName;
    _currentSession = {
      "id": DateTime.now().toIso8601String(),
      "email": _email,
      "deviceName": deviceName,
      "startTime": DateTime.now().toIso8601String(),
      "endTime": null,
      "dataPoints": []
    };
    notifyListeners();
  }

  void disconnectDevice() {
    if (_connectedDevice != null && _currentSession != null && _email != null) {
      _currentSession!["endTime"] = DateTime.now().toIso8601String();
      DatabaseHelper().saveSession(_email!, _currentSession!);
    }
    _connectedDevice = null;
    _currentSession = null;
    notifyListeners();
  }

  void saveDataPoint(double conductivity, String risk) {
    if (_connectedDevice == null || _currentSession == null || _email == null) return;
    
    final points = _currentSession!["dataPoints"] as List;
    points.add({
      "timestamp": DateTime.now().toIso8601String(),
      "conductivity": conductivity,
      "risk": risk
    });
    
    DatabaseHelper().saveSession(_email!, _currentSession!);
  }
}
