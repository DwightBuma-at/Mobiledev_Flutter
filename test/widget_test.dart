import 'package:barangay_management_flutter/main.dart';
import 'package:barangay_management_flutter/services/storage_service.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Barangay app opens the landing page', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.initialize();

    await tester.pumpWidget(
      DevicePreview(enabled: false, builder: (_) => const BarangayApp()),
    );

    expect(find.text('Barangay IMS'), findsOneWidget);
  });
}
