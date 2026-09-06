# usb-to-com: macOS 전용 Flutter 시리얼 터미널 — 설계 문서

## 배경
macOS에는 Windows처럼 무료 COM 포트 터미널이 마땅치 않다. CoolTerm은 오래돼서 더 이상 실행되지 않고, Termius는 시리얼 통신을 지원하지만 유료다. Termius 수준으로 깔끔하되, 단일 목적(시리얼 통신)에 맞게 단순화한 macOS 데스크톱 앱을 직접 만든다.

**확정된 범위**
- 1차 개발: macOS 전용
- 단일 연결: 탭/다중 세션 없음
- 기능: 포트 지정/자동 감지, 보드레이트 지정, 폰트/테마 지정, Hex View, Line Sender(줄 단위 송신), Output 로깅(버튼+단축키로 시작/정지)

## 컨벤션
- 상태관리: `provider`
- `pubspec.yaml`: `publish_to: 'none'`
- `flutter_lints` + `analysis_options.yaml`
- 주석은 "왜"만 한국어로

## 아키텍처

```
flutter_libserialport
      │  Stream<Uint8List>
      ▼
SerialService.dataStream ──► TerminalSessionProvider
                                 │  raw byte 버퍼 하나만 유지 (ring-buffer, 용량 제한)
                                 │  ├─► 현재 뷰 모드(ASCII/Hex)로만 렌더링
                                 │  └─► 로깅 중이면 raw bytes를 LogFileService로 전달
                                 ▼
                         notifyListeners() (연속 수신 시 코얼레싱)
                                 ▼
                         terminal_view.dart 리렌더

Line Sender ──text──► TerminalSessionProvider.send(bytes) ──► SerialService.write(bytes)
```

핵심 원칙:
- raw byte 버퍼는 하나만 (ASCII/Hex는 렌더링 차이일 뿐)
- TX는 Line Sender와 터미널 창 raw 키 입력 두 경로 모두 지원 (아래 "범위 변경" 참고). 둘 다 `TerminalSessionProvider`의 `_service.write()` 한 곳으로만 나간다.
- 로깅은 뷰 모드와 무관하게 항상 raw RX bytes 기록
- 고빈도 스트림 대비 notifyListeners 코얼레싱

### 범위 변경 1: raw 키 입력 추가 (Phase 4 중 결정)
처음엔 "Line Sender만 v1의 유일한 TX 경로"로 계획했는데, 사용자가 터미널 창에 직접 타이핑해서 보내고 싶어해서 범위를 넓혔다.

### 범위 변경 2: 직접 만든 raw 키 캡처 → `xterm2` 패키지로 교체
처음엔 `Focus.onKeyEvent` + `KeyEvent.character`로 직접 raw 키 입력을 만들었는데, 실기기 테스트에서 바로 문제가 드러났다: 한글 조합/인코딩이 깨지고, backspace가 이상하게 동작하고, 이스케이프 시퀀스 처리가 안 되고, 심지어 한 번 타이핑에 두 번 입력되는 현상까지 있었다. 원인은 근본적이었다 — `HardwareKeyboard`의 raw `KeyEvent` API는 macOS의 IME(입력기)를 완전히 우회한다. 한글 같은 조합형 입력은 물리 키 하나하나가 아니라 IME가 완성해주는 문자를 받아야 하는데, raw 키 이벤트는 그걸 모른다. 이런 걸 다 직접 구현하려면(IME 조합 상태 추적, ANSI 파서, 커서 addressable 렌더링) 사실상 미니 터미널 에뮬레이터를 만드는 것과 같아서, 검증된 오픈소스 터미널 에뮬레이터 패키지 `xterm2`(원조 `xterm.dart`의 유지보수 포크, IME 지원 내장, ANSI/VT100 렌더링 포함)로 교체했다.
- `TerminalSessionProvider`가 `xterm2`의 `Terminal` 인스턴스를 직접 들고 있고, 수신 바이트는 `terminal.write()`로, 키보드 입력은 `terminal.onOutput` 콜백을 거쳐 `sendRaw()`로 나간다.
- `_rawBytes`(RX raw 바이트 누적)는 화면 렌더링과 별개로 계속 유지 — Hex View/로깅은 여기서만 가져온다. 화면에 뭐가 보이는지와 실제로 수신한 바이트가 뭔지가 (echo 여부 등으로) 다를 수 있어서 분리해뒀다.
- 터미널 화면에서의 raw 키 입력은 로컬 에코를 하지 않는다 — 실제 터미널처럼 상대가 에코해줘야 화면에 보인다(이 기기는 Phase 1에서 확인했듯 에코함). Line Sender의 Local Echo 토글은 그와 별개로 Line Sender 자체 전송에만 적용된다.
- 부작용: `SelectableText` 기반의 자체 텍스트 선택은 없어지고, `xterm2`가 제공하는 마우스 드래그 선택 + 우클릭 복사/붙여넣기로 대체됨.

**알려진 한계 — 터미널 화면 raw 타이핑 중 한글 조합 실패**: 원인은 `xterm2`(원본 `xterm.dart`)의 `CustomTextEdit.updateEditingValue`가 macOS composing 경로에서 `setEditingState()` 리셋이 무시될 때 정적인 `_initEditingState` 기준으로 diff를 떠서 생기는 버그 — 한글처럼 매 글자가 composing 경로를 타는 입력에서 조합이 깨진다. 업스트림에 수정 PR([TerminalStudio/xterm.dart#226](https://github.com/TerminalStudio/xterm.dart/pull/226))이 있지만 아직 머지 안 됐고, 우리가 쓰는 `xterm2` 포크에도 반영 안 돼 있음. 로컬에 패키지를 벤더링해서 패치하는 것도 가능하지만(직접 검증한 패치안 있음), 한글 입력을 거의 안 쓴다고 하여 지금은 그냥 감수하고 넘어가기로 함. 필요해지면 벤더링 패치나 업스트림 머지 여부를 다시 확인.

## 기본값
- 로깅 시작/정지 단축키: ⌘⇧R
- 로그 파일: `~/Downloads/usb_to_com_logs/<port>_<yyyyMMdd_HHmmss>.log`, RX only
- Local Echo 기본 ON
- Line Sender 줄바꿈 기본 `\n` (드롭다운으로 변경 가능)
- 자동 재연결 없음
- 스크롤백 상한: 기본 10000줄, 설정에서 변경 가능(1000~100000 프리셋)

## 프로젝트 구조

```
lib/
  main.dart / app.dart
  models/serial_port_info.dart, connection_settings.dart
  services/serial_service.dart, log_file_service.dart
  state/terminal_session_provider.dart, settings_provider.dart
  screens/home_screen.dart
  widgets/port_selector.dart, baud_rate_selector.dart, terminal_view.dart,
          line_sender.dart, status_bar.dart, settings_dialog.dart
  utils/hex_dump.dart
assets/icons/   # icons8 세트 (rs-232, usb-connected, terminal, hex, speed, theme,
                #   settings, save-as, stop, record, refresh, send, error)
test/hex_dump_test.dart
```

## macOS entitlement — Phase 1에서 실측한 결과

애초 계획: `com.apple.security.device.serial`을 양쪽 entitlements에 추가하면 될 것으로 예상 (GitHub 이슈 #30, #105, #25, CHANGELOG v0.2.2 근거).

**실측 (socat 가상 pty 루프백 테스트)**:
1. Entitlement만 추가 + App Sandbox 유지 → `SerialPortError: Operation not permitted, errno = 1`. 샌드박스가 막고 있었다는 뜻.
2. App Sandbox를 꺼보니(`com.apple.security.app-sandbox = false`, 양쪽 entitlements) → 에러가 `Inappropriate ioctl for device, errno = 25 (ENOTTY)`로 바뀜. `libserialport`의 `get_config()`가 `ioctl(fd, TIOCMGET, ...)`(모뎀 제어선 상태 조회)를 호출하는데, 순수 BSD pty(socat으로 만든 가상 포트)는 이 ioctl을 지원하지 않음 — **이건 라이브러리 버그가 아니라 pty 루프백 테스트 자체의 근본적 한계**. 실제 USB-시리얼 어댑터/아두이노는 전부 TIOCMGET을 지원하므로 실기기에서는 발생하지 않을 것으로 판단됨.

**현재 설정** (개인용 도구, App Store 배포 아님이므로 정당화됨):
- `macos/Runner/DebugProfile.entitlements`, `Release.entitlements` 양쪽:
  - `com.apple.security.app-sandbox` = **false**
  - `com.apple.security.device.serial` = true (혹시 몰라 유지, 무해함)

**실기기 검증 완료** (`/dev/cu.usbserial-56710052361`):
- `SerialPort.availablePorts`가 IOKit으로 실제 어댑터를 정상 인식.
- 9600bps에서 open()/write() 성공 (TIOCMGET도 실기기에선 문제없음, pty만의 한계였음이 확인됨).
- 115200bps에서 완전한 TX/RX 왕복 확인 — 임베디드 기기(Android 디버그 콘솔, `/system/bin/sh` 프롬프트 응답)와 정상 통신.

App Sandbox를 끈 현재 설정으로 실기기 열기/읽기/쓰기 전부 정상 동작 확인됨. Phase 1 완전히 종료.

**빌드 확인됨**: `flutter_libserialport` 0.6.0의 CocoaPods/autotools 소스 빌드(`libserialport` C 라이브러리)는 이 환경(Xcode 전체 설치 + Homebrew autoconf/automake/pkgconf)에서 경고만 있고 정상 빌드됨.

## 단계별 로드맵

- [x] **Phase 0** — 부트스트랩 (`flutter create`, pubspec/lint 정리, 앱 아이콘)
- [x] **Phase 1** — `flutter_libserialport` 스파이크, entitlement/샌드박스 확정. 실기기(115200bps, Android 디버그 콘솔)로 TX/RX 풀 왕복까지 검증 완료.
- [x] **Phase 2** — 핵심 서비스/상태 골격 (`SerialService`, `TerminalSessionProvider`, 최소 UI). 실기기로 connect 성공 확인.
- [x] **Phase 3** — 포트 감지/새로고침(`PortSelector`, 2초 폴링) + 보드레이트 UI(`BaudRateSelector`, 프리셋 메뉴 + 숫자만 입력 가능한 필드). 사용자 확인 완료.
- [x] **Phase 4** — Line Sender: 여러 줄을 미리 써두고 Enter로 커서 줄만 전송(Ctrl+Enter는 줄바꿈), 전송 후 커서는 다음 줄 끝으로 자동 이동. 실기기로 검증 완료 — 처음엔 Ctrl+Enter를 "기본 동작에 맡김(ignored)"으로 처리했더니 플랫폼 텍스트 입력 채널이 raw 키 이벤트와 별개로 움직여서 줄바꿈이 전혀 안 들어가는 문제가 있었음(터미널 raw 입력 때와 같은 종류의 이중 채널 이슈) — 두 경우(Enter/Ctrl+Enter) 모두 컨트롤러를 직접 조작하는 방식으로 고쳐서 해결. 터미널 raw 타이핑은 `xterm2`로 구현(범위 변경 1·2 참고).
- [x] **Phase 5** — Hex View 토글: `lib/utils/hex_dump.dart`(순수 함수, 유닛 테스트 완료) + `HexView` 위젯, `TerminalSessionProvider.rawBytes`(RX raw 바이트, 화면 표시/로컬 에코와 무관)를 그대로 렌더링. 화면 상단 SegmentedButton으로 Terminal/Hex 전환.
- [x] **Phase 6** — Output 로깅: `LogFileService`(`~/Downloads/usb_to_com_logs/<port>_<timestamp>.log`, RX raw bytes만), 상태바에 기록 중 표시(빨간 점 + 파일명), record/stop 아이콘 버튼, 앱 전역 단축키 ⌘⇧R(`CallbackShortcuts`, 포커스 위치 무관하게 동작). `lib/app.dart` 신설(Provider + 전역 단축키 + MaterialApp).
- [x] **Phase 7** — 폰트/테마: `SettingsProvider`(`shared_preferences`로 영속화) + `SettingsDialog`(폰트 4종, 크기 슬라이더, 테마 9종 — xterm2 기본 2개 + 직접 만든 그린 포스포/라이트 + Solarized Dark/Light·Dracula·Nord·Gruvbox Dark). `TerminalView`(xterm2 `theme`/`textStyle`)와 `HexView` 둘 다 같은 설정을 따르도록 연결. AppBar에 설정 아이콘 버튼 추가.
  - 유명 테마 추가(2026-09-06): xterm2가 256색/트루컬러 SGR(`38;5;N`, `38;2;R;G;B`)까지 자체 지원한다는 걸 실기기로 확인한 뒤, 우리 `TerminalTheme`(16-ANSI-color 모델)이 이미 Solarized/Dracula/Nord/Gruvbox 같은 유명 팔레트를 그대로 표현할 수 있다는 데 착안해 추가함. 각 팔레트는 공식/통용 hex 값을 그대로 옮김.
  - 스크롤백 줄 수 설정 추가(2026-09-06): `xterm2`의 `Terminal.maxLines`는 생성자에서만 정해지는 `final` 값이라 런타임에 못 바꿈 — 값이 바뀌면 `TerminalSessionProvider.setScrollbackLines()`가 `Terminal`을 통째로 새로 만들어 교체한다(그 순간 화면 스크롤백은 비워짐, 실제 터미널 앱들도 보통 그럼). `SettingsProvider`(설정값 보관/영속화)와 `TerminalSessionProvider`(실제 적용)는 서로 모르게 두고, `app.dart`가 `_settings`에 리스너를 달아 둘을 이어준다.
- [x] **Phase 8** — 폴리시/엣지 케이스:
  - 기기 뽑힘 감지: 스트림 `onError`뿐 아니라 `onDone`(에러 없이 그냥 끊기는 경우)도 처리, 죽은 포트를 `SerialService.close()`가 각 단계를 독립적으로 try/catch로 방어(하나 실패해도 나머지 정리는 계속). 로깅 중이었으면 로그도 flush/close.
  - `SerialService.write()`가 네이티브 `SerialPortError`를 `SerialServiceException`으로 감싸서 provider가 일관되게 처리.
  - 앱 종료(⌘Q) 시 위젯 dispose가 보장 안 되는 문제: `app.dart`를 `StatefulWidget`+`WidgetsBindingObserver`로 바꿔 `didRequestAppExit()`에서 로그 파일을 명시적으로 flush/close(`TerminalSessionProvider.prepareForExit()`). `FlutterAppDelegate` 기본 구현이 이 훅을 지원해서 네이티브 쪽 추가 코드는 불필요.
  - 메모리 상한은 Phase 2부터 이미 있던 `_rawBytes` 2MB 캡 + xterm2 `Terminal(maxLines: 10000)`으로 충족.

- [x] **Phase 9** — 탭 기반 멀티 세션 (2026-09-06): "여러 포트에 동시 접속"이 필요해져서 진행. 멀티 윈도우(OS 창 여러 개)도 검토했지만 Flutter의 진짜 멀티윈도우 API가 아직 `@internal`(stable 채널 불가)이고 실전 대안인 `desktop_multi_window`는 창마다 별도 Flutter 엔진을 띄우는 무거운 구조라 기각 — 탭이 훨씬 간단하고 목적도 그대로 달성됨.
  - `TerminalSessionProvider`에 `pendingPort`/`pendingBaudRate`/`viewMode`/`tabTitle` 추가 — 원래 `_HomeScreenState`(위젯 로컬 State)에 있던 "연결 전 선택 상태"를 세션 쪽으로 승격해서 탭 전환해도 유지되게 함.
  - `SessionsProvider`(신규) — `List<TerminalSessionProvider>` + 활성 인덱스만 관리. 각 세션의 연결/버퍼/로깅은 그대로 각 `TerminalSessionProvider`가 담당(단일세션 때 로직 무수정). 탭이 백그라운드에 있어도 스트림 구독은 provider 객체에 붙어있어서 계속 데이터 수신/로깅됨 — 화면에 그릴 위젯만 활성 탭 것만 마운트.
  - `TabBarRow`(신규) — 동적 추가/삭제에 Material `TabController`(vsync, length 재생성) 쓰는 게 번거로워서 직접 만든 가로 Row. 탭 하나하나는 `ListenableBuilder`로 자기 세션만 구독해서, 탭 전체를 다시 그리지 않고 상태 바뀐 탭만 리렌더.
  - `home_screen.dart`는 탭바 + 활성 세션을 `ChangeNotifierProvider.value`로 스코프해서 내려주는 역할만 하고, PortSelector/BaudRateSelector/TerminalView/HexView/StatusBar/LineSender는 전부 "가장 가까운 조상 provider" 패턴 그대로라 무수정 재사용.
  - `app.dart`: 단일 `TerminalSessionProvider` 대신 `SessionsProvider` 하나만 최상위 provider로 둠. ⌘⇧R(로깅)은 활성 탭 기준으로 변경, ⌘T(새 탭)/⌘W(현재 탭 닫기) 추가(사용자가 명시 요청한 건 아니고 탭 UI 관례상 추가 — 불필요하면 바로 뺄 수 있음). `didRequestAppExit`도 `SessionsProvider.prepareAllForExit()`로 전체 탭 순회. 폰트/테마/스크롤백(`SettingsProvider`)은 계속 앱 전역(탭별 아님) — `_settings`와 `_sessions` 양쪽에 리스너를 달아 설정 변경이든 새 탭 추가든 전체 탭에 스크롤백 설정이 맞춰지게 함.
  - 로그 파일 이름 직접 지정(2026-09-06, 같은 세션): 탭이 여러 개면 동시에 여러 로그가 기록될 수 있어서, record 버튼을 누르면 자동 이름 대신 `file_selector`의 네이티브 저장 대화상자(`getSaveLocation`)를 띄워 파일 이름/위치를 직접 고르게 함(취소하면 로깅 안 켜짐). 기본 제안값은 기존 `<port>_<timestamp>.log` 규칙 그대로(`LogFileService.suggestedFileName`). `LogFileService`는 포트 이름이 아니라 완성된 경로를 받는 형태로 단순화.
  - 아이콘/폰트 재설계(2026-09-06, 같은 세션): 사용자가 형제 프로젝트 `saturn-mobile-client-flutter`(모바일 앱, 알파블렌드 글로우 카드 + 아이콘-인-박스 배지 + 둥근 Material 아이콘 스타일)와 UI가 닮아갈까 우려하고, 현재 icons8 래스터 스티커 아이콘도 "아쉽다"고 함. 방향을 명확히 다르게 잡음 — Portside는 딱딱하고 정밀한 도구 느낌으로: icons8 PNG 전부(앱 아이콘 제외) `Icons.*_sharp`(각진 Material Symbols, 벡터라 어떤 크기든 선명하고 테마 색을 그대로 입힘) 12종으로 교체, 배지/글로우 컨테이너 없이 평평한 배경 위에 큼직하게(18~26px, 이전보다 확대) 강조색으로 직접 배치. `pubspec.yaml`의 `assets/icons/` 선언은 제거(코드에서 더 이상 참조 안 함 — 원본 PNG 파일 자체는 남겨둠). 메뉴 폰트는 `_lightTextTheme()`(`lib/app.dart`)로 텍스트 테마 전체를 폰트 Light 웨이트(300) + 1pt 축소 처리 — 터미널 안쪽 모노스페이스 폰트(SettingsProvider가 따로 관리)는 무관.
  - 폰트 `ClipartKorea` 추가(같은 시점): 사용자가 제공한 4중량(light/regular/medium/bold) TTF를 `assets/fonts/`에 넣고 `pubspec.yaml`에 등록, `ThemeData`의 기본 폰트로 사용. 색상 시드도 인디고에서 비비드한 보라(`#7C4DFF`)로 교체해 화사함을 더함.

## 검증 방법
실기기 없을 때: `socat -d -d pty,raw,echo=0,link=/tmp/ttyA pty,raw,echo=0,link=/tmp/ttyB`로 가상 포트 페어 생성. 단, 위에서 확인했듯 `open()` 단계에서 TIOCMGET 요구 때문에 완전한 열기/읽기/쓰기 검증은 불가 — UI 골격/상태관리 흐름 검증 용도로만 사용.
실기기 생기면: Phase 2부터 각 단계를 실제 어댑터로 재검증.

## 현재 상태 (v1 완료)
Phase 0~8 전부 실기기(USB-시리얼 어댑터, Android 디버그 콘솔 115200bps)로 검증 완료. 알려진 한계는 터미널 화면 raw 타이핑 중 한글 조합 실패(`xterm2` 업스트림 버그, 위 참고) 하나뿐이고 사용 빈도가 낮아 감수하기로 함. 이후 추가 아이디어가 생기면 이 문서에 새 Phase로 이어서 기록.

## Phase 10 — Saturn 디자인 언어 적용 (2026-09-06)
사용자가 형제 프로젝트 `saturn-mobile-client-flutter`와 같은 패밀리처럼 보이면 좋겠다고 해서, 먼저 Claude Design 캔버스로 "Portside가 Saturn의 일부라면" 컨셉 목업을 그려 확인받은 뒤 실제 앱에 반영함.

- `lib/theme/tokens.dart`(신규) — Saturn의 `lib/core/theme.dart`에서 `AppColors`(bg `#0A0E14`, surface `#151D27`, primary `#4C9DFF`, accent `#7C5CFF`, success/warning/danger/idle 등)와 `AppRadius`(card 24 / tile 20 / chip 999)를 그대로 옮김 + `AuroraBackground`(대각선 그라디언트 배경 워시).
- `lib/widgets/glass_card.dart`(신규) — Saturn의 `glass_card.dart`를 그대로 이식: `GlassCard`(반투명 패널 + 헤어라인 보더, active일 때 accent 26%/8% 알파블렌드 그라디언트 + glow shadow), `IconBadge`(둥근 사각형 아이콘 배지, 비활성 14%/활성 90% 알파), `StatusPill`(필 모양 상태 배지).
- `app.dart` — `ColorScheme`을 Saturn과 동일한 다크 스킴으로 교체, `FilledButton` 스타일을 Saturn 톤(radius 16, bold)에 맞춤. 기존 `_lightTextTheme`(폰트 Light+축소)은 유지 — Saturn 특유의 굵은 강조는 새 컴포넌트(StatusPill, 활성 탭, 버튼)의 로컬 스타일로만 구현해서 두 요구사항이 충돌하지 않게 함.
- `home_screen.dart` — 전체를 `AuroraBackground`로 감싸고, 툴바/터미널 영역/상태바/Line Sender를 각각 `GlassCard`로 감쌈. 터미널은 GlassCard(surface색 프레임) 안에 xterm2 자체 배경(테마별 어두운색)이 있는 "베젤 속 화면" 구도. 연결되면 우상단에 `StatusPill`("CONNECTED")을 겹쳐 띄움.
- `tab_bar_row.dart` — Saturn은 하단 고정 4탭이지만 Portside 탭은 세션 전환이라 성격이 달라 상단에 유지하되, 각 탭을 `GlassCard` 기반 필 모양으로 바꾸고 활성 탭에 연결 상태색(연결=초록/에러=빨강/기본=회색) 글로우를 입힘 — Saturn의 디바이스별 accent 색 관례를 세션 상태에 맞게 응용.
- `port_selector.dart`/`baud_rate_selector.dart`/`line_sender.dart`/`settings_dialog.dart` — TextField/Dropdown을 Saturn의 "inset fill"(불투명도 28% 검정 채움, 테두리 없음, tile radius) 스타일로, 아이콘 버튼을 `IconBadge`로, 체크박스를 `Switch`로 교체.
- 아이콘을 `_rounded`(Saturn과 동일 스타일)로 전면 교체 — Phase 9 폴리시 때 의도적으로 `_sharp`(Saturn과 차별화)로 갔던 걸 이번 요청으로 뒤집음. 두 결정 다 그 시점 요구사항엔 맞았던 판단.
- 폰트는 Saturn의 `SeoulNamsan` 대신 이미 있는 `ClipartKorea`를 유지(실제 폰트 파일이 없어서) — 목업에서는 Noto Sans KR로 임시 대체했었음.

## Phase 11 — 연결 직후 프롬프트 깨우기 (2026-09-06)
많은 임베디드 리눅스/안드로이드 디버그 콘솔은 뭔가 받기 전엔 프롬프트를 안 찍는다(Phase 1에서 PING을 보내야만 응답이 왔던 것과 같은 현상). `TerminalSessionProvider.connect()`가 연결 성공 직후 `sendRaw([0x0D, 0x0A])`(CRLF)를 한 번 보내서 콘솔을 깨우도록 함 — 기존 raw 전송 경로(`sendRaw`)를 그대로 재사용.

## Phase 12 — About / Help (2026-09-06)
`lib/widgets/about_dialog.dart`(앱 이름/버전/설명), `lib/widgets/help_dialog.dart`(기능별 사용법 + 단축키 목록) 신설. 네이티브 macOS 메뉴(앱 메뉴의 "About Portside" 등)에 연결하려면 플랫폼 채널 브릿지가 필요해서, 지금까지 전부 Flutter 쪽 UI로만 만들어온 흐름에 맞춰 툴바에 `PopupMenuButton`(물음표 아이콘)으로 "도움말"/"Portside 정보"를 노출하는 쪽을 택함.
