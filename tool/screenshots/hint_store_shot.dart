// Renders the hint store screen with stubbed store products so the App Store
// Connect and Play Console review screenshots can be captured without signing
// in or reaching a live billing service. Prices mirror the configured Korean
// prices in [hintPacks].
//
// flutter build ios --simulator --debug -t tool/screenshots/hint_store_shot.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:numbering/l10n/app_translations.dart';
import 'package:numbering/screens/hints/hint_store_screen.dart';
import 'package:numbering/services/hint_purchase_service.dart';
import 'package:numbering/services/hint_service.dart';
import 'package:numbering/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hintService = await HintService().init();
  final purchaseService = HintPurchaseService(hintService: hintService);
  purchaseService.isStoreAvailable.value = true;
  purchaseService.products.assignAll([
    for (final pack in hintPacks)
      ProductDetails(
        id: pack.productId,
        title: '힌트 ${pack.hintCount}개',
        description: '게임에서 사용할 수 있는 힌트 ${pack.hintCount}개를 충전합니다.',
        price: pack.fallbackPrice,
        rawPrice: pack.plannedKrwPrice.toDouble(),
        currencyCode: 'KRW',
      ),
  ]);

  Get.put<HintService>(hintService, permanent: true);
  Get.put<HintPurchaseService>(purchaseService, permanent: true);

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: const Locale('ko', 'KR'),
      fallbackLocale: AppTranslations.fallback,
      theme: AppTheme.light,
      home: const HintStoreScreen(),
    ),
  );
}
