import 'package:get/get.dart';

enum RankingPeriod {
  daily,
  weekly,
  allTime,
}

extension RankingPeriodX on RankingPeriod {
  String get tabLabel => switch (this) {
        RankingPeriod.daily => 'TODAY',
        RankingPeriod.weekly => 'WEEKLY',
        RankingPeriod.allTime => '명예의 전당'.tr,
      };

  String get topPlayersLabel => switch (this) {
        RankingPeriod.daily => '오늘의 퍼즐 TOP 20'.tr,
        RankingPeriod.weekly => 'WEEKLY TOP 20',
        RankingPeriod.allTime => '명예의 전당 TOP 20'.tr,
      };

  String get emptyMessage => switch (this) {
        RankingPeriod.daily => '오늘의 퍼즐 기록이 아직 없어요'.tr,
        RankingPeriod.weekly => 'NO WEEKLY DATA YET',
        RankingPeriod.allTime => '아직 기록이 없습니다'.tr,
      };

  String get loggedInEmptyMessage => switch (this) {
        RankingPeriod.daily => '오늘의 퍼즐에 도전해 보세요'.tr,
        RankingPeriod.weekly => 'PLAY THIS WEEK TO JOIN',
        RankingPeriod.allTime => '내 기록을 남겨보세요'.tr,
      };

  String get guestEmptyMessage => switch (this) {
        RankingPeriod.daily => '로그인하고 오늘의 퍼즐 랭킹에 도전하세요'.tr,
        RankingPeriod.weekly => 'LOG IN TO JOIN THE WEEKLY RANKING',
        RankingPeriod.allTime => '로그인하고 랭킹에 도전하세요'.tr,
      };

  String get statusLabel => switch (this) {
        RankingPeriod.daily => 'KST DAILY',
        RankingPeriod.weekly => 'MON 00:00 RESET',
        RankingPeriod.allTime => 'HALL OF FAME',
      };
}
