import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Firebase Auth ile giriş yapar, profil bilgilerini Firestore'dan yükler.
  Future<bool> login(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        _isLoggedIn = true;
        _email = email;
        // Profil bilgilerini Firestore'dan yükle
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(email)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          _username = data['username'] ?? email.split('@')[0];
          _age = (data['age'] as num?)?.toInt() ?? 22;
          _weight = (data['weight'] as num?)?.toDouble() ?? 70.0;
          _dailyWaterTarget = (data['dailyWaterTarget'] as num?)?.toDouble() ?? 2.5;
        } else {
          // Firestore'da yoksa yerel DB'ye bak
          final profile = await DatabaseHelper().getUserByEmail(email);
          _username = profile?['username'] ?? email.split('@')[0];
          _age = (profile?['age'] as num?)?.toInt() ?? 22;
          _weight = (profile?['weight'] as num?)?.toDouble() ?? 70.0;
          _dailyWaterTarget = (profile?['dailyWaterTarget'] as num?)?.toDouble() ?? 2.5;
        }
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

  /// Firebase Auth ile kayıt olur, profil bilgilerini Firestore'a ve yerel DB'ye kaydeder.
  /// Başarılıysa null, hata varsa Türkçe hata mesajı döndürür.
  Future<String?> register(String email, String password, String username) async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        // Profil bilgilerini Firestore'a ve yerel DB'ye kaydet
        // Bu kısım başarısız olsa bile kayıt başarılı sayılır
        try {
          await FirebaseFirestore.instance.collection('users').doc(email).set({
            'username': username,
            'age': 22,
            'weight': 70.0,
            'dailyWaterTarget': 2.5,
          });
        } catch (_) {
          // Firestore kaydı başarısız olsa da Firebase hesabı oluşturuldu
        }
        try {
          await DatabaseHelper().registerUser(email, password, username);
        } catch (_) {
          // Yerel DB kaydı başarısız olsa da devam et
        }
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
          return 'Kayıt sırasında bir hata oluştu: ${e.message}';
      }
    } catch (e) {
      return 'Beklenmeyen bir hata oluştu: $e';
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

  /// Profil bilgilerini Firestore'a kaydeder (kalıcı).
  Future<void> updateProfile({String? username, int? age, double? weight, double? dailyWaterTarget}) async {
    if (username != null) _username = username;
    if (age != null) _age = age;
    if (weight != null) _weight = weight;
    if (dailyWaterTarget != null) _dailyWaterTarget = dailyWaterTarget;

    if (_email != null) {
      final updateData = <String, dynamic>{};
      if (username != null) updateData['username'] = username;
      if (age != null) updateData['age'] = age;
      if (weight != null) updateData['weight'] = weight;
      if (dailyWaterTarget != null) updateData['dailyWaterTarget'] = dailyWaterTarget;

      // Firestore'a kaydet
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_email!)
          .update(updateData);

      // Yerel DB'yi de güncelle
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
