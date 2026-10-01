import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Basic widget test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('SchoolPulse')),
        ),
      ),
    );

    expect(find.text('SchoolPulse'), findsOneWidget);
  });
}