import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/notifier/profiles_update_notifier.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/features/proxy/widget/proxy_tile.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Shows the actual outbound servers imported from the active subscription.
/// The profile list is for managing subscriptions; this sheet is for choosing
/// an individual server from the active subscription.
class ProxiesModal extends HookConsumerWidget {
  const ProxiesModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final proxies = ref.watch(proxiesOverviewNotifierProvider);
    final sortBy = ref.watch(proxiesSortNotifierProvider);

    const navy = Color(0xFF041426);
    const panel = Color(0xFF071D35);
    const cyan = Color(0xFF18CFFF);
    final darkTheme = Theme.of(context).copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: navy,
      colorScheme: ColorScheme.fromSeed(seedColor: cyan, brightness: Brightness.dark, surface: panel, primary: cyan, secondary: const Color(0xFF38E8FF)),
      dividerColor: cyan.withValues(alpha: .22),
    );

    return Theme(
      data: darkTheme,
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF092747), Color(0xFF041426), Color(0xFF020B16)]),
          ),
          child: DraggableScrollableSheet(
        initialChildSize: .72,
        minChildSize: .42,
        maxChildSize: .92,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.pages.proxies.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFFF3FBFF), fontWeight: FontWeight.w800, letterSpacing: .2),
                    ),
                  ),
                  PopupMenuButton<ProxiesSort>(
                    tooltip: t.pages.proxies.sort,
                    initialValue: sortBy,
                    onSelected: ref.read(proxiesSortNotifierProvider.notifier).update,
                    itemBuilder: (context) => [
                      for (final item in ProxiesSort.values)
                        PopupMenuItem(value: item, child: Text(item.present(t))),
                    ],
                    icon: const Icon(Icons.swap_vert_rounded, color: Color(0xFF18CFFF), size: 27),
                  ),
                  IconButton(
                    tooltip: t.pages.profiles.updateSubscriptions,
                    onPressed: () => ref.read(foregroundProfilesUpdateNotifierProvider.notifier).trigger(),
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF18CFFF), size: 26),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: const Color(0x5518CFFF)),
            Expanded(
              child: proxies.when(
                data: (group) {
                  if (group == null || group.items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          ref.watch(serviceRunningProvider)
                              ? t.pages.proxies.empty
                              : t.pages.proxies.connectToSeeProxies,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  final bestMatches = group.items.where((proxy) => proxy.name.toLowerCase() == 'lowest').toList();
                  final bestServer = bestMatches.isEmpty ? null : bestMatches.first;
                  final originalServers = group.items
                      .where((proxy) => !proxy.isGroup && !proxy.tag.contains('§hide§'))
                      .toList();

                  BoxDecoration serverCardDecoration(bool selected) => BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: selected
                          ? const [Color(0xFF103D59), Color(0xFF08243D)]
                          : const [Color(0xFF0A2742), Color(0xFF061A2E)],
                    ),
                    border: Border.all(
                      color: selected ? const Color(0xFF18DFFF) : const Color(0xFF1B5A7C),
                      width: selected ? 1.8 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF08BFEA).withValues(alpha: selected ? .20 : .07),
                        blurRadius: selected ? 18 : 10,
                        spreadRadius: selected ? 1 : 0,
                      ),
                    ],
                  );

                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(4, 2, 4, 10),
                        child: Text(
                          'BEST SERVER',
                          style: TextStyle(color: Color(0xFF18DFFF), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.3),
                        ),
                      ),
                      if (bestServer != null)
                        Container(
                          decoration: serverCardDecoration(group.selected == bestServer.tag),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            leading: const CircleAvatar(
                              backgroundColor: Color(0x3320D8FF),
                              child: Icon(Icons.bolt_rounded, color: Color(0xFF18DFFF), size: 27),
                            ),
                            title: const Text('Best Server', style: TextStyle(color: Color(0xFFF3FBFF), fontWeight: FontWeight.w800, fontSize: 17)),
                            subtitle: const Text('Auto • Lowest Ping', style: TextStyle(color: Color(0xFF9BC8DD), fontSize: 13)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  bestServer.urlTestDelay > 0 && bestServer.urlTestDelay < 65000
                                      ? '${bestServer.urlTestDelay} ms'
                                      : '--',
                                  style: const TextStyle(color: Color(0xFF45E6A0), fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                                const SizedBox(width: 10),
                                Icon(
                                  group.selected == bestServer.tag ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                                  color: const Color(0xFF18DFFF),
                                  size: 25,
                                ),
                              ],
                            ),
                            onTap: () async => await ref.read(proxiesOverviewNotifierProvider.notifier).changeProxy(group.tag, bestServer.tag),
                          ),
                        )
                      else
                        const Text('Best Server option is not available in this subscription.', style: TextStyle(color: Color(0xFF9BC8DD))),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(4, 24, 4, 10),
                        child: Text(
                          'ORIGINAL SERVERS',
                          style: TextStyle(color: Color(0xFF18DFFF), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.3),
                        ),
                      ),
                      if (originalServers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('No individual servers found.', style: TextStyle(color: Color(0xFF9BC8DD))),
                        )
                      else
                        for (final proxy in originalServers)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              decoration: serverCardDecoration(group.selected == proxy.tag),
                              clipBehavior: Clip.antiAlias,
                              child: ProxyTile(
                                proxy,
                                key: ValueKey(proxy.tag),
                                selected: group.selected == proxy.tag,
                                onTap: () async => await ref.read(proxiesOverviewNotifierProvider.notifier).changeProxy(group.tag, proxy.tag),
                              ),
                            ),
                          ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(t.pages.proxies.loadFailed, textAlign: TextAlign.center),
                  ),
                ),
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
