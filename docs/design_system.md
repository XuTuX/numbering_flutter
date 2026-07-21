# NUMBERING (NUMBERING) 네오 브루탈리즘(Neo-brutalism) 디자인 가이드

이 문서는 **NUMBERING (NUMBERING)** 프로젝트에서 사용된 **네오 브루탈리즘(Neo-brutalism)** 디자인 스타일의 핵심 규칙과 구현 코드를 정의합니다. 이 스타일은 복고풍(Retro)의 장난스럽고 현대적인 고대비(High-contrast) 비주얼이 특징입니다.

---

## 1. 디자인 핵심 컨셉 (Core Concept)

네오 브루탈리즘 디자인의 핵심은 **"솔직함과 극단적인 대비"**입니다. 부드러운 그라데이션이나 은은한 그림자 대신, 명확한 경계선과 강렬한 평면 그림자를 사용하여 시각적 임팩트를 줍니다.

1. **굵고 명확한 테두리 (Thick Outlines)**: 모든 카드, 버튼, 입력창 등에 굵은 검은색 테두리를 적용합니다.
2. **평면 하드 섀도우 (Hard Flat Shadows)**: 흐림 효과(Blur)가 없는 100% 불투명도의 검은색 그림자를 오프셋으로 주어 입체감을 표현합니다.
3. **고대비 컬러 & 파스텔 조합**: 기본 배경은 밝고 깔끔하게 유지하되, 주요 액션 버튼이나 포인트 요소에는 채도가 높은 원색이나 선명한 파스텔톤을 사용합니다.
4. **볼드한 타이포그래피 (Chunky Typography)**: 아주 두껍고 꽉 찬 느낌의 서체(예: `Black Han Sans`)를 메인 타이틀과 버튼에 사용하여 시각적 무게감을 맞춥니다.
5. **격자 패턴 (Grid Background)**: 기술적이고 정교한 느낌을 주기 위해 얇고 투명한 그리드 배경과 랜덤 블록 포인트를 활용합니다.

---

## 2. 컬러 팔레트 (Color Palette)

### 기본 및 텍스트 컬러
*   **Charcoal Black (주요 테두리 및 텍스트)**: `#1A1A1A` (`Color(0xFF1A1A1A)`)
*   **Scaffold Background (전체 배경)**: `#F8F9FA` (`Color(0xFFF8F9FA)`)
*   **Card Background (카드 배경)**: `#FFFFFF` (`Color(0xFFFFFFFF)`)

### 브랜드 / 액션 포인트 컬러
*   **Azure Blue (플레이 / 메인 버튼)**: `#0095FF` (`Color(0xFF0095FF)`)
*   **Amber Gold (오늘의 퍼즐 / 랭킹)**: `#F59E0B` (`Color(0xFFF59E0B)`)
*   **Mint Green (성공 / 긍정 상태)**: `#10B981` (`Color(0xFF10B981)`)
*   **Coral Red (경고 / 포인트)**: `#FF7F7F` (`Color(0xFFFF7F7F)`)
*   **Violet Purple (시즌 챌린저)**: `#C4A3FF` (`Color(0xFFC4A3FF)`)

---

## 3. 핵심 디자인 요소 및 Flutter 구현 코드

### 1) 네오 브루탈리즘 카드 (Card Container)
두꺼운 테두리와 흐림(Blur)이 없는 하드 그림자가 특징입니다.

```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: const Color(0xFF1A1A1A), width: 2.0),
    boxShadow: const [
      BoxShadow(
        color: Color(0xFF1A1A1A),
        offset: Offset(3, 3), // 오른쪽 아래로 치우친 그림자
        blurRadius: 0,        // 흐림 효과 없음 (Hard Shadow)
      ),
    ],
  ),
  padding: const EdgeInsets.all(20),
  child: const Column(
    children: [ ... ],
  ),
)
```

### 2) 네오 브루탈리즘 버튼 (Button)
눌리는 느낌을 강조하기 위해 스케일 애니메이션과 테두리/그림자를 조합합니다.

```dart
Container(
  height: 56,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    boxShadow: const [
      BoxShadow(
        color: Color(0xFF1A1A1A),
        offset: Offset(3, 3),
        blurRadius: 0,
      ),
    ],
  ),
  child: ElevatedButton(
    onPressed: () {},
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0095FF), // Azure Blue
      foregroundColor: Colors.white,
      elevation: 0, // 기본 머티리얼 입체감 제거
      side: const BorderSide(color: Color(0xFF1A1A1A), width: 2.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    child: Text(
      '게임 시작',
      style: GoogleFonts.blackHanSans(fontSize: 20),
    ),
  ),
)
```

### 3) 탭 바 (Tab Navigation)
라운드 처리된 네오 브루탈리즘 박스 안에 선택된 탭만 액센트 컬러 배경을 채웁니다.

```dart
Container(
  padding: const EdgeInsets.all(4),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
    boxShadow: const [
      BoxShadow(
        color: Color(0xFF1A1A1A),
        offset: Offset(2, 2),
        blurRadius: 0,
      ),
    ],
  ),
  child: Row(
    children: [
      // 활성화된 탭 예시
      Expanded(
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0095FF), // 활성화 탭 배경
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            '플레이',
            style: GoogleFonts.blackHanSans(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
      // 비활성화된 탭 예시
      Expanded(
        child: Container(
          height: 44,
          alignment: Alignment.center,
          child: Text(
            '오늘의 퍼즐',
            style: GoogleFonts.blackHanSans(color: const Color(0xFF1A1A1A).withOpacity(0.32), fontSize: 14),
          ),
        ),
      ),
    ],
  ),
)
```

### 4) 배경 격자 패턴 (Background Grid Painter)
배경에 40px 크기의 미세한 격자를 그리고, 파스텔톤 블록을 무작위로 옅게 채워 레트로 감성을 더합니다.

```dart
class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A).withOpacity(0.035) // 아주 투명한 격자선
      ..strokeWidth = 1;

    const double gridSize = 40.0;

    // 격자 그리기
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 포인트 파스텔 블록 채우기 (예시로 고정 좌표 한 개)
    final cellPaint = Paint()
      ..color = const Color(0xFFF9D86D).withOpacity(0.08) // 파스텔 옐로우 8% 투명도
      ..style = PaintingStyle.fill;
      
    final rect = Rect.fromLTWH(40 * 2 + 4, 40 * 3 + 4, 32, 32);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      cellPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

---

## 4. 타이포그래피 계층 구조 (Typography Hierarchy)

*   **Display (헤드라인 / 대형 스코어)**: 
    *   폰트: `Black Han Sans`
    *   크기: `48` ~ `64`
    *   특징: 아주 거대하고 꽉 찬 볼드 텍스트. 자간(Letter Spacing)을 살짝 줄여서(`-1.0` ~ `-2.0`) 응집력 있게 표현.
*   **Headline/Title (스크린 & 카드 제목)**:
    *   폰트: `Black Han Sans`
    *   크기: `24` ~ `32`
*   **Body (본문 및 상세 설명)**:
    *   폰트: `Noto Sans` 혹은 시스템 기본 샌드세리프
    *   두께: `FontWeight.w600` (Semi-bold) 이상을 주로 사용하여 테두리 선과의 시각적 균형을 유지.
    *   크기: `14` ~ `16`
*   **Labels (라벨 및 메타 데이터)**:
    *   폰트: 영문 대문자 위주
    *   크기: `12`
    *   특징: 대문자 가독성을 위해 자간을 넓게 설정 (`letterSpacing: 1.5`).
