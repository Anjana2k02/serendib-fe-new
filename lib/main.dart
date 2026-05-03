import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/artifact_provider.dart';
import 'providers/dev_options_provider.dart';
import 'services/storage_service.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/features/navigation_screen.dart';
import 'screens/features/translator_screen.dart';
import 'screens/features/qr_scanner_screen.dart';
import 'screens/features/ar_vr_screen.dart';
import 'screens/features/feedback_screen.dart';
import 'screens/features/contact_screen.dart';
import 'screens/features/ai_assistant_screen.dart';
import 'screens/features/indoor_map_screen.dart';
import 'screens/artifacts/artifacts_list_screen.dart';
import 'screens/artifacts/artifact_detail_screen.dart';
import 'screens/artifacts/artifact_form_screen.dart';
import 'models/artifact.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage
  await StorageService().init();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const SerendibApp());
}

class SerendibApp extends StatelessWidget {
  const SerendibApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ArtifactProvider()),
        ChangeNotifierProvider(create: (_) => DevOptionsProvider()),
      ],
      child: MaterialApp(
        title: 'Serendib',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        onGenerateRoute: _generateRoute,
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const _SplashScreen(),
        );
      case '/welcome':
        return MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        );
      case '/onboarding':
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        );
      case '/login':
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
      case '/register':
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
        );
      case '/home':
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
      case '/navigation':
        return MaterialPageRoute(
          builder: (_) => const NavigationScreen(),
        );
      case '/translator':
        return MaterialPageRoute(
          builder: (_) => const TranslatorScreen(),
        );
      case '/qr-scanner':
        return MaterialPageRoute(
          builder: (_) => const QRScannerScreen(),
        );
      case '/ar-vr':
        return MaterialPageRoute(
          builder: (_) => const ARVRScreen(),
        );
      case '/ai-assistant':
        return MaterialPageRoute(
          builder: (_) => const AIAssistantScreen(),
        );
      case '/feedback':
        return MaterialPageRoute(
          builder: (_) => const FeedbackScreen(),
        );
      case '/contact':
        return MaterialPageRoute(
          builder: (_) => const ContactScreen(),
        );
      case '/artifacts':
        return MaterialPageRoute(
          builder: (_) => const ArtifactsListScreen(),
        );
      case '/artifacts/create':
        final artifact = settings.arguments as Artifact?;
        return MaterialPageRoute(
          builder: (_) => ArtifactFormScreen(artifact: artifact),
        );
      case '/artifacts/detail':
        final artifact = settings.arguments as Artifact?;
        return MaterialPageRoute(
          builder: (_) => ArtifactDetailScreen(artifact: artifact),
        );
      case '/indoor-map':
        return MaterialPageRoute(
          builder: (_) => const IndoorMapScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
    }
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final storage = StorageService();

    // Check authentication status first
    final isAuthenticated = await storage.isAuthenticated();

    if (isAuthenticated) {
      // User is already logged in, go directly to home
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // User is not logged in, show welcome screen
      Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.explore,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              'Serendib',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover the beauty of Sri Lanka',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
