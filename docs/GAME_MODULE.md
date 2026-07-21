# 새 게임 연결 방법

이 템플릿은 홈, 로그인, 랭킹, 일일 도전, 설정, 광고, 오디오와 디자인을 그대로
유지합니다. 새 게임을 추가할 때는 공통 화면을 수정하지 않고 게임 모듈만
구현합니다.

## 1. GameModule 구현

```dart
import 'package:flutter/material.dart';
import 'package:hexor/game/game_module.dart';

class MyGameModule extends GameModule {
  const MyGameModule();

  @override
  String get id => 'my_game';

  @override
  String get title => 'MY GAME';

  @override
  Widget build(
    BuildContext context,
    GameSessionConfig session,
    GameCallbacks callbacks,
  ) {
    return MyGame(
      seed: session.seed,
      onScoreChanged: callbacks.onScoreChanged,
      onGameOver: (score) {
        callbacks.onFinished(GameResult(score: score));
      },
      onExit: callbacks.onExit,
    );
  }
}
```

## 2. 모듈 등록

`lib/game/game_registry.dart`에서 게임 파일을 import하고 다음 한 줄만 바꿉니다.

```dart
static const GameModule? active = MyGameModule();
```

이후 기존 홈의 PLAY 버튼, 튜토리얼 진입, 일일 도전 진입은 모두 새 게임 모듈을
사용합니다.

## 콜백

- `onScoreChanged`: 플레이 중 현재 점수와 로컬 최고 점수를 갱신합니다.
- `onFinished`: 공통 결과 화면을 표시합니다.
- `onExit`: 기존 홈으로 돌아갑니다.

온라인 점수 검증 방식은 게임 규칙마다 다르므로 새 게임을 추가할 때 해당 게임의
서버 검증 로직만 모듈과 함께 구현합니다. 기존 홈이나 랭킹 UI는 변경하지 않습니다.
