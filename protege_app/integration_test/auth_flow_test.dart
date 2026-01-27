import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:protege_app/app.dart';
import 'package:protege_app/data/services/storage_service.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:protege_app/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Auth Flow Integration Test (Auto Detect Mode)', (WidgetTester tester) async {
    // 1. Initialize Firebase (Required for Real Auth on Android)
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Test Firebase init check: $e');
    }

    // 2. Initialize Storage
    final storageService = StorageService();
    await storageService.init();

    // 2. Pump App (No overrides - testing real app logic)
    await tester.pumpWidget(
      const ProviderScope(
        child: ProtegeApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 3. Handle Start State
    bool onHome = find.text('Continue Learning').evaluate().isNotEmpty;
    bool onOnboarding = find.text('Get Started').evaluate().isNotEmpty;

    if (onHome) {
      print('DEBUG: Started on Home. Logging out.');
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
    } else if (onOnboarding) {
       print('DEBUG: Started on Onboarding.');
       await tester.tap(find.text('Get Started'));
       await tester.pumpAndSettle();
    }

    // Now on Login
    expect(find.text('Login'), findsWidgets);

    // 4. Go to Signup
    print('DEBUG: Navigating to Signup');
    final signUpButton = find.widgetWithText(TextButton, 'Sign Up');
    if (signUpButton.evaluate().isNotEmpty) {
        await tester.tap(signUpButton);
    } else {
        await tester.tap(find.text('Sign Up').last);
    }
    await tester.pumpAndSettle();

    expect(find.textContaining('Create Account'), findsOneWidget);

    // 5. Fill Form
    final email = 'demo_${const Uuid().v4().substring(0, 8)}@protege.com';
    final password = 'TestPassword123!';
    
    print('DEBUG: Filling form for $email');
    await tester.enterText(find.byType(TextFormField).at(0), 'Demo User');
    await tester.enterText(find.byType(TextFormField).at(1), email);
    await tester.enterText(find.byType(TextFormField).at(2), password);
    await tester.enterText(find.byType(TextFormField).at(3), password);
    await tester.pumpAndSettle();

    // 6. Submit
    print('DEBUG: Submitting Signup');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    
    // Wait for Mock Auth (it has 1s delay)
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // 7. Verify
    if (find.text('Continue Learning').evaluate().isNotEmpty) {
        print('SUCCESS: Auth Flow Verified (Real App Logic)!');
    } else {
         if (find.textContaining('error').evaluate().isNotEmpty) {
            print('FAILURE: Error shown in UI');
        } else {
            print('FAILURE: Did not reach Home Screen');
        }
        expect(find.text('Continue Learning'), findsOneWidget);
    }
  });
}
