import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_sample_project/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('com.clearquote/sdk');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async {
      switch (call.method) {
        case 'isSDKInitialized':
          return false;
        case 'getDealerCode':
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
  });

  testWidgets('shows initialize screen when SDK is not initialized', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('ClearQuoteSDK'), findsOneWidget);
    expect(find.text('Flutter Demo App'), findsOneWidget);
    expect(find.text('Initialize SDK'), findsOneWidget);
  });
}
