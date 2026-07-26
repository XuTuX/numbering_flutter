import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:numbering/services/hint_purchase_service.dart';
import 'package:numbering/services/hint_service.dart';
import 'package:numbering/theme/app_colors.dart';
import 'package:numbering/theme/app_radius.dart';

class HintStoreScreen extends StatelessWidget {
  const HintStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final purchaseService = Get.find<HintPurchaseService>();
    final hintService = Get.find<HintService>();
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isLandscape ? 24 : 20,
                12,
                isLandscape ? 24 : 20,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StoreHeader(hintService: hintService),
                  SizedBox(height: isLandscape ? 12 : 22),
                  Expanded(
                    child: Obx(() {
                      if (purchaseService.isLoadingProducts.value &&
                          purchaseService.products.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.ink,
                            strokeWidth: 2.5,
                          ),
                        );
                      }

                      final cards = [
                        for (final pack in hintPacks)
                          _HintPackCard(
                            pack: pack,
                            isLandscape: isLandscape,
                            storePrice: purchaseService
                                .productFor(pack.productId)
                                ?.price,
                            isBuying: purchaseService.buyingProductId.value ==
                                pack.productId,
                            isEnabled: purchaseService.buyingProductId.value ==
                                    null &&
                                purchaseService.productFor(pack.productId) !=
                                    null,
                            onBuy: () => purchaseService.buy(pack),
                          ),
                      ];

                      if (!isLandscape) {
                        return Column(
                          children: [
                            Expanded(
                              child: ListView.separated(
                                itemCount: cards.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, index) => cards[index],
                              ),
                            ),
                            _StoreStatus(purchaseService: purchaseService),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxHeight: 560),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (var index = 0;
                                        index < cards.length;
                                        index++) ...[
                                      Expanded(child: cards[index]),
                                      if (index != cards.length - 1)
                                        const SizedBox(width: 12),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          _StoreStatus(purchaseService: purchaseService),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({required this.hintService});

  final HintService hintService;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          key: const ValueKey('hint-store-back'),
          tooltip: '뒤로',
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            '힌트 상점',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 25,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
        ),
        Obx(
          () => Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lightbulb_rounded,
                  size: 19,
                  color: AppColors.yellow,
                ),
                const SizedBox(width: 6),
                Text(
                  '${hintService.hints.value}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HintPackCard extends StatelessWidget {
  const _HintPackCard({
    required this.pack,
    required this.isLandscape,
    required this.storePrice,
    required this.isBuying,
    required this.isEnabled,
    required this.onBuy,
  });

  final HintPack pack;
  final bool isLandscape;
  final String? storePrice;
  final bool isBuying;
  final bool isEnabled;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final isFeatured = pack.hintCount == 50;
    return Container(
      constraints: const BoxConstraints(minHeight: 130),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isFeatured ? AppColors.blockLilac : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isFeatured
              ? AppColors.ink.withValues(alpha: 0.3)
              : AppColors.borderLight,
          width: isFeatured ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lightbulb_rounded,
                    size: 28,
                    color: AppColors.yellow,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${pack.hintCount}개',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 28,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isLandscape) const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              key: ValueKey('buy-${pack.productId}'),
              onPressed: isEnabled ? onBuy : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                disabledBackgroundColor: AppColors.ink.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: isBuying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      storePrice ?? pack.fallbackPrice,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreStatus extends StatelessWidget {
  const _StoreStatus({required this.purchaseService});

  final HintPurchaseService purchaseService;

  @override
  Widget build(BuildContext context) {
    final error = purchaseService.errorMessage.value;
    final status = purchaseService.statusMessage.value;
    final message = error ?? status;
    if (message == null) {
      return const SizedBox(height: 8);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            error == null
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            size: 16,
            color: error == null ? AppColors.green : AppColors.danger,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    error == null ? AppColors.textSecondary : AppColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: purchaseService.reloadProducts,
              child: const Text(
                '다시 시도',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
