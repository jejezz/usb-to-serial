# Portside

macOS 전용 USB-to-Serial(COM) 터미널. Flutter로 만들었다.

## 왜

macOS에는 Windows처럼 무료 시리얼 터미널이 마땅치 않다. CoolTerm은 오래돼서 최신 macOS에서 더 이상 실행되지 않고, Termius는 시리얼 통신을 지원하지만 유료다. 그래서 직접 만들었다.

## 기능

- 시리얼 포트 자동 감지/새로고침, 보드레이트 지정
- **탭 기반 멀티 세션** — 여러 포트에 동시 접속
- 터미널 화면(`xterm2` 기반 — 한글 조합 제외한 IME, 256색/트루컬러 ANSI, 화살표·Ctrl 조합 지원)
- **Line Sender** — 여러 줄을 미리 써두고 Enter로 한 줄씩 순서대로 전송, Ctrl+Enter로 줄바꿈
- Hex View 토글
- Output 로깅 — 시작 시 저장 위치/파일명을 직접 지정, 단축키(⌘⇧R)로 시작/정지
- 폰트/색상 테마(Solarized, Dracula, Nord, Gruvbox 등)·스크롤백 줄 수 설정, 재실행 후에도 유지
- ⌘T(새 탭) / ⌘W(탭 닫기) / ⌘⇧R(로깅 토글)

## 요구 사항

- macOS, Xcode 전체 설치(Command Line Tools만으로는 안 됨)
- Flutter (stable 채널)
- Homebrew `autoconf`/`automake`/`pkg-config` — `flutter_libserialport`가 CocoaPods로 `libserialport` C 라이브러리를 소스 빌드하는 데 필요

## 실행

```bash
flutter pub get
flutter run -d macos
```

## 알려진 한계

- 터미널 화면에 직접 타이핑할 때 한글 조합이 깨진다 — `xterm2`(정확히는 원조 `xterm.dart`)의 macOS 텍스트 입력 처리 버그. Line Sender 입력창은 일반 `TextField`라 영향 없음.

## 설계 문서

전체 설계 배경, 아키텍처, 각 기능을 만들며 겪은 문제와 해결 과정은 [DESIGN.md](DESIGN.md)에 있다.
