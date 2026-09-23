import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:preflight_crew_auth/src/screens/signup_screen.dart";

void main() {
  testWidgets('Signup screen displays the student account form',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SignupScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Join PreFlight Crew'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('WeThinkCode Student Email'), findsOneWidget);
    expect(find.text('Password (min 6 characters)'), findsOneWidget);
  });
}
