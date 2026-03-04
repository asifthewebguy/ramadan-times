import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/prayer_log_model.dart';
import 'services/app_provider.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/timetable_screen.dart';
import 'screens/qibla_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dhikr_screen.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar styling (edge-to-edge: no deprecated color APIs)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialise Hive
  await Hive.initFlutter();
  Hive.registerAdapter(PrayerLogModelAdapter());
  await Hive.openBox<PrayerLogModel>(AppConstants.hiveBoxPrayerLog);

  // Initialise notification service
  await NotificationService.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: const RamadanTimesApp(),
    ),
  );
}

class RamadanTimesApp extends StatelessWidget {
  const RamadanTimesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ramadan Times',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const _AppRouter(),
    );
  }
}

/// Routes to OnboardingScreen on first launch, NavShell thereafter.
class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // Show loading until provider finishes initialising
    if (provider.status == AppStatus.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    if (!provider.onboardingDone) {
      return const OnboardingScreen();
    }

    return const _NavShell();
  }
}

class _NavShell extends StatefulWidget {
  const _NavShell();

  @override
  State<_NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<_NavShell> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    TimetableScreen(),
    QiblaScreen(),
    DhikrScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Timetable',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Qibla',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Dhikr',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
