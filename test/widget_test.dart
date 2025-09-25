import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ammaplay/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(child: MyApp(isLoggedIn: false)),
    );

    // Verify that the app starts without crashing
    expect(find.byType(MyApp), findsOneWidget);
  });
}
