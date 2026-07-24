import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:numbering/config/app_config.dart';
import 'package:numbering/services/hint_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HintPack {
  const HintPack({
    required this.productId,
    required this.hintCount,
    required this.plannedKrwPrice,
    required this.label,
  });

  final String productId;
  final int hintCount;
  final int plannedKrwPrice;
  final String label;

  String get fallbackPrice => '₩${_formatNumber(plannedKrwPrice)}';
}

const hintPacks = <HintPack>[
  HintPack(
    productId: 'numbering_hints_11',
    hintCount: 11,
    plannedKrwPrice: 1100,
    label: '가볍게 충전',
  ),
  HintPack(
    productId: 'numbering_hints_50',
    hintCount: 50,
    plannedKrwPrice: 3300,
    label: '인기',
  ),
  HintPack(
    productId: 'numbering_hints_100',
    hintCount: 100,
    plannedKrwPrice: 5500,
    label: '최대 보너스',
  ),
];

class HintPurchaseService extends GetxService {
  HintPurchaseService({
    required HintService hintService,
    SupabaseClient? supabase,
    InAppPurchase? store,
  })  : _hintService = hintService,
        _supabase = supabase,
        _store = store ?? InAppPurchase.instance;

  final HintService _hintService;
  final SupabaseClient? _supabase;
  final InAppPurchase _store;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Future<void> _purchaseQueue = Future<void>.value();

  final products = <ProductDetails>[].obs;
  final isStoreAvailable = false.obs;
  final isLoadingProducts = false.obs;
  final buyingProductId = RxnString();
  final statusMessage = RxnString();
  final errorMessage = RxnString();

  bool get isSupportedPlatform => AppConfig.isAndroid || AppConfig.isIos;

  Future<HintPurchaseService> init() async {
    if (!isSupportedPlatform) return this;

    _purchaseSubscription = _store.purchaseStream.listen(
      _enqueuePurchaseUpdates,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Purchase stream failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        errorMessage.value = '결제 정보를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
        buyingProductId.value = null;
      },
    );
    await reloadProducts();
    return this;
  }

  ProductDetails? productFor(String productId) {
    for (final product in products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  Future<void> reloadProducts() async {
    if (!isSupportedPlatform || isLoadingProducts.value) return;
    isLoadingProducts.value = true;
    errorMessage.value = null;
    try {
      final available = await _store.isAvailable();
      isStoreAvailable.value = available;
      if (!available) {
        products.clear();
        errorMessage.value = '현재 스토어에 연결할 수 없습니다.';
        return;
      }

      final response = await _store.queryProductDetails(
        hintPacks.map((pack) => pack.productId).toSet(),
      );
      if (response.error != null) {
        products.clear();
        errorMessage.value = '상품 정보를 불러오지 못했습니다.';
        debugPrint('Product query failed: ${response.error}');
        return;
      }

      final byId = {
        for (final product in response.productDetails) product.id: product
      };
      products.assignAll([
        for (final pack in hintPacks)
          if (byId[pack.productId] != null) byId[pack.productId]!,
      ]);
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
            'Store products not configured: ${response.notFoundIDs.join(', ')}');
        errorMessage.value = '스토어 상품 등록 상태를 확인해 주세요.';
      }
    } catch (error, stackTrace) {
      debugPrint('Store initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      isStoreAvailable.value = false;
      products.clear();
      errorMessage.value = '현재 스토어에 연결할 수 없습니다.';
    } finally {
      isLoadingProducts.value = false;
    }
  }

  Future<bool> buy(HintPack pack) async {
    statusMessage.value = null;
    errorMessage.value = null;
    final user = _supabase?.auth.currentUser;
    if (user == null) {
      errorMessage.value = '힌트를 구매하려면 로그인이 필요합니다.';
      return false;
    }
    if (buyingProductId.value != null) return false;

    var product = productFor(pack.productId);
    if (product == null) {
      await reloadProducts();
      product = productFor(pack.productId);
    }
    if (product == null) {
      errorMessage.value = '이 상품은 아직 스토어에 등록되지 않았습니다.';
      return false;
    }

    buyingProductId.value = pack.productId;
    try {
      final started = await _store.buyConsumable(
        purchaseParam: PurchaseParam(
          productDetails: product,
          // Supabase user ids are opaque UUIDs. StoreKit 2 records this as the
          // appAccountToken and Play Billing as obfuscatedExternalAccountId.
          applicationUserName: user.id,
        ),
        // Android must keep the token unconsumed until the backend has
        // verified and idempotently granted it. iOS transaction completion is
        // deferred by completePurchase below.
        autoConsume: !AppConfig.isAndroid,
      );
      if (!started) {
        buyingProductId.value = null;
        errorMessage.value = '결제 창을 열지 못했습니다. 다시 시도해 주세요.';
      }
      return started;
    } catch (error, stackTrace) {
      debugPrint('Purchase launch failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      buyingProductId.value = null;
      errorMessage.value = '결제를 시작하지 못했습니다.';
      return false;
    }
  }

  void _enqueuePurchaseUpdates(List<PurchaseDetails> purchases) {
    _purchaseQueue = _purchaseQueue.then((_) async {
      for (final purchase in purchases) {
        await _handlePurchase(purchase);
      }
    });
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        buyingProductId.value = purchase.productID;
        statusMessage.value = '결제 승인을 기다리고 있습니다.';
        return;
      case PurchaseStatus.canceled:
        buyingProductId.value = null;
        statusMessage.value = '결제가 취소되었습니다.';
        return;
      case PurchaseStatus.error:
        buyingProductId.value = null;
        errorMessage.value = purchase.error?.message ?? '결제 처리 중 오류가 발생했습니다.';
        return;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        await _verifyAndDeliver(purchase);
        return;
    }
  }

  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    final pack = hintPacks
        .where((item) => item.productId == purchase.productID)
        .firstOrNull;
    if (client == null || user == null || pack == null) {
      buyingProductId.value = null;
      errorMessage.value = '로그인 상태와 구매 상품을 확인해 주세요.';
      return;
    }

    buyingProductId.value = purchase.productID;
    statusMessage.value = '구매를 확인하고 있습니다.';
    errorMessage.value = null;
    try {
      final response = await client.functions.invoke(
        'verify-hint-purchase',
        body: <String, Object?>{
          'platform': AppConfig.isIos ? 'apple' : 'google',
          'productId': purchase.productID,
          'purchaseId': purchase.purchaseID ?? '',
          'verificationData': purchase.verificationData.serverVerificationData,
        },
      );
      final result = _asMap(response.data);
      if (result['ok'] != true) {
        throw StateError('Purchase was not verified');
      }
      if (client.auth.currentUser?.id != user.id) {
        throw StateError('Account changed during purchase');
      }

      if (AppConfig.isAndroid) {
        final addition =
            _store.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        final consumed = await addition.consumePurchase(purchase);
        if (consumed.responseCode != BillingResponse.ok) {
          throw StateError('Google Play consumption failed');
        }
      }

      final balance = _asInt(result['hint_count']);
      if (balance != null) {
        await _hintService.applyVerifiedBalance(balance);
      } else {
        await _hintService.refreshFromServer();
      }

      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
      buyingProductId.value = null;
      statusMessage.value = result['already_granted'] == true
          ? '이미 지급된 구매입니다. 잔액을 새로고침했습니다.'
          : '힌트 ${pack.hintCount}개가 지급되었습니다!';
    } catch (error, stackTrace) {
      debugPrint('Purchase verification failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      buyingProductId.value = null;
      errorMessage.value = '구매 확인에 실패했습니다. 결제 내역은 보존되며 자동으로 다시 확인됩니다.';
    }
  }

  @override
  void onClose() {
    _purchaseSubscription?.cancel();
    super.onClose();
  }
}

Map<String, Object?> _asMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String _formatNumber(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}
