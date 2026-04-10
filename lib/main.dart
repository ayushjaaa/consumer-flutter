import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onetap365app/features/home/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/signin_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/navigation_provider.dart';
import 'firebase_options.dart';

import 'providers/ads_provider.dart';
import 'data/services/api_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Handle background message
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: Could not load .env file - using defaults');
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const OneTap365App());
}

class OneTap365App extends StatefulWidget {
  const OneTap365App({super.key});

  @override
  State<OneTap365App> createState() => _OneTap365AppState();
}

class _OneTap365AppState extends State<OneTap365App> {
  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {
    try {
      // Listen for foreground messages (optional, not required for OTP)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print(
            '📨 Received a foreground message: ${message.notification?.title}');
      });
      print('✅ FCM listener initialized');
    } catch (e) {
      print('⚠️ FCM initialization note: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => AdsProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/signin': (context) => const SignInScreen(),
          '/main': (context) => const HomeScreen(),
        },
      ),
    );
  }
}
