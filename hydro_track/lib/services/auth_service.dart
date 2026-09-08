import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  /// Firebase Auth ile giriş yapar, profil bilgilerini yerel JSON'dan yükler.
  Future<bool> login(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        _isLoggedIn = true;
        _email = email;
        // Profil bilgilerini yerel veritabanından yükle
        final profile = await DatabaseHelper().getUserByEmail(email);
        _username = profile?["username"] ?? email.split('@')[0];
        _age = profile?["age"] ?? 22;
        _weight = (profile?["weight"] as num?)?.toDouble() ?? 70.0;
        _dailyWaterTarget = (profile?["dailyWaterTarget"] as num?)?.toDouble() ?? 2.5;
        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Firebase Auth ile kayıt olur, profil bilgilerini yerel JSON'a kaydeder.
  /// Başarılıysa null, hata varsa Türkçe hata mesajı döndürür.
  Future<String?> register(String email, String password, String username) async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        // Profil bilgilerini yerel veritabanına kaydet
        await DatabaseHelper().registerUser(email, password, username);
      }
      return null; // başarılı
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          return 'Şifre çok zayıf. En az 6 karakter kullanın.';
        case 'email-already-in-use':
          return 'Bu e-posta adresiyle zaten bir kayıt mevcut!';
        case 'invalid-email':
          return 'Geçersiz e-posta adresi.';
        default:
          return 'Kayıt sırasında bir hata oluştu. Lütfen tekrar deneyin.';
      }
    } catch (_) {
      return 'Kayıt sırasında bir hata oluştu. Lütfen tekrar deneyin.';
    }
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

  /// Firebase Auth üzerinden şifre sıfırlama e-postası gönderir.
  /// Başarılıysa null, hata varsa hata mesajını döndürür.
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return null; // başarılı
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Bu e-posta adresiyle kayıtlı bir hesap bulunamadı.';
        case 'invalid-email':
          return 'Geçersiz e-posta adresi.';
        case 'too-many-requests':
          return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
        default:
          return 'Bir hata oluştu. Lütfen tekrar deneyin.';
      }
    } catch (e) {
      return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
}
