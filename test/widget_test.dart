import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uangku/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('UangkuApp smoke test renders home and bento grid', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.runAsync(() async {
      await tester.pumpWidget(const UangkuApp());
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Verify key titles and elements exist
    expect(find.text('Uangku'), findsOneWidget);
    expect(find.text('JATAH HARIAN'), findsOneWidget);
    expect(find.text('Primer'), findsOneWidget);
    expect(find.text('Sekunder'), findsOneWidget);
    expect(find.text('Tersier'), findsOneWidget);
    expect(find.text('Tabungan'), findsOneWidget);
    expect(find.text('Catat Jajan'), findsOneWidget);
  });

  testWidgets('Buka Atur Budget modal dan verifikasi rincian item', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.runAsync(() async {
      await tester.pumpWidget(const UangkuApp());
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Tap Atur Budget
    await tester.tap(find.text('Atur Budget'));
    await tester.pumpAndSettle();

    // Modal title exists
    expect(find.text('Atur Anggaran Bulanan'), findsOneWidget);
    expect(find.text('TOTAL GAJI BULANAN'), findsOneWidget);
    expect(find.text('Simpan & Terapkan Anggaran'), findsOneWidget);
  });
}
