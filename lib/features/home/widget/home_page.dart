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
import 'package:hiddify/features/proxy/active/active_proxy_card.dart';
import 'package:hiddify/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
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
      colorScheme: theme.colorScheme.copyWith(
        brightness: Brightness.dark,
        surface: _panel,
        onSurface: Colors.white,
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
                width: 210,
                height: 54,
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
                            const _DataIpPanel(),
                            const Gap(14),
                            const ActiveProxyFooter(),
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
        center: Alignment(0, -.35),
        radius: 1.2,
        colors: [Color(0xFF0B2C58), Color(0xFF061A35), Color(0xFF020817)],
        stops: [0, .48, 1],
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          top: 115,
          left: -100,
          right: -100,
          child: Container(
            height: 230,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(180),
              border: Border.all(color: const Color(0x3310BFFF), width: 2),
              boxShadow: const [BoxShadow(color: Color(0x3310AFFF), blurRadius: 55, spreadRadius: 2)],
            ),
          ),
        ),
        Positioned(
          bottom: 80,
          left: -80,
          right: -80,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(180),
              border: Border.all(color: const Color(0x2210BFFF), width: 2),
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
                color: const Color(0xFF19D9FF),
                label: 'Download',
                value: connected ? formatMbps(down) : '0',
                unit: 'Mbps',
              ),
            ),
            Container(width: 1, height: 48, color: border.withValues(alpha: .35)),
            Expanded(
              child: _NetworkMetric(
                icon: Icons.north_rounded,
                color: const Color(0xFFE879F9),
                label: 'Upload',
                value: connected ? formatMbps(up) : '0',
                unit: 'Mbps',
              ),
            ),
            Container(width: 1, height: 48, color: border.withValues(alpha: .35)),
            Expanded(
              child: _NetworkMetric(
                icon: Icons.bolt_rounded,
                color: const Color(0xFFFFC247),
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


/// Live transfer total and exit IP. Values come from the VPN core/IP lookup, never demo data.
class _DataIpPanel extends HookConsumerWidget {
  const _DataIpPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsNotifierProvider).valueOrNull;
    final connected = ref.watch(
      connectionNotifierProvider.select((s) => s.valueOrNull is Connected),
    );
    final ipState = ref.watch(ipInfoNotifierProvider);
    final ip = connected ? (ipState.valueOrNull?.ip ?? (ipState.isLoading ? 'Checking…' : '--')) : '--';
    final total = connected ? (((stats?.downlinkTotal as num?) ?? 0).toInt()).size() : '0 B';
    const border = Color(0xFF168DFF);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF08264B), Color(0xFF04152D)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border, width: 1.1),
          boxShadow: const [BoxShadow(color: Color(0x44108FFF), blurRadius: 22)],
        ),
        child: Row(
          children: [
            Expanded(
              child: _InfoMetric(
                icon: Icons.bar_chart_rounded,
                color: const Color(0xFF19D9FF),
                label: 'Data Used',
                value: total,
              ),
            ),
            Container(width: 1, height: 48, color: border.withValues(alpha: .45)),
            Expanded(
              child: _InfoMetric(
                icon: Icons.language_rounded,
                color: const Color(0xFF19D9FF),
                label: 'IP Address',
                value: ip,
                onTap: connected ? () => ref.read(ipInfoNotifierProvider.notifier).refresh() : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w800)),
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
        Text(label, maxLines: 1, style: theme.textTheme.labelMedium),
        const Gap(3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: value, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
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
