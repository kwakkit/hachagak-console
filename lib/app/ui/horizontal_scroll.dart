import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 넓은 내용(표 등)을 가로 스크롤로 감싼다 — 창이 좁아도 잘리지 않게.
///
/// 웹에선 스크롤바가 기본으로 숨고 마우스 끌기도 막혀 있어 "잘린 것"처럼 보이므로
/// 스크롤바를 항상 보이고 마우스로도 끌 수 있게 한다. 자리가 넉넉하면 [child] 는
/// 가로 전체 폭으로 늘어난다.
class HorizontalScroll extends StatefulWidget {
  const HorizontalScroll({super.key, required this.child});

  final Widget child;

  @override
  State<HorizontalScroll> createState() => _HorizontalScrollState();
}

class _HorizontalScrollState extends State<HorizontalScroll> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(
        context,
      ).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
      child: LayoutBuilder(
        builder: (context, box) => Scrollbar(
          controller: _controller,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            // 스크롤바가 마지막 행을 가리지 않게.
            padding: const EdgeInsets.only(bottom: 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: box.maxWidth),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
