import 'package:flutter/painting.dart';

/// 하차각 노선 id → 표시 이름·상징색. 하차각 `assets/stations/seoul.json` 의
/// `lines[]` 와 맞춘다 — 하차각에 노선이 늘면 여기도 추가(모르는 id 는 id 그대로·회색).
class SubwayLine {
  const SubwayLine(this.id, this.name, this.color);

  final String id;
  final String name;
  final Color color;

  static const List<SubwayLine> all = [
    SubwayLine('1', '1호선', Color(0xFF0052A4)),
    SubwayLine('2', '2호선', Color(0xFF00A84D)),
    SubwayLine('3', '3호선', Color(0xFFEF7C1C)),
    SubwayLine('4', '4호선', Color(0xFF00A5DE)),
    SubwayLine('5', '5호선', Color(0xFF996CAC)),
    SubwayLine('6', '6호선', Color(0xFFCD7C2F)),
    SubwayLine('7', '7호선', Color(0xFF747F00)),
    SubwayLine('8', '8호선', Color(0xFFE6186C)),
    SubwayLine('9', '9호선', Color(0xFFBDB092)),
    SubwayLine('I1', '인천1호선', Color(0xFF7CA8D5)),
    SubwayLine('I2', '인천2호선', Color(0xFFF5A200)),
    SubwayLine('GTXA', 'GTX-A', Color(0xFF9A6292)),
    // 광역선 — 하차각 tool/build_kric.dart 로 추가 예정(id = KRIC 선코드).
    // 색은 위키백과 Module:Adjacent_stations/Seoul_Metropolitan_Subway 기준.
    SubwayLine('A1', '공항철도', Color(0xFF0090D2)),
    SubwayLine('D1', '신분당선', Color(0xFFD31145)),
    SubwayLine('K1', '수인분당선', Color(0xFFFABE00)),
    SubwayLine('K4', '경의중앙선', Color(0xFF77C4A3)),
  ];

  static SubwayLine of(String id) => all.firstWhere(
    (l) => l.id == id,
    orElse: () => SubwayLine(id, id, const Color(0xFF8A8A8A)),
  );
}
