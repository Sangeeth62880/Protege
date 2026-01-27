import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:protege_app/main.dart' as app;
import 'package:uuid/uuid.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full Auth Flow: Signup -> Home -> Logout', (WidgetTester tester) async {
    // Start app
    app.main();
    await tester.pumpAndSettle();

    // 1. Handle potential starts
    // Case A: Onboarding
    if (find.text('Get Started').evaluate().isNotEmpty) {
      print('On Onboarding Screen. Tapping Get Started...');
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
    }
    
    // Case B: Already Logged In (Home)
    if (find.text('Continue Learning').evaluate().isNotEmpty || 
        find.textContaining('Good morning').evaluate().isNotEmpty) {
       print('Already logged in. Logging out...');
       // Tap Profile (4th tab typically)
       await tester.tap(find.byIcon(Icons.person)); 
       await tester.pumpAndSettle();
       
       // Tap Logout
       await tester.tap(find.text('Logout'));
       await tester.pumpAndSettle();
    }

    // Now should be on Login Screen
    expect(find.text('Login'), findsWidgets); // Title or Button
    print('On Login Screen');

    // 2. Navigate to Sign Up
    // Find the Sign Up text button. 
    // "Don't have an account?" is text, "Sign Up" is button.
    final signUpButton = find.widgetWithText(TextButton, 'Sign Up');
    if (signUpButton.evaluate().isNotEmpty) {
      await tester.tap(signUpButton);
    } else {
      // Fallback
      await tester.tap(find.text('Sign Up').last); 
    }
    await tester.pumpAndSettle();
    
    expect(find.textContaining('Create Account'), findsOneWidget);
    print('On Signup Screen');

    // 3. Fill Signup Form
    final email = 'test_${const Uuid().v4().substring(0, 8)}@protege.com';
    final password = 'TestPassword123!';
    final name = 'Test Auto User';
    
    print('Creating user: $email');
    
    // Name
    await tester.enterText(find.byType(TextFormField).at(0), name);
    await tester.pump(const Duration(milliseconds: 200));
    
    // Email
    await tester.enterText(find.byType(TextFormField).at(1), email);
    await tester.pump(const Duration(milliseconds: 200));
    
    // Password
    await tester.enterText(find.byType(TextFormField).at(2), password);
    await tester.pump(const Duration(milliseconds: 200));
    
    // Confirm Password
    await tester.enterText(find.byType(TextFormField).at(3), password);
    await tester.pump(const Duration(milliseconds: 200));
    
    // Hide keyboard
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // 4. Submit
    // Tap the primary button 'Sign Up'
    final submitButton = find.widgetWithText(ElevatedButton, 'Sign Up'); 
    // Note: PrimaryButton usually wraps ElevatedButton
    if (submitButton.evaluate().isNotEmpty) {
      await tester.tap(submitButton);
    } else {
        // Search by text if widget type is obscure
        await tester.tap(find.text('Sign Up').last);
    }
    
    // Wait for async auth
    await tester.pumpAndSettle(const Duration(seconds: 8));

    // 5. Verify Home Screen
    expect(find.text('Continue Learning'), findsOneWidget, reason: 'Should be on Home Screen');
    
    print('Signup Successful! Landed on Home Screen.');
    
    // Optional: Logout again to clean up? 
    // Let's leave it logged in to verify persistence if needed, or logout.
  });
}
