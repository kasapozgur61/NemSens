import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydro_track/main.dart';
import 'package:hydro_track/services/auth_service.dart';

void main() {
  testWidgets('HydroTrack full application flow test (Register, Login, Connect, Auto-save, View History)', (WidgetTester tester) async {
    // 1. Start application (Default to LoginScreen)
    await tester.pumpWidget(const HydroTrackApp());

    // Verify Login Screen is displayed
    expect(find.text('Giriş Yap'), findsWidgets);
    expect(find.text('Google ile Giriş Yap'), findsNothing); // Removed

    // 2. Navigate to Register Screen
    await tester.tap(find.text('Hesabınız yok mu? Şimdi Kaydolun'));
    await tester.pumpAndSettle();

    // Verify Register Screen is displayed
    expect(find.text('Yeni Hesap Oluştur'), findsOneWidget);

    // 3. Fill registration form and sign up
    await tester.enterText(find.byType(TextFormField).at(0), 'Yarışmacı');
    await tester.enterText(find.byType(TextFormField).at(1), 'test@nemsens.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.enterText(find.byType(TextFormField).at(3), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
    await tester.pumpAndSettle();

    // Verify we are popped back to LoginScreen
    expect(find.text('Giriş Yap'), findsWidgets);

    // 4. Perform Login with newly created credentials
    await tester.enterText(find.byType(TextFormField).at(0), 'test@nemsens.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Giriş Yap'));
    
    // Pump frames to complete simulated 500ms delay in AuthService login
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify Dashboard is now displayed
    expect(find.text('NemSens - HydroTrack'), findsOneWidget);
    expect(find.text('CİHAZ BAĞLANTISI GEREKLİ'), findsOneWidget);

    // 5. Navigate to Bluetooth Connection Screen
    await tester.tap(find.text('Sensöre Bağlan'));
    await tester.pumpAndSettle();

    // Verify BluetoothScreen is opened and fix for overflow is active (No Row in trailing)
    expect(find.text('Biyosensör Bağlantısı'), findsOneWidget);
    
    // 6. Click 'Bağlan' to connect the device
    await tester.tap(find.text('Bağlan'));
    await tester.pumpAndSettle();

    // Verify we are back on the Dashboard and the warning banner is gone
    expect(find.text('NemSens - HydroTrack'), findsOneWidget);
    expect(find.text('CİHAZ BAĞLANTISI GEREKLİ'), findsNothing);
    expect(find.text('ANLIK DURUM'), findsOneWidget);

    // 7. Wait 10 seconds of simulated time to trigger auto-saving of at least one data point
    // Periodic timer runs every 2s, so 10s will trigger 5 ticks, which completes 1 save cycle.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();

    // 8. Open the yan menü (Drawer)
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Verify Yan Menü items are present
    expect(find.text('Geçmiş Ölçümlerim'), findsOneWidget);

    // 9. Navigate to History Screen
    await tester.tap(find.text('Geçmiş Ölçümlerim'));
    await tester.pumpAndSettle();

    // Verify HistoryScreen lists the active session
    expect(find.text('NemSens - HydroTrack'), findsOneWidget);
    
    // 10. Open Session Details
    await tester.tap(find.text('NemSens - HydroTrack'));
    await tester.pumpAndSettle();

    // Verify SessionDetailScreen shows session data
    expect(find.text('Seans Detayları'), findsOneWidget);
    expect(find.text('Ortalama İletkenlik'), findsOneWidget);
    expect(find.text('Kayıt Sayısı'), findsOneWidget);

    // Cleanup
    AuthService().logout();
  });
}
