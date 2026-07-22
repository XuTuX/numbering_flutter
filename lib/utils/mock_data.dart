
class MockData {
  static List<Map<String, dynamic>> getScores(String? myId, String? myNickname, int? myScore) {
    final List<Map<String, dynamic>> list = [
      {
        'user_id': 'mock-1',
        'profiles': {'nickname': '민준'},
        'score': 12500,
      },
      {
        'user_id': 'mock-2',
        'profiles': {'nickname': '서연'},
        'score': 9800,
      },
      {
        'user_id': 'mock-3',
        'profiles': {'nickname': '지우'},
        'score': 8500,
      },
      {
        'user_id': 'mock-4',
        'profiles': {'nickname': '하루'},
        'score': 7200,
      },
      {
        'user_id': 'mock-5',
        'profiles': {'nickname': '유나'},
        'score': 6100,
      },
      {
        'user_id': 'mock-6',
        'profiles': {'nickname': 'Alex'},
        'score': 5000,
      },
      {
        'user_id': 'mock-7',
        'profiles': {'nickname': 'Chloe'},
        'score': 4200,
      },
      {
        'user_id': 'mock-8',
        'profiles': {'nickname': 'Daniel'},
        'score': 3500,
      },
    ];

    if (myId != null && myScore != null) {
      list.removeWhere((item) => item['user_id'] == myId);
      list.add({
        'user_id': myId,
        'profiles': {'nickname': myNickname ?? 'Player (You)'},
        'score': myScore,
      });
    }

    // Sort descending
    list.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    // Assign rank
    for (int i = 0; i < list.length; i++) {
      list[i]['rank'] = i + 1;
    }

    return list;
  }
}
