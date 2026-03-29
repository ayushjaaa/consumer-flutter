// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onetap365app/main.dart';

void main() {
  testWidgets('App builds and shows splash image', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OneTap365App());

    // Allow frames to settle
    await tester.pumpAndSettle();

    // Expect the splash image to be present
    expect(find.byType(Image), findsOneWidget);
  });
}