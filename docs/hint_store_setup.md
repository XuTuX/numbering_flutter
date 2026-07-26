# 힌트 상점 설정

앱에는 소모성 힌트 상품 3개가 구현되어 있다. UI에 표시되는 상품 가격은
StoreKit 또는 Google Play Billing에서 가져온다. 따라서 지역별 가격의 기준은
각 스토어에 등록된 가격이다.

| 상품 ID | 유형 | 힌트 | 한국 가격 |
| --- | --- | ---: | ---: |
| `numbering_hints_11` | 소모성 / 일회성 상품 | 11 | ₩1,100 |
| `numbering_hints_50` | 소모성 / 일회성 상품 | 50 | ₩3,300 |
| `numbering_hints_100` | 소모성 / 일회성 상품 | 100 | ₩5,500 |

App Store Connect와 Google Play Console에 위 상품 ID를 정확히 동일하게
등록한다. 한국어 표시 이름은 `힌트 11개`, `힌트 50개`, `힌트 100개`를
권장한다. Apple에서는 세 상품을 모두 소모성 상품으로, Google에서는
일회성 소모 상품으로 설정한다. 앱에 별도의 가격을 하드코딩하지 않는다.
각 스토어에 한국 가격을 설정하고 다른 지역의 가격은 스토어가 계산하도록 한다.

## App Store Connect 상품 등록

**수익화 > 앱 내 구입 > 생성**에서 **소모성 상품**을 선택하고 아래 값을 그대로
입력한다. 상품 ID는 저장 후 수정할 수 없고, 삭제해도 같은 앱에서 재사용할 수
없으므로 저장 전에 반드시 확인한다.

| 항목 | `numbering_hints_11` | `numbering_hints_50` | `numbering_hints_100` |
| --- | --- | --- | --- |
| 참조 이름 (내부용, 64자 이내) | `Numbering Hints 11` | `Numbering Hints 50` | `Numbering Hints 100` |
| 제품 ID (수정 불가) | `numbering_hints_11` | `numbering_hints_50` | `numbering_hints_100` |
| 유형 | 소모성 상품 | 소모성 상품 | 소모성 상품 |
| 가격 (한국 기준) | ₩1,100 | ₩3,300 | ₩5,500 |

현지화는 **한국어**만 추가한다. 표시 이름은 2~30자, 설명은 45자 이내여야 한다.

| 현지화 항목 | `numbering_hints_11` | `numbering_hints_50` | `numbering_hints_100` |
| --- | --- | --- | --- |
| 표시 이름 | `힌트 11개` | `힌트 50개` | `힌트 100개` |
| 설명 | `게임에서 사용할 수 있는 힌트 11개를 충전합니다.` | `게임에서 사용할 수 있는 힌트 50개를 충전합니다.` | `게임에서 사용할 수 있는 힌트 100개를 충전합니다.` |

판매 지역은 전체 국가 및 지역을 선택한 상태로 둔다. 그래야 앱이 판매되는 모든
지역에서 현지화된 가격을 받아온다. 심사에 제출하는 앱 버전에 상품 3개를 모두
연결하지 않으면 상품이 거부 상태로 반환된다.

**앱 심사 스크린샷**은 상품마다 필수이며 심사에만 사용된다. 힌트 상점 화면에서
팩 3개가 모두 보이는 이미지 하나를 세 상품에 각각 올리면 된다. 로그인이나 실제
스토어 연결 없이 캡처할 수 있도록 `tool/screenshots/hint_store_shot.dart`
진입점을 두었다.

```bash
flutter build ios --simulator --debug -t tool/screenshots/hint_store_shot.dart
xcrun simctl install <udid> build/ios/iphonesimulator/Runner.app
xcrun simctl launch <udid> com.neoreo.numbering
xcrun simctl io <udid> screenshot hint_store.png
```

`simctl io screenshot`은 기기의 기본 방향 버퍼를 그대로 저장한다. iPhone은
가로 전용이므로 저장된 이미지를 반시계 방향으로 90도 회전해야 한다
(`sips -r -90 hint_store.png`). 결과 크기는 iPhone 6.9인치 2868×1320,
iPad 13인치 2752×2064이며 둘 다 App Store 스크린샷 규격에 해당한다.

**심사 메모**(4000자 이내)는 아래 내용에 테스트 계정을 채워 넣는다.

```text
힌트는 게임 내에서 정답 블록을 하나 채워 주는 소모성 아이템입니다.
확인 경로: 앱 실행 > 로그인 > 홈 화면 우측 상단 힌트(전구) 배지 탭 > 힌트 상점.
레벨 플레이 중 힌트가 0개일 때 힌트 버튼을 눌러도 같은 화면이 열립니다.
구매한 힌트는 서버(Supabase)에서 영수증 검증 후 계정 잔액에 지급됩니다.
소모성 상품이므로 구매 복원 버튼은 제공하지 않습니다.
테스트 계정: <email> / <password>
```

**프로모션 이미지**(1024×1024, JPG/PNG, 72dpi, RGB, 둥근 모서리 없음)는 App
Store 제품 페이지에서 상품을 홍보할 때만 필요하다. 힌트 팩은 홍보하지 않으므로
비워 둔다.

## StoreKit 로컬 테스트

`ios/Runner/Numbering.storekit`에 상품 3개를 동일하게 정의해 두고 Runner
스킴에 연결했다. 덕분에 App Store Connect에 상품을 등록하기 전에도 구매 흐름을
확인할 수 있다. 이 설정은 **Xcode > Product > Run**으로 실행할 때만 적용된다.
`flutter run`은 스킴을 거치지 않고 앱을 바로 설치하므로 실제 샌드박스를 사용한다.
상품 ID나 가격이 바뀌면 이 파일도 같이 수정한다.

로컬 StoreKit 거래는 App Store Server API에 존재하지 않으므로
`verify-hint-purchase`가 거부한다. 로컬 설정은 상점 UI와 구매 흐름 확인용으로만
쓰고, 지급까지 확인하는 검증은 Sandbox Apple 계정으로 진행한다.

## StoreKit 2 필수 조건

`in_app_purchase_storekit` 0.4.x는 iOS 15 이상에서 StoreKit 2를 기본으로
사용한다. `applicationUserName`이 거래의 `appAccountToken`으로 전달되는 것도
StoreKit 2에서만 동작한다. Edge Function은 이 토큰을 Supabase 사용자 ID와
비교해 불일치하면 구매를 거부한다. iOS 13~14에서는 플러그인이 StoreKit 1로
폴백하고 `appAccountToken`이 없으므로 해당 기기의 구매는 항상 검증에 실패한다.
상점을 출시하기 전에 `IPHONEOS_DEPLOYMENT_TARGET`과 Podfile의 platform을
15.0으로 올리거나, 해당 기기에서는 힌트 상점을 막아야 한다. `enableStoreKit1()`은
호출하지 않는다.

## Supabase 배포

구매 검증 함수는 App Store Server API와 Google Play Developer API를 호출한
뒤, `service_role`만 실행할 수 있는 RPC를 통해 구매 내역과 힌트 잔액을
저장한다. 함수를 배포하기 전에 데이터베이스 마이그레이션을 적용한다.

```bash
supabase db push
supabase functions deploy verify-hint-purchase
```

Supabase 프로젝트에 다음 Edge Function 비밀값을 설정한다.

```bash
supabase secrets set \
  APPLE_IAP_BUNDLE_ID=com.neoreo.numbering \
  APPLE_IAP_ISSUER_ID=... \
  APPLE_IAP_KEY_ID=... \
  APPLE_IAP_PRIVATE_KEY='-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----' \
  GOOGLE_PLAY_PACKAGE_NAME=com.neoreo.numbering \
  GOOGLE_PLAY_SERVICE_ACCOUNT_JSON='{"client_email":"...","private_key":"..."}'
```

Apple 앱 내 구입 API 키는 App Store Connect에서 생성하고, 발급된 `.p8`
개인키를 사용한다. Google에서는 Android Publisher API를 활성화하고,
Play Console에서 서비스 계정에 NUMBERING 앱 접근 권한을 부여한다.
두 개인키 모두 Flutter assets, Dart define 또는 저장소에 넣지 않는다.

## 출시 전 확인

1. App Store Connect와 Play Console에서 유료 앱 계약, 세금 및 은행 계좌
   설정을 완료한다.
2. 앱 심사에 제출할 App Store 버전에 앱 내 구입 상품 3개를 모두 연결한다.
3. Android 결제를 테스트하기 전에 빌드를 내부 테스트 트랙에 업로드하고,
   라이선스 테스터 계정으로 Google Play에서 앱을 설치한다.
4. Sandbox Apple 계정 또는 StoreKit 테스트 세션으로 Apple 결제를 테스트한다.
5. 구매 성공 시 로그인한 계정의 힌트가 한 번만 증가하는지, 같은 상품을 다시
   구매할 수 있는지, 같은 거래가 다시 전달되어도 중복 지급되지 않는지 확인한다.
6. 결제 대기, 취소, 오프라인, 계정 불일치, 환불 및 철회된 거래에는 힌트가
   지급되지 않는지 확인한다.

소모성 상품에는 사용자용 구매 복원 버튼을 제공하지 않는다. 완료되지 않은
거래는 스토어 구매 스트림을 통해 다시 전달되며, 지급 완료된 힌트 잔액은
Supabase의 `numbering_user_resources`에 유지된다.
