import 'package:dont_forget_sleep/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Onboarding page shows primary auth actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));

    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Login with Google'), findsOneWidget);
  });
}
