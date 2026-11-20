import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hiddify/utils/platform_utils.dart';

/// The native splash, the Hiddify logo on the app's background, from the tap until the app shows its first
/// screen. Removed once: removing it twice fails an assertion.
///
/// Desktop has no native splash: the window is shown during bootstrap, long before the app's first screen,
/// and held frames would leave it blank (white). There Flutter draws the splash itself, from the start, and
/// keeps it over the app ([cover]) until [remove].
abstract final class NativeSplash {
  static bool _removed = false;
  static final _showing = ValueNotifier(true);

  static bool get _drawn => !kIsWeb && PlatformUtils.isDesktop;

  /// Holds Flutter's first frame, so the native splash stays; on desktop, draws the splash.
  static void preserve(WidgetsBinding binding) {
    if (kIsWeb) return;
    if (_drawn) {
      runApp(const _Splash());
      return;
    }
    FlutterNativeSplash.preserve(widgetsBinding: binding);
  }

  /// The app, under the splash while it is up (desktop).
  static Widget cover(Widget app) => !kIsWeb ? _SplashCover(child: app) : app;

  /// Lets Flutter's frames through: the splash goes.
  static void remove() {
    if (kIsWeb || _removed) return;
    _removed = true;

    // Release Android's held first frame first. The Flutter splash overlay
    // is already mounted above the app, so it takes over from the native
    // launch screen without flashing the intro/home route.
    if (!_drawn) FlutterNativeSplash.remove();

    // Keep the branded HLP2VPN splash visible after the hand-off.
    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      _showing.value = false;
    });
  }
}

class _Splash extends StatefulWidget {
  const _Splash();

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> with SingleTickerProviderStateMixin {
  late final AnimationController _loader = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Draw behind the status and navigation bars. SafeArea + BoxFit.contain
    // letterboxed the tall artwork on narrow/tall phones, leaving black bands.
    return ColoredBox(
      color: const Color(0xFF020817),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/source/hlp2vpn_splash.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              Positioned(
                bottom: constraints.maxHeight * .10,
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: AnimatedBuilder(
                    animation: _loader,
                    builder: (context, child) => Transform.rotate(
                      angle: _loader.value * 6.283185307179586,
                      child: child,
                    ),
                    child: const CircularProgressIndicator(
                      value: .72,
                      strokeWidth: 3,
                      strokeCap: StrokeCap.round,
                      color: Color(0xFF08D9FF),
                      backgroundColor: Color(0x332D8CFF),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SplashCover extends StatefulWidget {
  const _SplashCover({required this.child});

  final Widget child;

  @override
  State<_SplashCover> createState() => _SplashCoverState();
}

class _SplashCoverState extends State<_SplashCover> {
  /// Out of the tree once faded, so it costs nothing afterwards.
  bool _gone = !NativeSplash._showing.value;

  @override
  Widget build(BuildContext context) {
    if (_gone) return widget.child;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          ValueListenableBuilder(
            valueListenable: NativeSplash._showing,
            builder: (context, showing, splash) => IgnorePointer(
              ignoring: !showing,
              child: AnimatedOpacity(
                opacity: showing ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                onEnd: () => setState(() => _gone = true),
                child: splash,
              ),
            ),
            child: const _Splash(),
          ),
        ],
      ),
    );
  }
}
