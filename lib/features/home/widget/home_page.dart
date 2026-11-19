import 'dart:async';

import 'package:dartx/dartx.dart';
import 'package:hiddify/utils/number_formatters.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/home/widget/local_proxy_hint.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/stats/notifier/stats_notifier.dart';
import 'package:hiddify/features/proxy/widget/upload_speed.dart';
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
      scaffoldBackgroundColor: _navy,
      cardTheme: theme.cardTheme.copyWith(
        color: const Color(0xFF061A34),
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x66008CFF),
        elevation: 0,
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
                width: 250,
                height: 62,
                child: Image.asset(
                  'assets/images/source/hlp2vpn_header_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const Gap(6),
              const AppVersionLabel(),
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
                  child: CustomScrollView(
                    physics: const ClampingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 108),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            switch (activeProfile) {
                              AsyncData(value: final profile?) => _NeonCard(
                                child: ProfileTile(
                                  profile: profile,
                                  isMain: true,
                                  margin: EdgeInsets.zero,
                                ),
                              ),
                              _ => const _NeonCard(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('Select a server to get started'),
                                ),
                              ),
                            },
                            const Gap(22),
                            const Center(child: ConnectionButton()),
                            const Gap(22),
                            const _LiveNetworkPanel(),
                            const Gap(12),
                            const _DataServerPanel(),

                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _HlpBottomNavigation(
          onServers: () => ref.read(bottomSheetsNotifierProvider.notifier).showProfilesOverview(),
          onSettings: () => context.goNamed('settings'),
        ),
      ),
    );
  }
}

class _PremiumHomeBackdrop extends StatelessWidget {
  const _PremiumHomeBackdrop();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0, -.28),
        radius: 1.05,
        colors: [Color(0xFF092B50), Color(0xFF04172F), Color(0xFF010713)],
        stops: [0, .42, 1],
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          top: 185,
          left: -130,
          right: -130,
          child: Container(
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(180),
              border: Border.all(color: const Color(0x2210CFFF), width: 1),
              boxShadow: const [BoxShadow(color: Color(0x18008FFF), blurRadius: 42, spreadRadius: 1)],
            ),
          ),
        ),
        Positioned(
          bottom: 115,
          left: -110,
          right: -110,
          child: Container(
            height: 165,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(180),
              border: Border.all(color: const Color(0x1C10BFFF), width: 1),
              boxShadow: const [BoxShadow(color: Color(0x14008FFF), blurRadius: 36, spreadRadius: 1)],
            ),
          ),
        ),
      ],
    ),
  );
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
        colors: [Color(0xFF0A2B55), Color(0xFF04152E)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFF168DFF), width: 1.2),
      boxShadow: const [
        BoxShadow(color: Color(0x55108FFF), blurRadius: 22, spreadRadius: 1),
        BoxShadow(color: Color(0x2210DFFF), blurRadius: 8),
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
          gradient: const LinearGradient(colors: [Color(0xFF08264C), Color(0xFF03152D)]),
          borderRadius: BorderRadius.circular(38),
          border: Border.all(color: const Color(0xFF168DFF), width: 1.2),
          boxShadow: const [BoxShadow(color: Color(0x66108FFF), blurRadius: 20)],
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
      color: selected ? const Color(0xFF075C9E) : Colors.transparent,
      borderRadius: BorderRadius.circular(34),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(34),
        child: Container(
          decoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: const Color(0xFF08D9FF), width: 1.4),
                  boxShadow: const [BoxShadow(color: Color(0xAA08BFFF), blurRadius: 18)],
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
    final down = connected ? (stats?.downlink.toInt() ?? 0) : 0;
    final up = connected ? (stats?.uplink.toInt() ?? 0) : 0;
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
                value: connected ? formatMbps(down) : '0',
                unit: 'Mbps',
              ),
            ),
            Container(width: 1, height: 48, color: border.withValues(alpha: .35)),
            Expanded(
              child: _NetworkMetric(
                icon: Icons.north_rounded,
                color: const Color(0xFFFF4DFF),
                label: 'Upload',
                value: connected ? formatMbps(up) : '0',
                unit: 'Mbps',
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
    final activeProxy = ref.watch(activeProxyNotifierProvider).valueOrNull;
    final connected = status is Connected;
    final connecting = status is Connecting || status is Waiting || status is HotReloading;
    final total = connected ? (((stats?.downlinkTotal as num?) ?? 0).toInt()).size() : '0 B';

    // The selected outbound is the actual server (e.g. TH-1 / SG-1), not the
    // subscription/profile title such as "HLP2VPN Servers".
    final serverName = activeProxy?.name ?? '--';
    final serverLabel = connected
        ? 'Connected Server'
        : connecting
            ? 'Connecting to'
            : 'Selected Server';
    final flag = _serverFlag(serverName);

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
          border: Border.all(color: const Color(0xFF168DFF), width: 1.1),
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
                    leading: flag,
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

String _serverFlag(String name) {
  final match = RegExp(r'^([A-Za-z]{2})[-_ ]').firstMatch(name.trim());
  if (match == null) return '';
  final code = match.group(1)!.toUpperCase();
  if (!RegExp(r'^[A-Z]{2}

class _InfoMetric extends StatelessWidget {
  const _InfoMetric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.onTap,
    this.leading,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final String? leading;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: .13),
              border: Border.all(color: color.withValues(alpha: .7)),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          if (leading != null && leading!.isNotEmpty) ...[
            const Gap(5),
            Text(leading!, style: const TextStyle(fontSize: 19)),
          ],
          const Gap(9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70)),
                const Gap(4),
                Text(value, maxLines: 2, softWrap: true, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w800, height: 1.12)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
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
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: .13),
            border: Border.all(color: color.withValues(alpha: .72), width: 1),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: .38), blurRadius: 16, spreadRadius: 1),
            ],
          ),
          child: Icon(icon, color: color, size: 23),
        ),
        const Gap(5),
        Text(label, maxLines: 1, style: theme.textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: .3)),
        const Gap(3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: value, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, shadows: [Shadow(color: color.withValues(alpha: .55), blurRadius: 10)])),
                if (unit.isNotEmpty)
                  TextSpan(text: ' $unit', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
).hasMatch(code)) return '';
  return String.fromCharCodes(code.codeUnits.map((unit) => 0x1F1E6 + unit - 0x41));
}

class _InfoMetric extends StatelessWidget {
  const _InfoMetric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: .13),
              border: Border.all(color: color.withValues(alpha: .7)),
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
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70)),
                const Gap(4),
                Text(value, maxLines: 2, softWrap: true, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w800, height: 1.12)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
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
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: .13),
            border: Border.all(color: color.withValues(alpha: .72), width: 1),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: .38), blurRadius: 16, spreadRadius: 1),
            ],
          ),
          child: Icon(icon, color: color, size: 23),
        ),
        const Gap(5),
        Text(label, maxLines: 1, style: theme.textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: .3)),
        const Gap(3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: value, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, shadows: [Shadow(color: color.withValues(alpha: .55), blurRadius: 10)])),
                if (unit.isNotEmpty)
                  TextSpan(text: ' $unit', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
