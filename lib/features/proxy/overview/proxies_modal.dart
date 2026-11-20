import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/notifier/profiles_update_notifier.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
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

    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: .72,
        minChildSize: .42,
        maxChildSize: .92,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.pages.proxies.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
                    icon: const Icon(Icons.sort_rounded),
                  ),
                  IconButton(
                    tooltip: t.pages.profiles.updateSubscriptions,
                    onPressed: () => ref.read(foregroundProfilesUpdateNotifierProvider.notifier).trigger(),
                    icon: const Icon(Icons.sync_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
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
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    itemCount: group.items.length,
                    separatorBuilder: (_, _) => const Gap(4),
                    itemBuilder: (context, index) {
                      final proxy = group.items[index];
                      return ProxyTile(
                        proxy,
                        key: ValueKey(proxy.tag),
                        selected: group.selected == proxy.tag,
                        onTap: () async {
                          await ref.read(proxiesOverviewNotifierProvider.notifier).changeProxy(group.tag, proxy.tag);
                        },
                      );
                    },
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
    );
  }
}
