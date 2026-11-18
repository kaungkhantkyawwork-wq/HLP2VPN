import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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
    _showing.value = false;
    if (_drawn) return;
    FlutterNativeSplash.remove();
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF020B1C),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Image(
            image: AssetImage('assets/images/source/hlp2vpn_splash.png'),
            fit: BoxFit.contain,
            width: 340,
          ),
        ),
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
