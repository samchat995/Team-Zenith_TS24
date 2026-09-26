import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'localization/app_localizations.dart';
import 'screens/splash/splash_screen.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NeuralNexusApp());
}

class NeuralNexusApp extends StatefulWidget {
  const NeuralNexusApp({super.key});

  @override
  State<NeuralNexusApp> createState() => _NeuralNexusAppState();
}

class _NeuralNexusAppState extends State<NeuralNexusApp> {
  @override
  void initState() {
    super.initState();
    AuthService.instance.initLanguage();
    AuthService.instance.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = AuthService.instance.language;

    return MaterialApp(
      title: 'Neural Nexus',
      debugShowCheckedModeBanner: false,
      locale: Locale(currentLang),
      supportedLocales: const [
        Locale('en', ''),
        Locale('hi', ''),
        Locale('as', ''),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFF10B981),
          surface: const Color(0xFFF0FDF4),
        ),
        scaffoldBackgroundColor: const Color(0xFFF0FDF4),
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth <= 600;
            if (isMobile) {
              return child ?? const SizedBox.shrink();
            }

            // Desktop & Tablet: Center as realistic Android phone layout (max 430px)
            return Scaffold(
              backgroundColor: const Color(0xFF0F172A),
              body: Center(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 430,
                    minWidth: 360,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 36,
                        spreadRadius: 4,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      size: Size(
                        constraints.maxWidth > 430 ? 430 : constraints.maxWidth,
                        constraints.maxHeight,
                      ),
                    ),
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
        );
      },
      home: const SplashScreen(),
    );
  }
}
