import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk mengambil konfigurasi app dari backend
/// Contoh: useDiscountPrice, dll.
class AppConfigService {
  static final AppConfigService _instance = AppConfigService._internal();
  factory AppConfigService() => _instance;
  AppConfigService._internal();

  final String? _baseUrl = dotenv.env['BASE_URL'];
  
  // Cache config di memory
  Map<String, dynamic>? _cachedConfig;
  DateTime? _lastFetch;
  static const _cacheDuration = Duration(minutes: 5);

  /// Fetch config dari backend
  Future<Map<String, dynamic>> fetchConfig({bool forceRefresh = false}) async {
    // Return cache if valid
    if (!forceRefresh && _cachedConfig != null && _lastFetch != null) {
      final cacheAge = DateTime.now().difference(_lastFetch!);
      if (cacheAge < _cacheDuration) {
        debugPrint('📦 Using cached app config');
        return _cachedConfig!;
      }
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/app-config'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          _cachedConfig = jsonData['data'] as Map<String, dynamic>;
          _lastFetch = DateTime.now();
          
          // Save to local storage as backup
          await _saveToLocal(_cachedConfig!);
          
          debugPrint('✅ Fetched app config from backend: $_cachedConfig');
          return _cachedConfig!;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to fetch app config: $e');
    }

    // Fallback to local storage or defaults
    return await _getFromLocalOrDefaults();
  }

  /// Get useDiscountPrice setting
  Future<bool> getUseDiscountPrice() async {
    final config = await fetchConfig();
    return config['useDiscountPrice'] ?? true;
  }

  /// Synchronous getter for use in build methods (uses cached value)
  bool get useDiscountPrice {
    return _cachedConfig?['useDiscountPrice'] ?? true;
  }

  /// Save config to local storage
  Future<void> _saveToLocal(Map<String, dynamic> config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_config', json.encode(config));
    } catch (e) {
      debugPrint('Failed to save config to local: $e');
    }
  }

  /// Get config from local storage or return defaults
  Future<Map<String, dynamic>> _getFromLocalOrDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('app_config');
      if (stored != null) {
        _cachedConfig = json.decode(stored) as Map<String, dynamic>;
        debugPrint('📱 Using local app config: $_cachedConfig');
        return _cachedConfig!;
      }
    } catch (e) {
      debugPrint('Failed to get local config: $e');
    }

    // Return defaults
    _cachedConfig = {
      'useDiscountPrice': true,
    };
    return _cachedConfig!;
  }

  /// Initialize config on app startup
  Future<void> initialize() async {
    await fetchConfig();
  }

  /// Clear cache
  void clearCache() {
    _cachedConfig = null;
    _lastFetch = null;
  }
}
