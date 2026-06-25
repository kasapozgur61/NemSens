import 'package:flutter/material.dart';
import 'package:hydro_track/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _waterController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _authService.username ?? '');
    _ageController = TextEditingController(text: _authService.age.toString());
    _weightController = TextEditingController(text: _authService.weight.toString());
    _waterController = TextEditingController(text: _authService.dailyWaterTarget.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      _authService.updateProfile(
        username: _nameController.text.trim(),
        age: int.tryParse(_ageController.text),
        weight: double.tryParse(_weightController.text),
        dailyWaterTarget: double.tryParse(_waterController.text),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil başarıyla güncellendi!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Profilim'),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar and general info card
              Card(
                color: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.white10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFF00ADB5).withOpacity(0.1),
                        child: const Icon(Icons.person, size: 48, color: Color(0xFF00ADB5)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _authService.username ?? 'Yarışmacı Kullanıcı',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _authService.email ?? 'e-posta belirtilmedi',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text(
                "Kişisel Bilgiler & Hedefler",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70),
              ),
              const SizedBox(height: 16),

              // Username input
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'İsim / Kullanıcı Adı',
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF00ADB5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'İsim alanı boş bırakılamaz';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Age input
              TextFormField(
                controller: _ageController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Yaş',
                  prefixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF00ADB5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Yaş alanı boş bırakılamaz';
                  if (int.tryParse(value) == null) return 'Geçerli bir yaş giriniz';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Weight input
              TextFormField(
                controller: _weightController,
                style: const TextStyle(color: Colors.white),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Kilo (kg)',
                  prefixIcon: const Icon(Icons.monitor_weight_outlined, color: Color(0xFF00ADB5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Kilo alanı boş bırakılamaz';
                  if (double.tryParse(value) == null) return 'Geçerli bir kilo giriniz';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Daily water intake target
              TextFormField(
                controller: _waterController,
                style: const TextStyle(color: Colors.white),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Günlük Su Hedefi (Litre)',
                  prefixIcon: const Icon(Icons.local_drink_outlined, color: Color(0xFF00ADB5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Su hedefi alanı boş bırakılamaz';
                  if (double.tryParse(value) == null) return 'Geçerli bir su hedefi giriniz';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00ADB5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveProfile,
                  child: const Text(
                    "Değişiklikleri Kaydet",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
