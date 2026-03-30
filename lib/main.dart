import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/app_settings.dart';
import 'services/ad_service.dart';
import 'services/client_service.dart';
import 'services/notification_service.dart';
import 'views/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettingsProvider();
  await settings.load();
  await initializeDateFormatting('es', null);
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    debugPrint('[Firebase] Error al inicializar: $e\n$st');
  }
  await NotificationService.initialize();
  unawaited(NotificationService().scheduleDailySummary());
  unawaited(MobileAds.instance.initialize().then((_) {
    AdService().preloadInterstitial();
  }));
  unawaited(_checkBirthdays());
  runApp(
    ChangeNotifierProvider.value(
      value: settings,
      child: const BizPulseApp(),
    ),
  );
}

Future<void> _checkBirthdays() async {
  try {
    final clients = await ClientService().getAll();
    final now = DateTime.now();
    final names = clients
        .where((c) =>
            c.birthday != null &&
            c.birthday!.month == now.month &&
            c.birthday!.day == now.day)
        .map((c) => c.name)
        .toList();
    if (names.isNotEmpty) {
      await NotificationService().scheduleBirthdayNotifs(names);
    }
  } catch (_) {}
}

class BizPulseApp extends StatefulWidget {
  const BizPulseApp({super.key});

  @override
  State<BizPulseApp> createState() => _BizPulseAppState();
}

class _BizPulseAppState extends State<BizPulseApp>
    with WidgetsBindingObserver {
  final _navKey = GlobalKey<NavigatorState>();
  DateTime? _backgroundedAt;
  bool _pinShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = context.read<AppSettingsProvider>();
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed &&
        settings.pinEnabled &&
        settings.pinCode.isNotEmpty &&
        settings.autoLockMinutes > 0) {
      final bg = _backgroundedAt;
      if (bg != null &&
          DateTime.now().difference(bg).inMinutes >= settings.autoLockMinutes) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _showPinLock(settings.pinCode));
      }
    }
  }

  void _showPinLock(String expectedPin) {
    if (_pinShowing) return;
    _pinShowing = true;
    _navKey.currentState
        ?.push<void>(MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _PinLockScreen(expectedPin: expectedPin),
        ))
        .then((_) => _pinShowing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (_, settings, __) => MaterialApp(
        navigatorKey: _navKey,
        title: 'BizPulse',
        debugShowCheckedModeBanner: false,
        locale: Locale(settings.languageCode),
        supportedLocales: const [
          Locale('es'),
          Locale('en'),
          Locale('pt'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: settings.buildTheme(brightness: Brightness.light),
        darkTheme: settings.buildTheme(brightness: Brightness.dark),
        themeMode: settings.themeMode,
        builder: (ctx, child) {
          // 1. Escala de texto global
          Widget result = MediaQuery(
            data: MediaQuery.of(ctx).copyWith(
              textScaler: TextScaler.linear(settings.textScale),
            ),
            child: child!,
          );
          // 2. Degradado / imagen de fondo detrás de todos los Scaffold
          final deco = settings.backgroundDecoration();
          if (deco != null) {
            // 3. Overlay sobre imagen para mejorar legibilidad del texto
            if (settings.hasImageBackground) {
              result = ColoredBox(
                color: Colors.black.withValues(
                    alpha: settings.backgroundOverlayOpacity),
                child: result,
              );
            }
            result = DecoratedBox(decoration: deco, child: result);
          }
          return result;
        },
        home: const SplashScreen(),
      ),
    );
  }
}

// ── Pantalla de bloqueo por PIN ────────────────────────────────────────────────

class _PinLockScreen extends StatefulWidget {
  final String expectedPin;
  const _PinLockScreen({required this.expectedPin});

  @override
  State<_PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<_PinLockScreen> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _verify() {
    if (_ctrl.text == widget.expectedPin) {
      Navigator.of(context).pop();
    } else {
      setState(() => _error = 'PIN incorrecto');
      _ctrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 56, color: Colors.white54),
                const SizedBox(height: 24),
                const Text(
                  'Ingresá tu PIN',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _ctrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, letterSpacing: 12),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    errorText: _error,
                    counterText: '',
                  ),
                  onSubmitted: (_) => _verify(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _verify,
                    child: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
