import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/common/general_pref_tiles.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class IntroPage extends HookConsumerWidget with PresLogger {
  const IntroPage({super.key});

  static bool locationInfoLoaded = false;

  /// The user picked the region on this screen: neither the time zone nor the language changes it after that.
  static bool _regionChosenByUser = false;
  static bool _localeChosenByUser = false;

  @visibleForTesting
  static void resetForTest() {
    locationInfoLoaded = false;
    _regionChosenByUser = false;
    _localeChosenByUser = false;
  }

  /// The region a language points to, or null for a language spoken in no listed region.
  /// Persian keeps Afghanistan when that is already the region.
  static Region? regionForLocale(AppLocale locale, Region current) => switch (locale) {
    AppLocale.fa => current == Region.af ? Region.af : Region.ir,
    AppLocale.ps => Region.af,
    AppLocale.zhCn => Region.cn,
    AppLocale.ru => Region.ru,
    AppLocale.id => Region.id,
    AppLocale.tr => Region.tr,
    AppLocale.ptBr => Region.br,
    _ => null,
  };

  Future<void> _setRegion(WidgetRef ref, Region region) async {
    await ref.read(ConfigOptions.region.notifier).update(region);
    await ref.read(ConfigOptions.directDnsAddress.notifier).reset();
  }

  // for focus management
  KeyEventResult _handleKeyEvent(KeyEvent event, String key) {
    if (KeyboardConst.activate.contains(event.logicalKey) && event is KeyDownEvent) {
      UriUtils.tryLaunch(Uri.parse(IntroConst.url[key]!));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final isStarting = useState(false);
    final acceptedTerms = useState(true);

    if (!locationInfoLoaded) {
      autoSelectRegion(ref).then((value) => loggy.debug("Auto Region selection finished!"));
      locationInfoLoaded = true;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF061329),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 120,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/source/hlp2vpn_full_logo.png',
                                  width: 340,
                                  height: 116,
                                  fit: BoxFit.contain,
                                ),
                                const Gap(8),
                                Text(
                                  t.intro.banner,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: .78),
                                    height: 1.5,
                                  ),
                                ),
                                const Gap(28),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0C2342),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFF08D9FF).withValues(alpha: .48),
                                    ),
                                  ),
                                  child: Theme(
                                    data: theme.copyWith(
                                      listTileTheme: const ListTileThemeData(
                                        iconColor: Color(0xFF08D9FF),
                                        textColor: Colors.white,
                                        titleTextStyle: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        subtitleTextStyle: TextStyle(
                                          color: Color(0xFFB8C8DA),
                                        ),
                                      ),
                                    ),
                                    child: LocalePrefTile(
                                      options: const [AppLocale.en, AppLocale.my],
                                      onChanged: (locale) async {
                                        _localeChosenByUser = true;
                                        if (_regionChosenByUser) return;
                                        final region = regionForLocale(
                                          locale,
                                          ref.read(ConfigOptions.region),
                                        );
                                        if (region != null) await _setRegion(ref, region);
                                      },
                                    ),
                                  ),
                                ),
                                const Gap(20),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0C2342).withValues(alpha: .72),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFF1B527A),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: acceptedTerms.value,
                                        activeColor: const Color(0xFF08D9FF),
                                        checkColor: const Color(0xFF041326),
                                        side: const BorderSide(
                                          color: Color(0xFF8DDFFF),
                                          width: 1.5,
                                        ),
                                        onChanged: (value) {
                                          acceptedTerms.value = value ?? false;
                                        },
                                      ),
                                      const Gap(6),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 10),
                                          child: Focus(
                                            onKeyEvent: (node, event) => _handleKeyEvent(
                                              event,
                                              IntroConst.termsAndConditionsKey,
                                            ),
                                            child: Text.rich(
                                              t.intro.termsAndPolicyCaution(
                                                tap: (text) => TextSpan(
                                                  text: text,
                                                  style: const TextStyle(
                                                    color: Color(0xFF08D9FF),
                                                    decoration: TextDecoration.underline,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  recognizer: TapGestureRecognizer()
                                                    ..onTap = () async {
                                                      await UriUtils.tryLaunch(
                                                        Uri.parse(Constants.termsAndConditionsUrl),
                                                      );
                                                    },
                                                ),
                                              ),
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: Colors.white.withValues(alpha: .9),
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Gap(14),
                                // Keep the shield and its label as one centered,
                                // clearly readable action on the dark welcome screen.
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF8DDFFF),
                                    backgroundColor: const Color(0xFF0C2342).withValues(alpha: .58),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                    shape: StadiumBorder(
                                      side: BorderSide(
                                        color: const Color(0xFF08D9FF).withValues(alpha: .28),
                                      ),
                                    ),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () async {
                                    await UriUtils.tryLaunch(
                                      Uri.parse(Constants.privacyPolicyUrl),
                                    );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.shield_outlined,
                                        size: 18,
                                        color: Color(0xFF8DDFFF),
                                      ),
                                      const Gap(8),
                                      Text(
                                        t.pages.about.privacyPolicy,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: const Color(0xFFBFEFFF),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Gap(18),
                                Container(
                                  width: double.infinity,
                                  height: 1,
                                  color: const Color(0xFF1B527A),
                                ),
                                const Gap(16),
                                Text.rich(
                                  t.intro.info(
                                    tap_source: (text) => TextSpan(
                                      text: text,
                                      style: const TextStyle(
                                        color: Color(0xFF08D9FF),
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          await UriUtils.tryLaunch(Uri.parse(Constants.githubUrl));
                                        },
                                    ),
                                    tap_license: (text) => TextSpan(
                                      text: text,
                                      style: const TextStyle(
                                        color: Color(0xFF08D9FF),
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          await UriUtils.tryLaunch(Uri.parse(Constants.licenseUrl));
                                        },
                                    ),
                                  ),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: .58),
                                    height: 1.6,
                                  ),
                                ),
                                const Gap(12),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Gap(12),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF08D9FF),
                            foregroundColor: const Color(0xFF041326),
                            disabledBackgroundColor: const Color(0xFF17445C),
                            disabledForegroundColor: Colors.white54,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: isStarting.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF041326),
                                  ),
                                )
                              : const Icon(Icons.rocket_launch_rounded),
                          label: Text(
                            t.common.start,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: !acceptedTerms.value || isStarting.value
                              ? null
                              : () async {
                                  if (isStarting.value) return;
                                  isStarting.value = true;
                                  if (!ref.read(analyticsControllerProvider).requireValue) {
                                    loggy.info("disabling analytics per user request");
                                    try {
                                      await ref
                                          .read(analyticsControllerProvider.notifier)
                                          .disableAnalytics();
                                    } catch (error, stackTrace) {
                                      loggy.error(
                                        "could not disable analytics",
                                        error,
                                        stackTrace,
                                      );
                                    }
                                  }
                                  await ref
                                      .read(Preferences.introCompleted.notifier)
                                      .update(true);
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> autoSelectRegion(WidgetRef ref) async {
    try {
      final countryCode = RegionDetector.detect();
      final regionLocale = _getRegionLocale(countryCode);
      loggy.debug('Timezone Region: ${regionLocale.region} Locale: ${regionLocale.locale}');
      if (_regionChosenByUser) return;
      await _setRegion(ref, regionLocale.region);
      if (!_localeChosenByUser) {
        await ref.read(localePreferencesProvider.notifier).changeLocale(regionLocale.locale);
      }
      return;
    } catch (e) {
      loggy.warning('Could not get the local country code based on timezone', e);
    }

    try {
      final DioHttpClient client = DioHttpClient(
        timeout: const Duration(seconds: 2),
        userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0",
        debug: true,
      );
      final response = await client.get<Map<String, dynamic>>('https://api.ip.sb/geoip/');

      if (response.statusCode == 200) {
        final jsonData = response.data!;
        final regionLocale = _getRegionLocale(jsonData['country_code']?.toString() ?? "");

        loggy.debug('Region: ${regionLocale.region} Locale: ${regionLocale.locale}');
        // the answer can come seconds later, after the user picked a region
        if (_regionChosenByUser) return;
        await _setRegion(ref, regionLocale.region);
        if (!_localeChosenByUser) {
          await ref.read(localePreferencesProvider.notifier).changeLocale(regionLocale.locale);
        }
      } else {
        loggy.warning('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      loggy.warning('Could not get the local country code from ip');
    }
  }

  RegionLocale _getRegionLocale(String country) {
    switch (country.toUpperCase()) {
      case "IR":
        return RegionLocale(Region.ir, AppLocale.fa);
      case "CN":
        return RegionLocale(Region.cn, AppLocale.zhCn);
      case "RU":
        return RegionLocale(Region.ru, AppLocale.ru);
      case "AF":
        return RegionLocale(Region.af, AppLocale.fa);
      case "BR":
        return RegionLocale(Region.br, AppLocale.ptBr);
      case "TR":
        return RegionLocale(Region.tr, AppLocale.tr);
      default:
        return RegionLocale(Region.other, AppLocale.en);
    }
  }
}

class RegionLocale {
  final Region region;
  final AppLocale locale;

  RegionLocale(this.region, this.locale);
}

class RegionDetector {
  /// Returns: 'IR' | 'AF' | 'CN' | 'TR' | 'RU' | 'BR' | 'US'
  static String detect() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset.inMinutes;
    final tz = now.timeZoneName.toLowerCase().trim();

    if (offset == 210) return 'IR';

    if (offset == 270) {
      final (_, country) = _parseLocale();
      return country == 'IR' ? 'IR' : 'AF';
    }

    final fromName = _fromTzName(tz, offset);
    if (fromName != null) return fromName;

    final candidates = _candidatesForOffset(offset);
    if (candidates.isEmpty) return 'US';

    return _resolveByLocale(candidates);
  }

  static String? _fromTzName(String tz, int offset) {
    if (tz.contains('/')) {
      final city = tz.split('/').last.replaceAll(' ', '_');
      final r = _ianaCities[city];
      if (r != null) return r;
    }

    if (tz == 'irst' || tz == 'irdt' || tz.contains('iran')) return 'IR';

    if (tz == 'aft' || tz.contains('afghanistan')) return 'AF';

    if (tz == 'trt' || tz.contains('turkey') || tz.contains('istanbul')) {
      return 'TR';
    }

    if (tz.contains('china') || tz.contains('beijing')) return 'CN';
    if (tz == 'cst' && offset == 480) return 'CN';

    if (_matchesRussiaTz(tz)) return 'RU';

    if (_matchesBrazilTz(tz)) return 'BR';

    return null;
  }

  static bool _matchesRussiaTz(String tz) {
    if (tz.contains('russia') || tz.contains('moscow')) return true;

    const abbrs = {'msk', 'yekt', 'omst', 'krat', 'irkt', 'yakt', 'vlat', 'magt', 'pett', 'sakt', 'sret'};
    if (abbrs.contains(tz)) return true;

    const winKeys = [
      'ekaterinburg',
      'kaliningrad',
      'yakutsk',
      'vladivostok',
      'magadan',
      'sakhalin',
      'kamchatka',
      'astrakhan',
      'saratov',
      'volgograd',
      'altai',
      'tomsk',
      'transbaikal',
      'n. central asia',
      'north asia',
    ];
    return winKeys.any(tz.contains);
  }

  static bool _matchesBrazilTz(String tz) {
    if (tz == 'brt' || tz == 'brst') return true;
    if (tz.contains('brazil') || tz.contains('brasilia')) return true;

    const winKeys = ['e. south america', 'central brazilian', 'tocantins', 'bahia'];
    return winKeys.any(tz.contains);
  }

  static Set<String> _candidatesForOffset(int offset) {
    final c = <String>{};

    if (offset == 180) c.add('TR');

    if (offset == 480) c.add('CN');

    if (_ruOffsets.contains(offset)) c.add('RU');

    if (_brOffsets.contains(offset)) c.add('BR');

    return c;
  }

  static const _ruOffsets = {120, 180, 240, 300, 360, 420, 480, 540, 600, 660, 720};

  static const _brOffsets = {-120, -180, -240, -300};

  static String _resolveByLocale(Set<String> candidates) {
    final (lang, country) = _parseLocale();

    if (country != null && candidates.contains(country)) {
      return country;
    }

    final regionFromLang = _langToRegion[lang];
    if (regionFromLang != null && candidates.contains(regionFromLang)) {
      return regionFromLang;
    }

    return 'US';
  }

  static (String, String?) _parseLocale() {
    try {
      final parts = Platform.localeName.split(RegExp(r'[_\-.]'));
      final lang = parts.first.toLowerCase();

      String? country;
      for (final p in parts.skip(1)) {
        if (p.length == 2) {
          country = p.toUpperCase();
          break;
        }
      }

      return (lang, country);
    } catch (_) {
      return ('en', null);
    }
  }

  static const _langToRegion = <String, String>{'fa': 'IR', 'ps': 'AF', 'tr': 'TR', 'zh': 'CN', 'ru': 'RU', 'pt': 'BR'};

  static const _ianaCities = <String, String>{
    'tehran': 'IR',
    'kabul': 'AF',
    'istanbul': 'TR',
    'shanghai': 'CN',
    'chongqing': 'CN',
    'urumqi': 'CN',
    'harbin': 'CN',
    'moscow': 'RU',
    'kaliningrad': 'RU',
    'samara': 'RU',
    'yekaterinburg': 'RU',
    'omsk': 'RU',
    'novosibirsk': 'RU',
    'barnaul': 'RU',
    'tomsk': 'RU',
    'krasnoyarsk': 'RU',
    'irkutsk': 'RU',
    'chita': 'RU',
    'yakutsk': 'RU',
    'vladivostok': 'RU',
    'magadan': 'RU',
    'sakhalin': 'RU',
    'kamchatka': 'RU',
    'anadyr': 'RU',
    'volgograd': 'RU',
    'saratov': 'RU',
    'astrakhan': 'RU',
    'sao_paulo': 'BR',
    'fortaleza': 'BR',
    'recife': 'BR',
    'manaus': 'BR',
    'belem': 'BR',
    'cuiaba': 'BR',
    'bahia': 'BR',
    'rio_branco': 'BR',
    'noronha': 'BR',
    'porto_velho': 'BR',
    'campo_grande': 'BR',
  };
}
