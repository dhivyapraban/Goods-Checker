import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Config
import 'config/app_theme.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/delivery_provider.dart';
import 'providers/shipment_provider.dart';
import 'providers/synergy_provider.dart';
import 'providers/backhaul_provider.dart';
import 'providers/payment_provider.dart';

// Screens
import 'screens/auth/phone_login_screen.dart';
import 'screens/driver/driver_home_screen.dart';
import 'screens/shipper/shipper_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Lock to portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const EcoLogiqApp());
}

class EcoLogiqApp extends StatelessWidget {
  const EcoLogiqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => DeliveryProvider()),
        ChangeNotifierProvider(create: (_) => ShipmentProvider()),
        ChangeNotifierProvider(create: (_) => SynergyProvider()),
        ChangeNotifierProvider(create: (_) => BackhaulProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: MaterialApp(
        title: 'EcoLogiq',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Auth wrapper that routes based on authentication status and role
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Show splash/loading while checking auth
        if (auth.status == AuthStatus.initial ||
            auth.status == AuthStatus.loading) {
          return const SplashScreen();
        }

        // Authenticated - route based on role
        if (auth.isAuthenticated) {
          if (auth.isDriver) {
            return const DriverHomeScreen();
          } else if (auth.isShipper) {
            return const ShipperHomeScreen();
          }
          // Default to driver if unknown role
          return const DriverHomeScreen();
        }

        // Not authenticated - show login
        return const PhoneLoginScreen();
      },
    );
  }
}

/// Splash screen shown during auth check
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_shipping,
                size: 56,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),

            // App name
            Text(
              'EcoLogiq',
              style: AppTheme.headingLarge.copyWith(color: AppTheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Smart Logistics Platform',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 48),

            // Loading indicator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
