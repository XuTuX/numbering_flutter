import 'package:get/get.dart';

enum RankingPeriod {
  daily,
}

extension RankingPeriodX on RankingPeriod {
  String get tabLabel => 'TODAY';

  String get topPlayersLabel => '오늘의 퍼즐 TOP 20'.tr;

  String get emptyMessage => '오늘의 퍼즐 기록이 아직 없어요'.tr;

  String get loggedInEmptyMessage => '오늘의 퍼즐에 도전해 보세요'.tr;

  String get guestEmptyMessage => '로그인하고 오늘의 퍼즐 랭킹에 도전하세요'.tr;

  String get statusLabel => 'KST DAILY';
}
