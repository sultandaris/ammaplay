import 'package:flutter_test/flutter_test.dart';// This is a basic Flutter widget test.// Thisimport 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ammaplay/main.dart';//import 'package:flutter_riverpod/flutter_riverpod.dart';



void main() {// To perform an interaction with a widget in your test, use the WidgetTester

  testWidgets('App starts correctly', (WidgetTester tester) async {

    await tester.pumpWidget(// utility in the flutter_test package. For example, you can send tap and scrollimport 'package:ammaplay/main.dart';

      const ProviderScope(

        child: MyApp(isLoggedIn: false),// gestures. You can also use WidgetTester to find child widgets in the widget

      ),

    );// tree, read text, and verify that the values of widget properties are correct.void main() {

    expect(find.byType(MyApp), findsOneWidget);

  });  testWidgets('App starts correctly', (WidgetTester tester) async {

}
import 'package:flutter_test/flutter_test.dart';    // Build our app and trigger a frame.

import 'package:flutter_riverpod/flutter_riverpod.dart';    await tester.pumpWidget(

      const ProviderScope(

import 'package:ammaplay/main.dart';        child: MyApp(isLoggedIn: false),

      ),

void main() {    );

  testWidgets('App starts correctly', (WidgetTester tester) async {

    // Build our app and trigger a frame.    // Verify that the app starts (you can customize this test based on your needs)

    await tester.pumpWidget(    expect(find.byType(MyApp), findsOneWidget);

      const ProviderScope(  });

        child: MyApp(isLoggedIn: false),} widget test.

      ),//

    );// To perform an interaction with a widget in your test, use the WidgetTester

// utility in the flutter_test package. For example, you can send tap and scroll

    // Verify that the app starts (you can customize this test based on your needs)// gestures. You can also use WidgetTester to find child widgets in the widget

    expect(find.byType(MyApp), findsOneWidget);// tree, read text, and verify that the values of widget properties are correct.

  });

}import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ammaplay/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(isLoggedIn: false),
      ),
    );

    // Verify that the app starts (you can customize this test based on your needs)
    expect(find.byType(MyApp), findsOneWidget);
  });
  });
}
