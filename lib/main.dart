import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'models/adapters/adapters.dart';
import 'providers/baby_provider.dart';
import 'providers/event_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'utils/storage_service.dart';
import 'services/notification_service.dart';
import 'services/navigation_service.dart';
import 'services/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(BabyAdapter());
  Hive.registerAdapter(BabyEventAdapter());
  Hive.registerAdapter(EventTypeAdapter());
  Hive.registerAdapter(FeedTypeAdapter());
  Hive.registerAdapter(FeedSideAdapter());
  Hive.registerAdapter(DiaperTextureAdapter());
  await StorageService.init();

  await NotificationService.initialize();

  try {
    await PurchaseService.initialize('test_BpoJpIniStKnxSClbfrdieuFbYI');
  } catch (e) {
    debugPrint('RevenueCat init skipped: $e');
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const NestRoutineApp());
}

class NestRoutineApp extends StatelessWidget {
  const NestRoutineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) {
          final provider = BabyProvider();
          provider.loadBabies();
          return provider;
        }),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) {
          final provider = LocaleProvider();
          provider.loadLocale();
          return provider;
        }),
        ChangeNotifierProvider(create: (_) {
          final provider = NotificationProvider();
          provider.loadSettings();
          return provider;
        }),
        ChangeNotifierProvider(create: (_) {
          final provider = SubscriptionProvider();
          provider.initialize();
          return provider;
        }),
      ],
      child: const _AppNavigator(),
    );
  }
}

class _AppNavigator extends StatefulWidget {
  const _AppNavigator();

  @override
  State<_AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<_AppNavigator> {
  bool? _showOnboarding;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
    _connectProviders();
  }

  void _connectProviders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventProvider = context.read<EventProvider>();
      final notificationProvider = context.read<NotificationProvider>();
      final localeProvider = context.read<LocaleProvider>();
      eventProvider.setNotificationProvider(notificationProvider);
      notificationProvider.setLocaleProvider(localeProvider);

      Purchases.addCustomerInfoUpdateListener((info) {
        if (mounted) {
          context.read<SubscriptionProvider>().updateCustomerInfo(info);
        }
      });
    });
  }

  void _checkOnboarding() {
    final complete = StorageService.isOnboardingComplete;
    if (mounted) setState(() => _showOnboarding = !complete);
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NestRoutine',
      locale: localeProvider.locale,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: _buildHome(),
      routes: {
        '/home': (context) => const MainShell(),
        '/paywall': (context) => const PaywallScreen(),
      },
    );
  }

  Widget _buildHome() {
    if (_showOnboarding == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.sleepPurple,
          ),
        ),
      );
    }
    if (_showOnboarding!) {
      return const OnboardingScreen();
    }
    return const MainShell();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentTab = 0;

  final _screens = const [
    HomeScreen(),
    HistoryScreen(),
    InsightsScreen(),
    ProfileScreen(),
  ];

  BabyProvider? _babyProvider;

  @override
  void initState() {
    super.initState();
    NavigationService.tabIndex.addListener(_onTabChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _babyProvider?.removeListener(_onBabyChanged);
    _babyProvider = context.read<BabyProvider>();
    _babyProvider!.addListener(_onBabyChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEventsForCurrentBaby());
  }

  @override
  void dispose() {
    NavigationService.tabIndex.removeListener(_onTabChanged);
    _babyProvider?.removeListener(_onBabyChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() => _currentTab = NavigationService.tabIndex.value);
  }

  void _onBabyChanged() {
    _loadEventsForCurrentBaby();
  }

  void _loadEventsForCurrentBaby() {
    final baby = context.read<BabyProvider>().currentBaby;
    if (baby != null) {
      context.read<EventProvider>().loadEvents(baby.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: _screens,
      ),
      bottomNavigationBar: _NavBar(
        currentTab: _currentTab,
        onTabChanged: (index) => setState(() => _currentTab = index),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTabChanged;

  const _NavBar({
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final hasActiveTimer = eventProvider.activeSleepTimer != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark.withValues(alpha: 0.98),
        border: Border(
          top: BorderSide(
            color: AppColors.cardBorder.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isSelected: currentTab == 0,
                badge: hasActiveTimer,
                onTap: () => onTabChanged(0),
              ),
              _NavBarItem(
                icon: Icons.history_outlined,
                activeIcon: Icons.history_rounded,
                label: 'History',
                isSelected: currentTab == 1,
                onTap: () => onTabChanged(1),
              ),
              _NavBarItem(
                icon: Icons.insights_outlined,
                activeIcon: Icons.insights_rounded,
                label: 'Insights',
                isSelected: currentTab == 2,
                onTap: () => onTabChanged(2),
              ),
              _NavBarItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isSelected: currentTab == 3,
                onTap: () => onTabChanged(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final bool badge;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    this.badge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppColors.sleepPurple
        : AppColors.textTertiary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (badge)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.sleepPurple,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
