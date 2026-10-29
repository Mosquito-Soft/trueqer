import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueqer/login_screen.dart';
import 'package:trueqer/core/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel googleSignInChannel =
      MethodChannel('plugins.flutter.io/google_sign_in');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(googleSignInChannel, (MethodCall call) async {
      if (call.method == 'init') {
        return null;
      }
      if (call.method == 'signIn') {
        // Simulates an arbitrary user signing in with their Google account
        return <String, dynamic>{
          'displayName': 'Arbitrary Google User',
          'email': 'arbitrary.user@gmail.com',
          'id': '109283746501928374',
          'photoUrl': 'https://lh3.googleusercontent.com/a/avatar',
          'serverAuthCode': null,
        };
      }
      if (call.method == 'getTokens') {
        return <String, dynamic>{
          // An arbitrary Google OAuth2 ID token returned by Google
          'idToken': 'invalid_oauth2_google_id_token_xyz',
          'accessToken': 'arbitrary_access_token',
        };
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(googleSignInChannel, null);
  });

  testWidgets(
      'successfully signs in with an arbitrary Google account using Continue with Google button',
      (WidgetTester tester) async {
    // 1. Render LoginScreen
    await tester.pumpWidget(
      MaterialApp(
        home: const LoginScreen(),
        routes: {
          '/profile': (context) => const Scaffold(
                body: Text('Profile Screen - Logged In Successfully'),
              ),
        },
      ),
    );
    await tester.pump();

    // 2. Locate the "Continue with Google" button
    final googleButton = find.text('Continue with Google');
    expect(googleButton, findsOneWidget);

    // 3. Tap the "Continue with Google" button to initiate OAuth2 sign in
    await tester.tap(googleButton);
    await tester.pumpAndSettle();

    // 4. Verification:
    // A successful login MUST navigate the user to '/profile' and populate currentUser.
    // However, due to the OAuth2 authentication error, the user is NOT redirected,
    // and remains stuck on the login screen with an error.
    expect(find.text('Profile Screen - Logged In Successfully'), findsOneWidget);
    expect(AuthService().currentUser, isNotNull);
  });
}
