import 'dart:async';

import 'package:dartx/dartx.dart';
import 'package:hiddify/utils/number_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/home/widget/local_proxy_hint.dart';
import 'package:hiddify/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_page.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/stats/notifier/stats_notifier.dart';
import 'package:hiddify/features/proxy/widget/upload_speed.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/profiles_update_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  static const _navy = Color(0xFF020817);
  static const _panel = Color(0xFF061B38);
  static const _cyan = Color(0xFF08D9FF);
  static const _blue = Color(0xFF167BFF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeProfile = ref.watch(activeProfileProvider);
    final darkTheme = theme.copyWith(
      brightness: Brightness.dark,
      // ProfileTile and other upstream widgets inherit this text palette. The home
      // surface is navy; keeping the light-theme text colours made server names
      // nearly invisible on the selected-server card.
      textTheme: theme.textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      primaryTextTheme: theme.primaryTextTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      scaffoldBackgroundColor: _navy,
      cardTheme: theme.cardTheme.copyWith(
        color: const Color(0xFF061A34),
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0xAA008CFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFF168DFF), width: 1.2),
        ),
      ),
      colorScheme: theme.colorScheme.copyWith(
        brightness: Brightness.dark,
        surface: _panel,
        surfaceContainerLowest: const Color(0xFF020B1C),
        surfaceContainerLow: const Color(0xFF061A34),
        surfaceContainer: const Color(0xFF082344),
        surfaceContainerHigh: const Color(0xFF0A2B50),
        surfaceContainerHighest: const Color(0xFF0D315B),
        onSurface: Colors.white,
        onSurfaceVariant: const Color(0xFFB8CBE0),
        primary: _cyan,
        secondary: _blue,
        outline: const Color(0xFF167BFF),
      ),
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: _navy,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );

    return Theme(
      data: darkTheme,
      child: Scaffold(
        backgroundColor: _navy,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 290,
                height: 72,
                child: Image.asset(
                  'assets/images/source/hlp2vpn_header_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
          actions: [
            Semantics(
              key: const ValueKey("profile_add_button"),
              label: 'Add server',
              child: IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: _cyan),
                onPressed: () => ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile(),
              ),
            ),
            const Gap(6),
          ],
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: _PremiumHomeBackdrop()),
            SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width: double.infinity,
                    height: constraints.maxHeight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: constraints.maxWidth.clamp(0.0, 620.0).toDouble(),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _CyberServerSelector(
                                onTap: () => ref.read(bottomSheetsNotifierProvider.notifier).showProfilesOverview(),
                                onRefresh: activeProfile.valueOrNull != null && activeProfile.valueOrNull!.name != 'HLP2VPN Servers'
                                    ? () => ref.read(foregroundProfilesUpdateNotifierProvider.notifier).trigger()
                                    : null,
                              ),
                              // Give the subscription selector and the main power dial
                              // more breathing room so they read as two premium sections.
                              const Gap(22),
                              const Center(child: ConnectionButton()),
                              const Gap(16),
                              const _LiveNetworkPanel(),
                              const Gap(10),
                              const _DataServerPanel(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _HlpBottomNavigation(
          onServers: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ProxiesOverviewPage())),
          onSettings: () => context.goNamed('settings'),
        ),
      ),
    );
  }
}

class _CyberServerSelector extends StatelessWidget {
  const _CyberServerSelector({required this.onTap, this.onRefresh});

  final VoidCallback onTap;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      width: double.infinity,
      child: CustomPaint(
        painter: const _CyberSelectorPainter(),
        child: ClipPath(
          clipper: const _CyberSelectorClipper(),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
              child: Row(
                children: [
                  // Decorative server icon only: intentionally has no tap handler.
                  const SizedBox(
                    width: 66,
                    child: Center(
                      child: Icon(Icons.public_rounded, color: Color(0xFF20E7FF), size: 43),
                    ),
                  ),
                  Container(width: 1.2, height: 48, color: const Color(0x6653DFFF)),
                  const Gap(16),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(8),
                        splashColor: const Color(0x3323DFFF),
                        highlightColor: const Color(0x1A23DFFF),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'HLP2VPN Servers',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (onRefresh != null)
                    IconButton(
                      tooltip: 'Refresh subscription',
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF8BEFFF), size: 20),
                    ),
                  const SizedBox(width: 4),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      customBorder: const CircleBorder(),
                      splashColor: const Color(0x3323DFFF),
                      child: ClipPath(
                        clipper: const _HexDropdownClipper(),
                        child: Container(
                          width: 58,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF10527B), Color(0xFF06213F)],
                            ),
                            border: Border.all(color: const Color(0xFF19DFFF), width: 1.4),
                            boxShadow: const [BoxShadow(color: Color(0xAA00CFFF), blurRadius: 13)],
                          ),
                          child: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFBDF8FF), size: 32),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CyberSelectorClipper extends CustomClipper<Path> {
  const _CyberSelectorClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * .075, h * .06)
      ..lineTo(w * .235, h * .06)
      ..lineTo(w * .275, h * .15)
      ..lineTo(w * .725, h * .15)
      ..lineTo(w * .765, h * .06)
      ..lineTo(w * .925, h * .06)
      ..lineTo(w * .985, h * .34)
      ..lineTo(w * .985, h * .66)
      ..lineTo(w * .925, h * .94)
      ..lineTo(w * .765, h * .94)
      ..lineTo(w * .725, h * .85)
      ..lineTo(w * .275, h * .85)
      ..lineTo(w * .235, h * .94)
      ..lineTo(w * .075, h * .94)
      ..lineTo(w * .015, h * .66)
      ..lineTo(w * .015, h * .34)
      ..close();
  }

  @override
  bool shouldReclip(covariant _CyberSelectorClipper oldClipper) => false;
}

class _HexDropdownClipper extends CustomClipper<Path> {
  const _HexDropdownClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * .25, 0)
    ..lineTo(size.width * .75, 0)
    ..lineTo(size.width, size.height * .5)
    ..lineTo(size.width * .75, size.height)
    ..lineTo(size.width * .25, size.height)
    ..lineTo(0, size.height * .5)
    ..close();

  @override
  bool shouldReclip(covariant _HexDropdownClipper oldClipper) => false;
}

class _CyberSelectorPainter extends CustomPainter {
  const _CyberSelectorPainter();

  Path _path(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * .075, h * .06)
      ..lineTo(w * .235, h * .06)
      ..lineTo(w * .275, h * .15)
      ..lineTo(w * .725, h * .15)
      ..lineTo(w * .765, h * .06)
      ..lineTo(w * .925, h * .06)
      ..lineTo(w * .985, h * .34)
      ..lineTo(w * .985, h * .66)
      ..lineTo(w * .925, h * .94)
      ..lineTo(w * .765, h * .94)
      ..lineTo(w * .725, h * .85)
      ..lineTo(w * .275, h * .85)
      ..lineTo(w * .235, h * .94)
      ..lineTo(w * .075, h * .94)
      ..lineTo(w * .015, h * .66)
      ..lineTo(w * .015, h * .34)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path(size);
    final rect = Offset.zero & size;
    canvas.drawPath(path, Paint()
      ..color = const Color(0xAA00BFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13));
    canvas.drawPath(path, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B4774), Color(0xFF03162F), Color(0xFF082B4D)],
      ).createShader(rect));
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF21DFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1);
    final accent = Paint()
      ..color = const Color(0xFF20E8FF)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * .43, 2), Offset(size.width * .57, 2), accent);
    canvas.drawLine(Offset(size.width * .43, size.height - 2), Offset(size.width * .57, size.height - 2), accent);
  }

  @override
  bool shouldRepaint(covariant _CyberSelectorPainter oldDelegate) => false;
}

class _PremiumHomeBackdrop extends StatelessWidget {
  const _PremiumHomeBackdrop();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0, -.08),
        radius: 1.18,
        colors: [Color(0xFF071D3A), Color(0xFF030E20), Color(0xFF010611)],
        stops: [0, .52, 1],
      ),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _NeonRibbonPainter()),
        // A soft blue atmosphere behind the connection control, without
        // the old bright cyan wash or horizontal oval outlines.
        _BackdropGlow(),
      ],
    ),
  );
}

class _BackdropGlow extends StatelessWidget {
  const _BackdropGlow();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Align(
      alignment: const Alignment(0, -.02),
      child: Container(
        width: 360,
        height: 520,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0x44216DCE), Color(0x18205AA8), Colors.transparent],
            stops: [0, .48, 1],
          ),
        ),
      ),
    ),
  );
}

class _NeonRibbonPainter extends CustomPainter {
  const _NeonRibbonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final top = Path()
      ..moveTo(-size.width * .12, size.height * .34)
      ..cubicTo(size.width * .18, size.height * .18, size.width * .43, size.height * .20,
          size.width * .62, size.height * .02)
      ..cubicTo(size.width * .78, -size.height * .08, size.width * .92, size.height * .05,
          size.width * 1.12, -size.height * .04);

    final topFine = Path()
      ..moveTo(-size.width * .10, size.height * .39)
      ..cubicTo(size.width * .18, size.height * .24, size.width * .44, size.height * .25,
          size.width * .65, size.height * .04)
      ..cubicTo(size.width * .82, -.02 * size.height, size.width * .96, size.height * .08,
          size.width * 1.10, -.01 * size.height);

    final bottom = Path()
      ..moveTo(-size.width * .12, size.height * 1.04)
      ..cubicTo(size.width * .16, size.height * .88, size.width * .42, size.height * .96,
          size.width * .63, size.height * .82)
      ..cubicTo(size.width * .82, size.height * .69, size.width * .96, size.height * .76,
          size.width * 1.12, size.height * .63);

    final bottomFine = Path()
      ..moveTo(-size.width * .08, size.height * 1.08)
      ..cubicTo(size.width * .20, size.height * .92, size.width * .45, size.height * .99,
          size.width * .66, size.height * .85)
      ..cubicTo(size.width * .84, size.height * .73, size.width * .98, size.height * .80,
          size.width * 1.10, size.height * .68);

    void glow(Path path, double width, Color color, double blur) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      canvas.drawPath(path, paint);
    }

    void ribbon(Path path, double width) {
      glow(path, width * 3.8, const Color(0xAA007BFF), 18);
      glow(path, width * 1.7, const Color(0xCC00BFFF), 7);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0x0016AFFF), Color(0xFF00CFFF), Color(0xFF168BFF), Color(0x001A5CFF)],
          stops: [0, .32, .72, 1],
        ).createShader(Offset.zero & size);
      canvas.drawPath(path, paint);
      glow(path, 1.1, const Color(0xCC8AEFFF), 1.2);
    }

    ribbon(top, 2.1);
    ribbon(topFine, 1.0);
    ribbon(bottom, 2.0);
    ribbon(bottomFine, 1.0);

    // Fine blue glints add depth while keeping the central content readable.
    final speck = Paint()..color = const Color(0x667BCBFF);
    for (var i = 0; i < 34; i++) {
      final x = (i * 73.0 % size.width);
      final y = (i * 131.0 % size.height);
      if (y > size.height * .34 && y < size.height * .72) continue;
      canvas.drawCircle(Offset(x, y), i % 5 == 0 ? 1.25 : .65, speck);
    }
  }

  @override
  bool shouldRepaint(covariant _NeonRibbonPainter oldDelegate) => false;
}

class _NeonCard extends StatelessWidget {
  const _NeonCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B3970), Color(0xFF04152E)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFF16BFFF), width: 1.5),
      boxShadow: const [
        BoxShadow(color: Color(0x77108FFF), blurRadius: 26, spreadRadius: 1),
        BoxShadow(color: Color(0x4410DFFF), blurRadius: 12),
      ],
    ),
    child: ClipRRect(borderRadius: BorderRadius.circular(23), child: child),
  );
}

class _HlpBottomNavigation extends StatelessWidget {
  const _HlpBottomNavigation({required this.onServers, required this.onSettings});
  final VoidCallback onServers;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0B3970), Color(0xFF03152D)]),
          borderRadius: BorderRadius.circular(38),
          border: Border.all(color: const Color(0xFF19C8FF), width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x88108FFF), blurRadius: 24), BoxShadow(color: Color(0x3310EFFF), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Expanded(child: _NavItem(icon: Icons.home_rounded, label: 'Home', selected: true, onTap: () {})),
            Expanded(child: _NavItem(icon: Icons.dns_rounded, label: 'Servers', onTap: onServers)),
            Expanded(child: _NavItem(icon: Icons.settings_rounded, label: 'Settings', onTap: onSettings)),
          ],
        ),
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.onTap, this.selected = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(4),
    child: Material(
      color: selected ? const Color(0xFF087FC7) : Colors.transparent,
      borderRadius: BorderRadius.circular(34),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(34),
        child: Container(
          decoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: const Color(0xFF38E9FF), width: 1.7),
                  boxShadow: const [BoxShadow(color: Color(0xCC08BFFF), blurRadius: 22), BoxShadow(color: Color(0x448B4DFF), blurRadius: 12)],
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 25, color: selected ? const Color(0xFF08E5FF) : Colors.white),
              const Gap(3),
              Text(label, style: TextStyle(
                color: selected ? const Color(0xFF08E5FF) : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              )),
            ],
          ),
        ),
      ),
    ),
  );
}

class AppVersionLabel extends HookConsumerWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    final version = ref.watch(appInfoProvider).requireValue.presentVersion;
    if (version.isBlank) return const SizedBox();

    return Semantics(
      label: t.common.version,
      button: false,
      child: Container(
        decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Text(
          version,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSecondaryContainer),
        ),
      ),
    );
  }
}


/// Displays low traffic in Kbps so ordinary browsing does not round down to 0.00 Mbps.
({String value, String unit}) formatTrafficRate(int bytesPerSecond) {
  if (bytesPerSecond <= 0) return (value: '0.0', unit: 'Kbps');
  final kilobits = bytesPerSecond * 8 / 1000;
  if (kilobits < 1000) return (value: kilobits.toStringAsFixed(1), unit: 'Kbps');
  return (value: (kilobits / 1000).toStringAsFixed(2), unit: 'Mbps');
}

/// Live tunnel traffic from the core; never shows sample or hard-coded speeds.
class _LiveNetworkPanel extends HookConsumerWidget {
  const _LiveNetworkPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = ref.watch(statsNotifierProvider).valueOrNull;
    final connected = ref.watch(
      connectionNotifierProvider.select((s) => s.valueOrNull is Connected),
    );
    final proxy = ref.watch(activeProxyNotifierProvider).valueOrNull;
    // The core's trafficAvailable flag can be false on some Android builds even
    // while cumulative byte counters are being updated. Trust real counters first;
    // the polling layer derives current Mbps from the change in those totals.
    final hasTrafficCounters = stats != null &&
        (stats.trafficAvailable ||
            stats.downlinkTotal.toInt() > 0 ||
            stats.uplinkTotal.toInt() > 0);
    final trafficAvailable = connected && hasTrafficCounters;
    final down = trafficAvailable ? stats!.downlink.toInt() : 0;
    final up = trafficAvailable ? stats!.uplink.toInt() : 0;
    final downSpeed = formatTrafficRate(down);
    final upSpeed = formatTrafficRate(up);
    final ping = connected && (proxy?.urlTestDelay ?? 0) > 0 ? proxy!.urlTestDelay.toString() : '--';
    final border = theme.brightness == Brightness.dark
        ? const Color(0xFF168DFF)
        : const Color(0xFF62B8F5);
    final surface = theme.brightness == Brightness.dark
        ? const Color(0xFF071B36)
        : theme.colorScheme.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              surface,
              Color.lerp(surface, const Color(0xFF087BCE), theme.brightness == Brightness.dark ? .22 : .06)!,
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border.withValues(alpha: .72), width: 1.1),
          boxShadow: [
            BoxShadow(
            color: border.withValues(alpha: theme.brightness == Brightness.dark ? .42 : .14),
            blurRadius: 26,
            spreadRadius: 1,
          ),
          if (theme.brightness == Brightness.dark)
            const BoxShadow(color: Color(0x3310CFFF), blurRadius: 10, spreadRadius: -2),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: _NetworkMetric(
                icon: Icons.south_rounded,
                color: const Color(0xFF18E8FF),
                label: 'Download',
                value: trafficAvailable ? downSpeed.value : '--',
                unit: trafficAvailable ? downSpeed.unit : '',
              ),
            ),
            Container(width: 1, height: 48, color: border.withValues(alpha: .35)),
            Expanded(
              child: _NetworkMetric(
                icon: Icons.north_rounded,
                color: const Color(0xFFFF4DFF),
                label: 'Upload',
                value: trafficAvailable ? upSpeed.value : '--',
                unit: trafficAvailable ? upSpeed.unit : '',
              ),
            ),
            Container(width: 1, height: 48, color: border.withValues(alpha: .35)),
            Expanded(
              child: _NetworkMetric(
                icon: Icons.bolt_rounded,
                color: const Color(0xFFFFC21A),
                label: 'Ping',
                value: ping,
                unit: ping == '--' ? '' : 'ms',
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Live transfer total and the selected/connected server name.
class _DataServerPanel extends HookConsumerWidget {
  const _DataServerPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsNotifierProvider).valueOrNull;
    final status = ref.watch(connectionNotifierProvider).valueOrNull;
    // Resolve selector groups (for example "lowest") to the actual outbound.
    final activeServer = ref.watch(activeProxyCardProvider)?.server;
    final connected = status is Connected;
    final connecting = status is Connecting || status is Waiting || status is HotReloading;
    // Data Used is the sum of both directions, not download-only.
    final totalBytes = (stats?.downlinkTotal.toInt() ?? 0) +
        (stats?.uplinkTotal.toInt() ?? 0);
    final total = totalBytes.size();

    final serverName = activeServer?.name ?? '--';
    final serverLabel = connected
        ? 'Connected Server'
        : connecting
            ? 'Connecting to'
            : 'Selected Server';

    // Start the session clock only after the tunnel reaches Connected.
    // It stays fixed while disconnected and starts over on the next session.
    final connectedAt = useRef<DateTime?>(null);
    final elapsedTick = useState(0);
    useEffect(() {
      if (connected) {
        connectedAt.value ??= DateTime.now();
        final timer = Timer.periodic(const Duration(seconds: 1), (_) => elapsedTick.value++);
        return timer.cancel;
      }
      connectedAt.value = null;
      return null;
    }, [connected]);
    final elapsed = connected && connectedAt.value != null
        ? DateTime.now().difference(connectedAt.value!)
        : Duration.zero;
    final timeText = _formatConnectionTime(elapsed);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF08264B), Color(0xFF04152D)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF18BFFF), width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x44108FFF), blurRadius: 22)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _InfoMetric(
                    icon: Icons.bar_chart_rounded,
                    color: const Color(0xFF19D9FF),
                    label: 'Data Used',
                    value: total,
                  ),
                ),
                Container(width: 1, height: 48, color: const Color(0x73168DFF)),
                Expanded(
                  child: _InfoMetric(
                    icon: Icons.dns_rounded,
                    color: const Color(0xFF19D9FF),
                    label: serverLabel,
                    value: serverName,
                    leading: activeServer == null || activeServer.ipinfo.countryCode.isEmpty
                        ? null
                        : IPCountryFlag(
                            countryCode: activeServer.ipinfo.countryCode,
                            organization: activeServer.ipinfo.org,
                            size: 28,
                            radius: 6,
                          ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 9),
              child: Divider(height: 1, color: Color(0x55168DFF)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined, size: 19, color: Color(0xFF19D9FF)),
                const Gap(7),
                const Text('Connection Time', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const Gap(10),
                Text(
                  timeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatConnectionTime(Duration duration) {
  String two(int value) => value.toString().padLeft(2, '0');
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  return '${two(hours)}:${two(minutes)}:${two(seconds)}';
}

class _NetworkMetric extends StatelessWidget {
  const _NetworkMetric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: .14),
            border: Border.all(color: color.withValues(alpha: .75)),
            boxShadow: [BoxShadow(color: color.withValues(alpha: .28), blurRadius: 13)],
          ),
          child: Icon(icon, color: color, size: 25),
        ),
        const Gap(7),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        const Gap(3),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: value, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              if (unit.isNotEmpty) TextSpan(text: ' $unit', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoMetric extends StatelessWidget {
  const _InfoMetric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.leading,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: .13),
            border: Border.all(color: color.withValues(alpha: .72)),
            boxShadow: [BoxShadow(color: color.withValues(alpha: .2), blurRadius: 12)],
          ),
          child: Icon(icon, color: color, size: 25),
        ),
        const Gap(9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const Gap(4),
              Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const Gap(5),
                  ],
                  Expanded(
                    child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
