import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/keep_top/keep_top_widgets.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/features/proxy/widget/proxy_tile.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProxiesOverviewPage extends HookConsumerWidget with PresLogger {
  const ProxiesOverviewPage({super.key});

  static const _bg = Color(0xFF020817);
  static const _panel = Color(0xFF071B36);
  static const _cyan = Color(0xFF08D9FF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final proxies = ref.watch(proxiesOverviewNotifierProvider);
    final sortBy = ref.watch(proxiesSortNotifierProvider);
    final showResting = ref.watch(Preferences.showSleepingProxies);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('VPN Servers', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          const KeepTopAction(),
          PopupMenuButton<ProxiesSort>(
            initialValue: sortBy,
            onSelected: ref.read(proxiesSortNotifierProvider.notifier).update,
            icon: const Icon(Icons.sort_rounded, color: _cyan),
            tooltip: t.pages.proxies.sort,
            itemBuilder: (context) => [
              ...ProxiesSort.values.map((e) => PopupMenuItem(value: e, child: Text(e.present(t)))),
            ],
          ),
          const Gap(8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF071A2C), Color(0xFF061426), Color(0xFF030A14)],
          ),
        ),
        child: proxies.when(
        data: (group) => group != null
            ? Builder(
                builder: (context) {
                  final inUse = group.items
                      .where((e) => !e.resting && !e.isGroup && e.tag != lowestGroupTag && e.tag != balanceGroupTag)
                      .toList();
                  final resting = group.items.where((e) => e.resting && !e.isGroup).toList();
                  final listed = inUse.length;
                  var bestServerName = 'No server selected';
                  for (final item in group.items) {
                    if (item.tag == group.selected) {
                      bestServerName = item.nameWithDetour;
                      break;
                    }
                  }

                  Widget serverCard(OutboundInfo proxy) {
                    final selected = group.selected == proxy.tag;
                    final serverTheme = Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                        onSurface: Colors.white,
                        onSurfaceVariant: const Color(0xFFB8D8F4),
                      ),
                    );
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: selected
                              ? const [Color(0xFF0B4770), Color(0xFF08213D)]
                              : const [Color(0xFF0A294B), Color(0xFF06162C)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected ? _cyan : const Color(0xFF174A70),
                          width: selected ? 1.6 : 1,
                        ),
                        boxShadow: [
                          if (selected)
                            const BoxShadow(color: Color(0x5500CFFF), blurRadius: 18, spreadRadius: 1),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: Theme(
                          data: serverTheme,
                          child: ProxyTile(
                          proxy,
                          key: ValueKey(proxy.tag),
                          selected: selected,
                          quiet: group.keepTopPicking,
                          onTap: () async {
                            await ref.read(proxiesOverviewNotifierProvider.notifier).changeProxy(group.tag, proxy.tag);
                          },
                        ),
                        ),
                      ),
                    );
                  }

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF075B78), Color(0xFF102A62), Color(0xFF171B45)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: _cyan, width: 1.4),
                            boxShadow: const [BoxShadow(color: Color(0x5500BFFF), blurRadius: 20)],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () async {
                                await ref.read(proxiesOverviewNotifierProvider.notifier).urlTest(group.tag);
                                await ref.read(activeProxyNotifierProvider.notifier).switchToLowest(group.tag);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0x3324E6FF),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(color: const Color(0xAA50E9FF)),
                                      ),
                                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 27),
                                    ),
                                    const Gap(14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Best Server', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                                          const SizedBox(height: 3),
                                          Text(
                                            bestServerName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Color(0xFFB8EFFF), fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.bolt_rounded, color: Color(0xFF79F5FF), size: 27),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (group.keepTopPicking)
                        SliverToBoxAdapter(
                          child: KeepTopFooter(listed: listed, picking: group.keepTopPicking, proxies: group.items),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => serverCard(inUse[index]),
                            childCount: inUse.length,
                          ),
                        ),
                      ),
                      if (!group.keepTopPicking)
                        SliverToBoxAdapter(
                          child: KeepTopFooter(listed: listed, picking: group.keepTopPicking, proxies: group.items),
                        ),
                      if (resting.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: RestingProxiesHeader(
                            count: resting.length,
                            shown: showResting,
                            onToggle: () => ref.read(Preferences.showSleepingProxies.notifier).update(!showResting),
                          ),
                        ),
                        if (showResting)
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => serverCard(resting[index]),
                              childCount: resting.length,
                            ),
                          ),
                      ],
                      const SliverPadding(padding: EdgeInsets.only(bottom: 28)),
                    ],
                  );
                },
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    ref.watch(serviceRunningProvider) ? t.pages.proxies.empty : t.pages.proxies.connectToSeeProxies,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.pages.proxies.loadFailed, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                const Gap(12),
                TextButton(
                  onPressed: () => ref.invalidate(proxiesOverviewNotifierProvider),
                  child: Text(t.connection.tapToRetry),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: _cyan)),
        ),
      ),
    );
  }
}
