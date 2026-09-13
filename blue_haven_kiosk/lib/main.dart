import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/kiosk_config.dart';
import 'core/interfaces/presence_detector.dart';
import 'core/theme/kiosk_theme.dart';
import 'firebase_options.dart';
import 'presentation/attract/kiosk_attract_screen.dart';
import 'presentation/providers/kiosk_session_provider.dart';

final GlobalKey<NavigatorState> kioskNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  runApp(const ProviderScope(child: BlueHavenKioskApp()));
}

class BlueHavenKioskApp extends StatelessWidget {
  const BlueHavenKioskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: kioskNavigatorKey,
      title: 'Blue Haven Kiosk',
      debugShowCheckedModeBanner: false,
      theme: KioskTheme.themeData,
      builder: (context, child) {
        return KioskSessionWrapper(
          navigatorKey: kioskNavigatorKey,
          child: child!,
        );
      },
      home: const KioskAttractScreen(),
    );
  }
}

class KioskSessionWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const KioskSessionWrapper({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  ConsumerState<KioskSessionWrapper> createState() => _KioskSessionWrapperState();
}

class _KioskSessionWrapperState extends ConsumerState<KioskSessionWrapper> {
  final PresenceDetector _presenceDetector = TapToWakeDetector();
  Timer? _idleInactivityTimer;
  StreamSubscription<PresenceStatus>? _presenceSub;

  @override
  void initState() {
    super.initState();
    _presenceDetector.start();
    _presenceSub = _presenceDetector.presenceStream.listen((status) {
      if (status == PresenceStatus.presenceLost) {
        // 20s of lost presence -> Wipe session and return to Attract Loop
        debugPrint('20s lost presence detected. Wiping session.');
        _resetAndWipeSession();
      }
    });

    _resetIdleTimer();
  }

  void _resetIdleTimer() {
    _idleInactivityTimer?.cancel();
    _idleInactivityTimer = Timer(
      const Duration(seconds: KioskConfig.idleInactivityTimeoutSeconds), // 90s idle
      () {
        debugPrint('90s idle timeout reached. Wiping session.');
        _resetAndWipeSession();
      },
    );
  }

  void _onUserInteraction() {
    _presenceDetector.notifyInteraction();
    _resetIdleTimer();
    ref.read(kioskSessionNotifierProvider.notifier).updateActivity();
  }

  void _resetAndWipeSession() {
    _idleInactivityTimer?.cancel();
    // Wipe all session state
    ref.read(kioskSessionNotifierProvider.notifier).endSession();

    final navigator = widget.navigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _idleInactivityTimer?.cancel();
    _presenceSub?.cancel();
    _presenceDetector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onUserInteraction(),
      onPointerMove: (_) => _onUserInteraction(),
      child: widget.child,
    );
  }
}
