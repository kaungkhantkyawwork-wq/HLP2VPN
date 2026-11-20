import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/adaptive_layout/shell_route_action.dart';
import 'package:hiddify/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:hiddify/core/router/go_router/routing_config_notifier.dart';
import 'package:hiddify/features/stats/widget/side_bar_stats_overview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MyAdaptiveLayout extends HookConsumerWidget {
  const MyAdaptiveLayout({
    super.key,
    required this.navigationShell,
    required this.isMobileBreakpoint,
    required this.showProfilesAction,
  });
  // managed by go router(Shell Route)
  final StatefulNavigationShell navigationShell;
  final bool isMobileBreakpoint;
  final bool showProfilesAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final isSettingsBranch = navigationShell.currentIndex ==
        getIndexOfBranch(isMobileBreakpoint, showProfilesAction, 'settings');
    const settingsNavy = Color(0xFF061426);
    const settingsCyan = Color(0xFF19D7FF);
    final settingsTheme = Theme.of(context).copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: settingsNavy,
      colorScheme: ColorScheme.fromSeed(
        seedColor: settingsCyan,
        brightness: Brightness.dark,
        surface: const Color(0xFF0A2542),
        primary: settingsCyan,
        secondary: const Color(0xFF648BFF),
      ),
      textTheme: Theme.of(context).textTheme.apply(
        bodyColor: const Color(0xFFF2F8FF),
        displayColor: const Color(0xFFF2F8FF),
      ),
      primaryTextTheme: Theme.of(context).primaryTextTheme.apply(
        bodyColor: const Color(0xFFF2F8FF),
        displayColor: const Color(0xFFF2F8FF),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: settingsNavy,
        foregroundColor: Color(0xFFF3FAFF),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      iconTheme: const IconThemeData(color: settingsCyan),
      listTileTheme: const ListTileThemeData(
        textColor: Color(0xFFF2F8FF),
        iconColor: settingsCyan,
        subtitleTextStyle: TextStyle(color: Color(0xFFA9C2D9)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? settingsCyan : const Color(0xFFB8CBE0)),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? const Color(0xFF176B9D) : const Color(0xFF34465A)),
        trackOutlineColor: WidgetStateProperty.all(settingsCyan.withValues(alpha: .55)),
      ),
      dividerTheme: const DividerThemeData(color: Color(0x3327CFFF)),
      popupMenuTheme: const PopupMenuThemeData(
        color: Color(0xFF0A2542),
        textStyle: TextStyle(color: Color(0xFFF2F8FF)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0A2542),
        labelStyle: const TextStyle(color: Color(0xFFA9C2D9)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B5A7C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: settingsCyan, width: 1.5),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF087FC5),
        foregroundColor: Colors.white,
      ),
    );
    final branchContent = Theme(
      data: isSettingsBranch ? settingsTheme : Theme.of(context),
      child: navigationShell,
    );
    // focus switch management
    final primaryFocusHash = useState<int?>(null);
    final navScopeNode = useFocusScopeNode();
    useEffect(() {
      bool handler(KeyEvent event) {
        final arrows = isMobileBreakpoint ? KeyboardConst.verticalArrows : KeyboardConst.horizontalArrows;
        if (!arrows.contains(event.logicalKey)) return false;
        if (event is KeyDownEvent) {
          primaryFocusHash.value = FocusManager.instance.primaryFocus.hashCode;
        } else {
          // focus node does not change => true.
          if (primaryFocusHash.value == FocusManager.instance.primaryFocus.hashCode) {
            if (branchesScope.values.any((node) => node.hasFocus)) {
              navScopeNode.requestFocus();
            } else if (navScopeNode.hasFocus) {
              branchesScope[getNameOfBranch(isMobileBreakpoint, showProfilesAction, navigationShell.currentIndex)]
                  ?.requestFocus();
            }
          }
        }
        return true;
      }

      HardwareKeyboard.instance.addHandler(handler);
      return () {
        HardwareKeyboard.instance.removeHandler(handler);
      };
    }, [isMobileBreakpoint, showProfilesAction, navigationShell.currentIndex]);
    // Owns the system back press for the whole shell.
    //
    // It has to sit here, on the visible shell, and nowhere else. A PopScope
    // inside a branch stays mounted after the user leaves that branch, and go
    // router then lets it answer presses meant for another branch, which locks
    // the back button for good (flutter/flutter#193098).
    //
    // canPop is always false so the platform always routes the press to us.
    // Otherwise Android closes the app without calling into Flutter at all, and
    // no callback of ours ever runs. A press that a branch can handle is popped
    // by go router before it reaches here, so this only sees presses at the
    // root of a branch.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final homeIndex = getIndexOfBranch(isMobileBreakpoint, showProfilesAction, 'home');
        if (navigationShell.currentIndex != homeIndex) {
          // on another branch: go home instead of closing the app
          navigationShell.goBranch(homeIndex);
        } else {
          // already home: this is the way out of the app
          SystemNavigator.pop();
        }
      },
      // Keeps the claim above alive on the platform side.
      //
      // Every branch navigator broadcasts whether it can handle a back press,
      // and the last broadcast wins. Popping a page inside a branch leaves it
      // reporting "cannot handle", which reaches Android and makes it close the
      // app on the next press without ever calling Flutter. The PopScope above
      // always handles the press, so that report is wrong: replace it.
      child: NotificationListener<NavigationNotification>(
        onNotification: (notification) {
          if (notification.canHandlePop) return false;
          const NavigationNotification(canHandlePop: true).dispatch(context);
          return true;
        },
        child: Material(
          child: Scaffold(
            body: isMobileBreakpoint
                ? branchContent
                : Row(
                    children: [
                      FocusScope(
                        node: navScopeNode,
                        child: NavigationRail(
                          extended: Breakpoint(context).isDesktop(),
                          destinations: _navRailDests(_actions(t, showProfilesAction, isMobileBreakpoint)),
                          selectedIndex: navigationShell.currentIndex,
                          onDestinationSelected: (index) => _onTap(context, index),
                          trailing: Breakpoint(context).isDesktop()
                              ? const Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: SizedBox(width: 220, child: SideBarStatsOverview()),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      // Keeps the rail visible to screen readers (#2097).
                      //
                      // Every page route draws a modal barrier, and its
                      // BlockSemantics drops all the semantics painted before
                      // it, up to the nearest container. Without this boundary
                      // that reached the rail, so NVDA saw no sidebar at all
                      // (flutter/flutter#135656).
                      Expanded(child: Semantics(container: true, child: branchContent)),
                    ],
                  ),
            bottomNavigationBar: isMobileBreakpoint &&
                    navigationShell.currentIndex != getIndexOfBranch(isMobileBreakpoint, showProfilesAction, 'home')
                ? FocusScope(
                    node: navScopeNode,
                    child: NavigationBar(
                      selectedIndex: navigationShell.currentIndex <= 1 ? navigationShell.currentIndex : 0,
                      destinations: _navDests(_actions(t, showProfilesAction, isMobileBreakpoint)),
                      onDestinationSelected: (index) => _onTap(context, index),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  // shell route action onTap
  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  List<ShellRouteAction> _actions(Translations t, bool showProfilesAction, bool isMobileBreakpoint) => [
    ShellRouteAction(Icons.power_settings_new_rounded, t.pages.home.title),
    if (showProfilesAction && !isMobileBreakpoint) ShellRouteAction(Icons.view_list_rounded, t.pages.profiles.title),
    ShellRouteAction(Icons.settings_rounded, t.pages.settings.title),
    if (!isMobileBreakpoint) ShellRouteAction(Icons.description_rounded, t.pages.logs.title),
    if (!isMobileBreakpoint) ShellRouteAction(Icons.info_rounded, t.pages.about.title),
  ];

  List<NavigationDestination> _navDests(List<ShellRouteAction> actions) =>
      actions.map((e) => NavigationDestination(icon: Icon(e.icon), label: e.title)).toList();
  List<NavigationRailDestination> _navRailDests(List<ShellRouteAction> actions) =>
      actions.map((e) => NavigationRailDestination(icon: Icon(e.icon), label: Text(e.title))).toList();
}
