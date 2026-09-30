import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/adapters/adapters.dart';
import 'providers/auth_provider.dart';
import 'providers/baby_provider.dart';
import 'providers/event_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/insights_screen.dart';

import 'screens/profile_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'utils/storage_service.dart';
import 'services/notification_service.dart';
import 'services/navigation_service.dart';
import 'services/purchase_service.dart';
import 'services/analytics_service.dart';
import 'services/meta_ads_service.dart';
import 'services/paywall_service.dart';
import 'services/paywall_trigger_service.dart';
import 'services/review_service.dart';
import 'services/version_service.dart';
import 'widgets/update_modal.dart';
import 'widgets/wake_up_modal.dart';

const bool kAlwaysShowOnboarding = false;

void _handleNotificationTap(String payload) {
  if (payload == NotificationService.payloadWakeCheck) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return;

    final notificationProvider = context.read<NotificationProvider>();
    final eventProvider = context.read<EventProvider>();
    final babyProvider = context.read<BabyProvider>();
    final baby = babyProvider.currentBaby;

    WakeUpModal.show(
      context,
      onYes: () {
        notificationProvider.onWakeCheckResponse(wokeUp: true);
        if (baby != null && eventProvider.activeSleepTimer != null) {
          eventProvider.stopSleepTimer(baby.id);
        }
      },
      onNo: () {
        notificationProvider.onWakeCheckResponse(wokeUp: false);
      },
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await MetaAdsService.instance.initialize();

  await Hive.initFlutter();
  Hive.registerAdapter(BabyAdapter());
  Hive.registerAdapter(BabyEventAdapter());
  Hive.registerAdapter(EventTypeAdapter());
  Hive.registerAdapter(FeedTypeAdapter());
  Hive.registerAdapter(FeedSideAdapter());
  Hive.registerAdapter(DiaperTextureAdapter());
  await StorageService.init();
  await initializeDateFormatting();
  await ReviewService.init();
  await PaywallTriggerService.init();

  await NotificationService.initialize(
    onTap: _handleNotificationTap,
  );
  try {
    final isProduction = !kDebugMode;
    final revenueCatKey = isProduction
        ? (Platform.isAndroid
            ? dotenv.env['REVENUECAT_ANDROID_API_KEY_PROD']
            : dotenv.env['REVENUECAT_IOS_API_KEY_PROD'])
        : (Platform.isAndroid
            ? dotenv.env['REVENUECAT_ANDROID_API_KEY_DEV']
            : dotenv.env['REVENUECAT_IOS_API_KEY_DEV']);

    if (revenueCatKey == null || revenueCatKey.isEmpty) {
      debugPrint(
          '[RevenueCat] ⚠️ No API key configured for ${Platform.operatingSystem} (${isProduction ? 'PRODUCTION' : 'SANDBOX'}) - purchases disabled');
    } else {
      debugPrint(
          '[RevenueCat] Using ${Platform.operatingSystem} ${isProduction ? "PRODUCTION" : "SANDBOX"} key');
      await PurchaseService.initialize(apiKey: revenueCatKey);
    }
  } catch (e) {
    debugPrint('RevenueCat init failed: $e');
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
          Purchases.addCustomerInfoUpdateListener((info) {
            provider.updateFromCustomerInfo(info);
          });
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
  VersionInfo? _pendingUpdate;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
    _connectProviders();
    _checkForUpdate();
  }

  void _connectProviders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final babyProvider = context.read<BabyProvider>();
      final eventProvider = context.read<EventProvider>();
      final notificationProvider = context.read<NotificationProvider>();
      final localeProvider = context.read<LocaleProvider>();

      babyProvider.initSyncService(authProvider.authService);
      eventProvider.initSyncService(authProvider.authService);
      eventProvider.setNotificationProvider(notificationProvider);
      notificationProvider.setLocaleProvider(localeProvider);

      if (authProvider.isLoggedIn) {
        _syncDataFromCloud(authProvider, babyProvider, eventProvider);
      }

      authProvider.authService.authStateChanges.listen((authState) {
        if (!mounted) return;
        if (authState.session != null) {
          _syncDataFromCloud(authProvider, babyProvider, eventProvider);
          _checkOnboarding();
        } else {
          babyProvider.clearBabies();
          eventProvider.clearEvents();
          _revenueCatLogOut();
          MetaAdsService.instance.setUserId(null);
        }
      });
    });
  }

  void _syncDataFromCloud(
      AuthProvider authProvider, BabyProvider babyProvider, EventProvider eventProvider) {
    final userId = authProvider.user?.id;
    if (userId != null) {
      _revenueCatLogIn(userId);
      MetaAdsService.instance.setUserId(userId);
    }
    babyProvider.loadBabiesFromCloud().then((_) {
      for (final baby in babyProvider.babies) {
        eventProvider.loadEventsFromCloud(baby.id);
      }
    });
  }

  void _revenueCatLogIn(String userId) async {
    try {
      await Purchases.logIn(userId);
      debugPrint('[RevenueCat] Logged in with userId: $userId');
    } catch (e) {
      debugPrint('[RevenueCat] logIn failed: $e');
    }
  }

  void _revenueCatLogOut() async {
    try {
      await Purchases.logOut();
      debugPrint('[RevenueCat] Logged out');
    } catch (e) {
      debugPrint('[RevenueCat] logOut failed: $e');
    }
  }

  void _checkOnboarding() {
    if (kAlwaysShowOnboarding) {
      if (mounted) setState(() => _showOnboarding = true);
      return;
    }
    final userId = context.read<AuthProvider>().user?.id;
    final complete = StorageService.isOnboardingCompleteFor(userId);
    if (mounted) setState(() => _showOnboarding = !complete);
  }

  Future<void> _checkForUpdate() async {
    final versionInfo = await VersionService.checkForUpdate();
    if (!versionInfo.hasUpdate || !mounted) return;

    _pendingUpdate = versionInfo;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final update = _pendingUpdate;
      if (update == null || !mounted) return;
      final navigator = NavigationService.navigatorKey.currentState;
      if (navigator == null) return;

      _pendingUpdate = null;

      navigator.push(PageRouteBuilder(
        opaque: false,
        barrierDismissible: !update.isForceUpdate,
        barrierColor: Colors.black54,
        pageBuilder: (_, __, ___) => UpdateModal(
          latestVersion: update.latestVersion,
          releaseNotes: update.releaseNotes,
          storeUrl: update.storeUrl,
          isForceUpdate: update.isForceUpdate,
          onDismiss: () => navigator.pop(),
        ),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final authProvider = context.watch<AuthProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      title: 'NestRoutine',
      locale: localeProvider.locale,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: authProvider.isLoggedIn ? _buildHome() : const LoginScreen(),
      routes: {
        '/home': (context) => const MainShell(),
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

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentTab = 0;
  AnalyticsService? _analyticsService;

  final _screenNames = const ['home', 'history', 'insights', 'profile'];

  static const int insightsTab = 2;

  BabyProvider? _babyProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NavigationService.tabIndex.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _analyticsService ??=
          AnalyticsService(context.read<AuthProvider>().authService);
      _analyticsService?.log(AnalyticsService.appOpen, AnalyticsService.engagement,
          properties: {'source': 'cold_start'});
      _maybeShowAutoPaywall(trigger: PaywallTriggerPoint.appColdStart);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _babyProvider?.removeListener(_onBabyChanged);
    _babyProvider = context.read<BabyProvider>();
    _babyProvider!.addListener(_onBabyChanged);
    _analyticsService ??= AnalyticsService(context.read<AuthProvider>().authService);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEventsForCurrentBaby());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NavigationService.tabIndex.removeListener(_onTabChanged);
    _babyProvider?.removeListener(_onBabyChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;
    _analyticsService?.log(AnalyticsService.appResumed, AnalyticsService.engagement,
        properties: {'source': 'resumed'});
    _maybeShowAutoPaywall(trigger: PaywallTriggerPoint.appResume);
  }

  /// Avalia o paywall automatico. O throttling impede que vire assedio:
  /// cooldown, limite por dia, carencia de instalacao e bloqueio quando ha
  /// timer de sono ativo. Veja [PaywallTriggerService] para as regras.
  Future<void> _maybeShowAutoPaywall({required String trigger}) async {
    final sleepTimerActive = context.read<EventProvider>().activeSleepTimer != null;

    // Da tempo da UI assentar e evita competir com modais de update/review.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    if (PaywallService.isPresenting) return;

    await PaywallService.present(
      context,
      trigger: trigger,
      automatic: true,
      sleepTimerActive: sleepTimerActive,
    );
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() => _currentTab = NavigationService.tabIndex.value);
      _analyticsService?.log(AnalyticsService.screenView, AnalyticsService.engagement, properties: {
        'screen': _screenNames[_currentTab],
      });
      if (_screenNames[_currentTab] == 'insights') {
        MetaAdsService.instance.logViewInsights();
      }
    }
  }

  void _onBabyChanged() {
    _loadEventsForCurrentBaby();
  }

  void _loadEventsForCurrentBaby() {
    final baby = context.read<BabyProvider>().currentBaby;
    if (baby != null) {
      context.read<EventProvider>().loadEvents(baby.id);
      if (context.read<AuthProvider>().isLoggedIn) {
        context.read<EventProvider>().loadEventsFromCloud(baby.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          const HomeScreen(),
          const HistoryScreen(),
          InsightsScreen(isActive: _currentTab == insightsTab),
          const ProfileScreen(),
        ],
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
                label: context.read<LocaleProvider>().strings.navHome,
                isSelected: currentTab == 0,
                badge: hasActiveTimer,
                onTap: () => onTabChanged(0),
              ),
              _NavBarItem(
                icon: Icons.history_outlined,
                activeIcon: Icons.history_rounded,
                label: context.read<LocaleProvider>().strings.navHistory,
                isSelected: currentTab == 1,
                onTap: () => onTabChanged(1),
              ),
              _NavBarItem(
                icon: Icons.insights_outlined,
                activeIcon: Icons.insights_rounded,
                label: context.read<LocaleProvider>().strings.navInsights,
                isSelected: currentTab == 2,
                onTap: () => onTabChanged(2),
              ),
              _NavBarItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person_rounded,
                label: context.read<LocaleProvider>().strings.navProfile,
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
