import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static const String termsOfServiceUrl = 'https://www.neoreo.org/terms';
  static const String privacyPolicyUrl =
      'https://www.neoreo.org/privacy-policy';

  static bool get isWeb => kIsWeb;
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get supportsAds => isAndroid || isIos;
  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static void validateRequired() {
    if (supabaseUrl.isEmpty && supabaseAnonKey.isEmpty) return;

    final missing = <String>[
      if (supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
    ];

    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required values: ${missing.join(', ')}. '
        'Provide both SUPABASE_URL and SUPABASE_ANON_KEY, or omit both for '
        'offline guest mode.',
      );
    }
  }
}
