import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static const String legacySupabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseKey => supabasePublishableKey.isNotEmpty
      ? supabasePublishableKey
      : legacySupabaseAnonKey;

  static const String termsOfServiceUrl = 'https://www.neoreo.org/terms';
  static const String privacyPolicyUrl =
      'https://www.neoreo.org/privacy-policy';

  static bool get isWeb => kIsWeb;
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

  static void validateRequired() {
    final missing = <String>[
      if (supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (supabaseKey.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
    ];

    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required values: ${missing.join(', ')}. '
        'Login is required, so SUPABASE_URL and '
        'SUPABASE_PUBLISHABLE_KEY must be provided.',
      );
    }
  }
}
