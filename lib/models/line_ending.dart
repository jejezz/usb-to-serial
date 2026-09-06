/// Line Sender에서 Enter를 눌렀을 때 뒤에 붙일 종단 문자.
enum LineEnding { none, lf, cr, crlf }

extension LineEndingX on LineEnding {
  String get suffix => switch (this) {
        LineEnding.none => '',
        LineEnding.lf => '\n',
        LineEnding.cr => '\r',
        LineEnding.crlf => '\r\n',
      };

  String get label => switch (this) {
        LineEnding.none => '없음',
        LineEnding.lf => r'\n',
        LineEnding.cr => r'\r',
        LineEnding.crlf => r'\r\n',
      };
}
