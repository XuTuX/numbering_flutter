# NUMBERING 디자인 시스템

> 상태: Canonical / 앱 UI의 최우선 시각 규칙
>
> 기준: 2026-07 홈 화면 개편
> 구현 토큰: `lib/theme/`

NUMBERING은 숫자 퍼즐 자체가 주인공인 조용하고 기능적인 인터페이스를 지향한다. 장난감 같은 게임 대시보드나 장식적인 3D 비주얼보다 넓은 여백, 명확한 정보 계층, 낮은 채도의 면을 사용한다.

## 1. 핵심 원칙

1. **목적이 먼저 보인다.** 한 화면에서 가장 중요한 행동은 하나만 가장 크게 배치한다.
2. **콘텐츠가 한 화면에 들어온다.** 홈은 스크롤하지 않으며 `7:3` Bento 구조를 유지한다.
3. **면은 조용하게, 글자는 선명하게.** 배경과 카드는 저채도, 텍스트와 CTA는 검정에 가깝게 쓴다.
4. **깊이는 테두리로 표현한다.** 일반 카드와 버튼에는 그림자를 사용하지 않는다.
5. **장식보다 정보다.** 3D 일러스트, 글래스모피즘, 배경 그리드, 장식용 그라데이션을 사용하지 않는다.
6. **게임 기능 색상은 예외다.** 성공, 위험, 제한 시간, 퍼즐 블록처럼 의미가 있는 색은 유지한다.

## 2. 레이아웃

### 홈

- 화면은 가로형 Bento Grid다.
- 왼쪽 메인 카드와 오른쪽 보조 영역의 비율은 `7:3`이다.
- 오른쪽에는 보조 카드 두 개를 같은 높이로 위아래 배치한다.
- 카드 간격은 `14dp`, 바깥 여백은 화면 폭의 약 `5.5%`이며 `22–48dp`로 제한한다.
- 홈 내부에는 `SingleChildScrollView`, 통계 바, 리더보드 목록을 두지 않는다.
- 헤더 왼쪽에는 `NUMBERING`만 표시한다. 설명형 태그라인은 붙이지 않는다.
- 헤더 오른쪽에는 Profile과 Settings 두 액션만 둔다.

### 일반 화면

- 콘텐츠 최대 폭을 정해 긴 가로 화면에서도 정보가 과도하게 퍼지지 않게 한다.
- 화면 제목, 핵심 정보, 주 CTA 순으로 계층을 만든다.
- 반복 목록은 스캔이 필요한 화면에서만 스크롤한다. 홈은 예외 없이 한 화면이다.
- 최소 터치 영역은 `44×44dp`다.

## 3. 컬러

| 역할 | 토큰 | HEX | 규칙 |
|---|---|---|---|
| App Background | `AppColors.background` | `#FAF9F6` | 모든 기본 Scaffold |
| Ink / Primary | `AppColors.ink` | `#171716` | 제목, 본문, 주요 CTA |
| Surface | `AppColors.surface` | `#FFFFFF` | 다이얼로그와 중립 카드 |
| Soft Surface | `AppColors.surfaceSoft` | `#F1F0EB` | 입력창, 선택 전 상태 |
| Hairline | `AppColors.hairline` | Ink 10% | 카드와 컨트롤 테두리 |
| Lavender | `AppColors.blockLilac` | `#EDE9F5` | 랭킹, 차분한 강조 |
| Sage | `AppColors.blockMint` | `#E8EFE8` | 아케이드, 긍정적 보조 기능 |
| Warm Gray | `AppColors.blockCream` | `#F2ECE2` | 기록, 중립적 강조 |

저채도 파스텔은 카드 하나당 한 색만 사용한다. 한 화면에서 서로 다른 파스텔 카드가 세 개를 넘지 않게 한다. 파랑, 빨강, 초록 등 고채도 색은 상태나 게임 규칙을 전달할 때만 사용한다.

## 4. 카드와 표면

- 기본 카드 radius: `24dp` (`AppRadius.card`)
- 기본 테두리: `1dp`, `AppColors.hairline`
- 기본 그림자: 없음 (`AppShadows.cardShadow`)
- 내부 패딩: `18–24dp`
- Surface tint 및 Material elevation: `0`
- 선택 상태는 테두리를 두껍게 하기보다 배경톤 또는 Ink 색상으로 구분한다.
- 배경 숫자 모티프처럼 콘텐츠와 직접 연결된 추상 장식은 최대 `4%` opacity로 허용한다.

금지 항목:

- 하드 섀도와 검정 오프셋 그림자
- 장식용 glow
- 카드 안의 불필요한 아이콘/일러스트
- 한 카드 안에서 여러 포인트 컬러 혼용
- 반투명 유리 효과와 blur panel

## 5. 타이포그래피

시스템 기본 산세리프를 사용하고, 크기보다 굵기와 여백으로 계층을 만든다.

| 역할 | 크기 | 굵기 | 규칙 |
|---|---:|---:|---|
| Hero | `32–40` | `800–900` | 핵심 행동 카드에만 사용 |
| Screen title | `20–24` | `800` | 짧고 직접적인 제목 |
| Card title | `20–28` | `800` | 최대 두 줄 |
| Body | `14–16` | `500–600` | 긴 설명 최소화 |
| Label | `10–12` | `700–800` | 영문 대문자, 자간 `0.8–1.4` |
| Metric | `12–18` | `600–800` | 숫자를 먼저 읽을 수 있게 구성 |

- 큰 제목은 자간 `-0.5`에서 `-1.6`을 사용한다.
- 라벨은 짧은 영문 대문자로 표현할 수 있다.
- 버튼 문구는 동사로 시작한다: `Start Puzzle`, `View Ranking`, `Continue`.
- 브랜드 헤더에는 이름 외 부제나 마케팅 문구를 추가하지 않는다.

## 6. 버튼과 아이콘

### Primary button

- 배경 `AppColors.primary`, 글자 `AppColors.onPrimary`
- 높이 `46–52dp`
- radius `14dp`
- elevation과 그림자 없음
- 한 화면에 한 개를 원칙으로 한다.

### Secondary control

- 흰색 또는 Soft Surface 배경
- Hairline 테두리
- 텍스트와 아이콘은 Ink
- 원형 헤더 버튼은 `42–44dp`

아이콘은 기능을 설명할 때만 사용한다. 카드 제목 옆의 장식용 아이콘은 넣지 않는다. 화살표는 이동 가능성을 나타낼 때 허용한다.

## 7. 모션

- 기본 전환: `150–220ms`, `easeOutCubic`
- 눌림 피드백: scale `0.96–0.98`, 약 `100ms`
- 장시간 반복 애니메이션과 장식용 부유 효과는 사용하지 않는다.
- 점수 획득, 성공, 시간 임박처럼 게임 상태 피드백에는 더 강한 모션을 허용한다.

## 8. 화면별 적용

| 화면 | 적용 규칙 |
|---|---|
| Home | 7:3 Bento, 무스크롤, 메인 CTA 하나 |
| Arcade | 저채도 지역 카드, 검정 진행 표시, 단일 Continue CTA |
| Ranking | TOP 3만 서로 다른 파스텔, 나머지는 중립 Surface |
| Profile | Off-white 배경, 무그림자 아바타, 간결한 메뉴 행 |
| Settings | 중립 Surface 그룹, Hairline 구분선, 검정 활성 상태 |
| Dialog | 흰색 Surface, 24 radius, Hairline, 무그림자 |
| Gameplay | 레이아웃은 미니멀하게 유지하되 블록/성공/위험 기능 색상 허용 |

## 9. 구현 체크리스트

- [ ] `AppColors`의 semantic token을 사용했는가?
- [ ] 카드 radius가 기본적으로 24dp인가?
- [ ] 일반 UI에서 shadow/glow/gradient를 제거했는가?
- [ ] 화면의 주요 행동이 하나로 명확한가?
- [ ] 카드마다 포인트 컬러가 하나 이하인가?
- [ ] 홈에 스크롤이나 하단 통계 바가 없는가?
- [ ] 가로 667×375에서도 overflow가 없는가?
- [ ] 기능 색상과 장식 색상을 구분했는가?

## 10. Flutter 기준 예시

```dart
Material(
  color: AppColors.blockLilac,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.card),
    side: const BorderSide(color: AppColors.hairline),
  ),
  clipBehavior: Clip.antiAlias,
  child: InkWell(
    onTap: onTap,
    child: const Padding(
      padding: EdgeInsets.all(AppSpacing.xxl),
      child: CardContent(),
    ),
  ),
)
```

새 UI는 이 문서를 먼저 따르고, 기존 화면과 충돌할 경우 기존 화면을 이 시스템으로 마이그레이션한다.
