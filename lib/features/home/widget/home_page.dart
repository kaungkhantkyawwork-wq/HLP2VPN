import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    // final hasAnyProfile = ref.watch(hasAnyProfileProvider);
    final activeProfile = ref.watch(activeProfileProvider);

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/source/logo.png',
                      width: 42,
                      height: 42,
                      fit: BoxFit.contain,
                    ),
                    const Gap(12),
                    const Text(
                      "HLP2VPN",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.home_rounded),
                title: Text(t.pages.home.title),
                selected: true,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRect(
              child: SizedBox(
                width: 190,
                height: 48,
                child: Image.asset(
                  'assets/images/source/hlp2vpn_header_logo.png',
                  width: 190,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.center,
                ),
              ),
            ),
            const Gap(6),
            const AppVersionLabel(),
          ],
        ),
        actions: [
          // IconButton(
          //     onPressed: () => const QuickSettingsRoute().push(context),
          //     icon: const Icon(FluentIcons.options_24_filled),
          //     material: (context, platform) => MaterialIconButtonData(
          //           tooltip: t.config.quickSettings,
          //         )),
          // IconButton(
          //     onPressed: () => const AddProfileRoute().push(context),
          //     icon: const Icon(FluentIcons.add_circle_24_filled),
          //     material: (context, platform) => MaterialIconButtonData(
          //           tooltip: t.profile.add.buttonText,
          //         )),
          Semantics(
            key: const ValueKey("profile_add_button"),
            label: t.pages.profiles.add,
            child: IconButton(
              icon: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFC928)),
              onPressed: () => ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile(),
            ),
          ),
          const Gap(8),
        ],
      ),
      // The sky and the map are drawn once into their own layer: a ripple or a label changing on
      // the page no longer redraws the whole map image under it.
      body: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: DecoratedBox(
              decoration: BoxDecoration(
                // Deep navy atmosphere with a soft electric-blue glow around the connect button.
                gradient: theme.brightness == Brightness.dark
                    ? const RadialGradient(
                        center: Alignment(0, -.15),
                        radius: .95,
                        colors: [Color(0xFF0B2445), Color(0xFF061A35), Color(0xFF020A19)],
                        stops: [0, .48, 1],
                      )                    : RadialGradient(
                        center: const Alignment(0, -.15),
                        radius: 1.1,
                        colors: [
                          Colors.white.withValues(alpha: .55),
                          Colors.white.withValues(alpha: 0),
                          Colors.black.withValues(alpha: .045),
                        ],
                        stops: const [0, .5, 1],
                      ),
                image: DecorationImage(
                  image: const AssetImage('assets/images/world_map.png'), // Replace with your image path
                  fit: BoxFit.cover,
                  opacity: 0.09,
                  colorFilter: theme.brightness == Brightness.dark
                      ? ColorFilter.mode(Colors.white.withValues(alpha: .15), BlendMode.srcIn) //
                      : ColorFilter.mode(
                          Colors.grey.withValues(alpha: 1),
                          BlendMode.srcATop,
                        ), // Apply white tint in dark mode
                ),
              ),
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 600, // Set the maximum width here
                  ),
                  // The page does not move under the finger: no bounce (iOS) or stretch (Android) when it
                  // fits the screen. It still scrolls, without them, when it does not (a small screen or a
                  // large font).
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
                    child: CustomScrollView(
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        // switch (activeProfile) {
                        // AsyncData(value: final profile?) =>
                        MultiSliver(
                          children: [
                            // const Gap(100),
                            switch (activeProfile) {
                              AsyncData(value: final profile?) => ProfileTile(
                                profile: profile,
                                isMain: true,
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              _ => const Text(""),
                            },
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Gap(10),
                                        const ConnectionButton(),
                                        const Gap(18),
                                        const _LiveNetworkPanel(),
                                        const Gap(12),
                                      ],
                                    ),
                                  ),
                                  ActiveProxyFooter(),
                                  Gap(32),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // AsyncData() => switch (hasAnyProfile) {
                        //     AsyncData(value: true) => const EmptyActiveProfileHomeBody(),
                        //     _ => const EmptyProfilesHomeBody(),
                        //   },
                        // AsyncError(:final error) => SliverErrorBodyPlaceholder(t.presentShortError(error)),
                        // _ => const SliverToBoxAdapter(),
                        // },
                      ],
                    ),
                  ),
                ),
              ),
              if (ref.watch(hasAnyProfileProvider).value ?? false)
                Positioned(
                  right: 0,
                  left: 0,
                  bottom: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    // tabs of either height stand on the bottom edge
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // in proxy mode, a smaller tab beside this one on how to point apps at the proxy
                      const Flexible(child: LocalProxyHint()),
                      Material(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          onTap: () => ref.read(bottomSheetsNotifierProvider.notifier).showQuickSettings(),
                          child: Container(
                            height: 32,
                            padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(t.pages.home.quickSettings),
                                const Gap(4),
                                const Icon(Icons.arrow_drop_up_rounded, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
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
                TextSpan(text: value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                if (unit.isNotEmpty)
                  TextSpan(text: ' $unit', style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
