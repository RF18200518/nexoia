import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static const _prefix = 'analytics_';
  bool _enabled = true;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('${_prefix}enabled') ?? true;
  }

  Future<void> setEnabled(bool v) async {
    _enabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefix}enabled', v);
  }

  bool get enabled => _enabled;

  void trackEvent(String name, {Map<String, dynamic>? params}) {
    if (!_enabled) return;
    if (kDebugMode) {
      debugPrint('📊 Analytics: $name ${params ?? ''}');
    }
    // TODO: Enviar a backend / Firebase Analytics cuando estén configurados
    // FirebaseAnalytics.instance.logEvent(name: name, parameters: params);
  }

  void trackScreenView(String screenName) {
    trackEvent('screen_view', params: {'screen_name': screenName});
  }

  void trackAction(String action, {Map<String, dynamic>? params}) {
    trackEvent('action_$action', params: params);
  }

  void trackError(String error, {String? screen}) {
    trackEvent('error', params: {'error': error, 'screen': screen});
  }

  Future<void> incrementCounter(String key) async {
    if (!_enabled) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('${_prefix}counter_$key') ?? 0;
    await prefs.setInt('${_prefix}counter_$key', current + 1);
  }

  Future<int> getCounter(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${_prefix}counter_$key') ?? 0;
  }
}