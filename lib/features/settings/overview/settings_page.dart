import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/settings/notifier/config_option/config_option_notifier.dart';
import 'package:hiddify/features/settings/notifier/reset_tunnel/reset_tunnel_notifier.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum ConfigOptionSection {
  warp,
  fragment;

  static final _warpKey = GlobalKey(debugLabel: "warp-section-key");
  static final _fragmentKey = GlobalKey(debugLabel: "fragment-section-key");

  GlobalKey get key => switch (this) {
    ConfigOptionSection.warp => _warpKey,
    ConfigOptionSection.fragment => _fragmentKey,
  };
}

class SettingsPage extends HookConsumerWidget {
  SettingsPage({super.key, String? section})
    : section = section != null ? ConfigOptionSection.values.byName(section) : null;

  final ConfigOptionSection? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    // final scrollController = useScrollController();

    // useMemoized(
    //   () {
    //     if (section != null) {
    //       WidgetsBinding.instance.addPostFrameCallback(
    //         (_) {
    //           final box = section!.key.currentContext?.findRenderObject() as RenderBox?;

    //           final offset = box?.localToGlobal(Offset.zero);
    //           if (offset == null) return;
    //           final height = scrollController.offset + offset.dy - MediaQueryData.fromView(View.of(context)).padding.top - kToolbarHeight;
    //           scrollController.animateTo(
    //             height,
    //             duration: const Duration(milliseconds: 500),
    //             curve: Curves.decelerate,
    //           );
    //         },
    //       );
    //     }
    //   },
    // );

    const navy = Color(0xFF061426);
    const panel = Color(0xFF0A2542);
    const cyan = Color(0xFF19D7FF);
    final settingsTheme = Theme.of(context).copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: navy,
      colorScheme: ColorScheme.fromSeed(
        seedColor: cyan,
        brightness: Brightness.dark,
        surface: panel,
        primary: cyan,
        secondary: const Color(0xFF648BFF),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        foregroundColor: Color(0xFFF3FAFF),
        elevation: 0,
        centerTitle: false,
      ),
      dividerColor: const Color(0x3327CFFF),
    );

    return Theme(
      data: settingsTheme,
      child: Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        title: Text(t.pages.settings.title, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .2)),
        actions: [
          MenuAnchor(
            menuChildren: <Widget>[
              SubmenuButton(
                menuChildren: <Widget>[
                  MenuItemButton(
                    onPressed: () async => await ref
                        .read(dialogNotifierProvider.notifier)
                        .showConfirmation(
                          title: t.common.msg.import.confirm,
                          message: t.dialogs.confirmation.settings.import.msg,
                        )
                        .then((shouldImport) async {
                          if (shouldImport) {
                            await ref.read(configOptionNotifierProvider.notifier).importFromClipboard();
                          }
                        }),
                    child: Text(t.pages.settings.options.import.clipboard),
                  ),
                  MenuItemButton(
                    onPressed: () async => await ref
                        .read(dialogNotifierProvider.notifier)
                        .showConfirmation(
                          title: t.common.msg.import.confirm,
                          message: t.dialogs.confirmation.settings.import.msg,
                        )
                        .then((shouldImport) async {
                          if (shouldImport) {
                            await ref.read(configOptionNotifierProvider.notifier).importFromJsonFile();
                          }
                        }),
                    child: Text(t.pages.settings.options.import.file),
                  ),
                ],
                child: Text(t.common.import),
              ),
              SubmenuButton(
                menuChildren: <Widget>[
                  MenuItemButton(
                    onPressed: () async => await ref.read(configOptionNotifierProvider.notifier).exportJsonClipboard(),
                    child: Text(t.pages.settings.options.export.anonymousToClipboard),
                  ),
                  MenuItemButton(
                    onPressed: () async => await ref.read(configOptionNotifierProvider.notifier).exportJsonFile(),
                    child: Text(t.pages.settings.options.export.anonymousToFile),
                  ),
                  const PopupMenuDivider(),
                  MenuItemButton(
                    onPressed: () async => await ref
                        .read(configOptionNotifierProvider.notifier)
                        .exportJsonClipboard(excludePrivate: false),
                    child: Text(t.pages.settings.options.export.allToClipboard),
                  ),
                  MenuItemButton(
                    onPressed: () async =>
                        await ref.read(configOptionNotifierProvider.notifier).exportJsonFile(excludePrivate: false),
                    child: Text(t.pages.settings.options.export.allToFile),
                  ),
                ],
                child: Text(t.common.export),
              ),
              const PopupMenuDivider(),
              MenuItemButton(
                child: Text(t.pages.settings.options.reset),
                onPressed: () async => await ref.read(configOptionNotifierProvider.notifier).resetOption(),
              ),
            ],
            builder: (context, controller, child) => IconButton(
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ),
          const Gap(8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF031426), Color(0xFF06182B), Color(0xFF020B16)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            children: [
              SettingsSection(
                compact: true,
                title: t.pages.settings.general.title,
                icon: Icons.tune_rounded,
                subtitle: const Text('Language, theme and app preferences'),
                accent: const Color(0xFF00CFFF),
                namedLocation: context.namedLocation('general'),
              ),
              const Gap(5),
              _SettingsGroupLabel(title: 'NETWORK & SECURITY'),
              const Gap(2),
              if (ref.watch(hasAnyProfileProvider).value ?? false)
                Row(
                  children: [
                    Expanded(
                      child: SettingsSection(
                        compact: true,
                        title: t.pages.settings.chain.title,
                        icon: Icons.hub_rounded,
                        subtitle: Text(t.pages.settings.chain.subtitle),
                        accent: const Color(0xFF9A55F5),
                        namedLocation: context.namedLocation('chainOptions'),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: SettingsSection(
                        compact: true,
                        title: t.pages.settings.routing.title,
                        icon: Icons.alt_route_rounded,
                        subtitle: const Text('Traffic rules & routing'),
                        accent: const Color(0xFF168BFA),
                        namedLocation: context.namedLocation('routingOptions'),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: SettingsSection(
                        compact: true,
                        title: t.pages.settings.routing.title,
                        icon: Icons.alt_route_rounded,
                        subtitle: const Text('Traffic rules & routing'),
                        accent: const Color(0xFF168BFA),
                        namedLocation: context.namedLocation('routingOptions'),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: SettingsSection(
                        compact: true,
                        title: t.pages.settings.dns.title,
                        icon: Icons.dns_rounded,
                        subtitle: const Text('DNS servers & resolution'),
                        accent: const Color(0xFF00CFFF),
                        namedLocation: context.namedLocation('dnsOptions'),
                      ),
                    ),
                  ],
                ),
              if (ref.watch(hasAnyProfileProvider).value ?? false)
                Row(
                  children: [
                    Expanded(
                      child: SettingsSection(
                        compact: true,
                        title: t.pages.settings.dns.title,
                        icon: Icons.dns_rounded,
                        subtitle: const Text('DNS servers & resolution'),
                        accent: const Color(0xFF00CFFF),
                        namedLocation: context.namedLocation('dnsOptions'),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: SettingsSection(
                        compact: true,
                        title: t.pages.settings.inbound.title,
                        icon: Icons.input_rounded,
                        subtitle: const Text('VPN & local proxy options'),
                        accent: const Color(0xFF08BFA4),
                        namedLocation: context.namedLocation('inboundOptions'),
                      ),
                    ),
                  ],
                )
              else
                SettingsSection(
                  compact: true,
                  title: t.pages.settings.inbound.title,
                  icon: Icons.input_rounded,
                  subtitle: const Text('VPN & local proxy options'),
                  accent: const Color(0xFF08BFA4),
                  namedLocation: context.namedLocation('inboundOptions'),
                ),
              SettingsSection(
                compact: true,
                title: t.pages.settings.tlsTricks.title,
                icon: Icons.security_rounded,
                subtitle: const Text('Advanced connection techniques'),
                accent: const Color(0xFF9A55F5),
                namedLocation: context.namedLocation('tlsTricks'),
              ),
              if ((PlatformUtils.isIOS || PlatformUtils.isMacOS) &&
                  ref.watch(hiddifyCoreServiceProvider).core.hasVpnProfile)
                SettingsSection(
                  compact: true,
                  title: t.pages.settings.resetTunnel,
                  icon: Icons.restart_alt_rounded,
                  accent: const Color(0xFFFFB454),
                  onTap: () async => await ref.read(resetTunnelNotifierProvider.notifier).run(),
                ),
              const Gap(2),
              _SettingsGroupLabel(title: 'TOOLS & INFORMATION'),
              const Gap(2),
              if (Breakpoint(context).isMobile())
                SettingsSection(
                  compact: true,
                  title: t.pages.about.title,
                  icon: Icons.info_outline_rounded,
                  subtitle: const Text('Version, updates and app information'),
                  accent: const Color(0xFF168BFA),
                  namedLocation: context.namedLocation('about'),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _SettingsGroupLabel extends StatelessWidget {
  const _SettingsGroupLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
    child: Text(
      title,
      style: const TextStyle(
        color: Color(0xFF7FA9C8),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.25,
      ),
    ),
  );
}

class SettingsSection extends HookConsumerWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.namedLocation,
    this.accent = const Color(0xFF18CFFF),
    this.onTap,
    this.compact = false,
  });

  final String title;
  final Widget? subtitle;
  final IconData icon;
  final String? namedLocation;
  final Color accent;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 8 : 10),
      decoration: BoxDecoration(
        color: const Color(0xCC0A2542),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: .34)),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: .055), blurRadius: 15, spreadRadius: 1),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap ?? (namedLocation == null ? null : () => context.go(namedLocation!)),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 10 : 15),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accent.withValues(alpha: .95), accent.withValues(alpha: .48)],
                    ),
                    boxShadow: [BoxShadow(color: accent.withValues(alpha: .18), blurRadius: 12)],
                  ),
                  child: Icon(icon, color: Colors.white, size: compact ? 21 : 24),
                ),
                const Gap(13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xFFF2F8FF), fontSize: compact ? 13 : 15, fontWeight: FontWeight.w700)),
                      if (subtitle != null) ...[
                        const Gap(4),
                        DefaultTextStyle(
                          style: TextStyle(color: const Color(0xFFA9C2D9), fontSize: compact ? 9 : 11.5, height: 1.2),
                          child: subtitle!,
                        ),
                      ],
                    ],
                  ),
                ),
                const Gap(8),
                Icon(Icons.chevron_right_rounded, color: accent, size: compact ? 21 : 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
