import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    // 연결바+터미널+Line Sender가 겹치지 않을 최소 크기. 툴바 한 줄(포트
    // 선택/보드레이트/Connect/뷰 전환/도움말/설정)이 실제로 겹치지 않는
    // 최소 콘텐츠 폭은 위젯 테스트로 측정한 값이 800px 부근이라(790px부터
    // RenderFlex 오버플로 발생), 거기에 여유를 두고 860으로 잡았다.
    self.minSize = NSSize(width: 860, height: 560)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
