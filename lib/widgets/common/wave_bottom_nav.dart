import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A modern bottom navigation bar with a "wave" cradle: the bar's top edge
/// curves down beneath the active item, and a floating circular button slides
/// (with a subtle wave bob) between items when the selection changes.
class WaveNavItem {
  final IconData icon;
  final String label;
  const WaveNavItem({required this.icon, required this.label});
}

class WaveBottomNav extends StatefulWidget {
  final List<WaveNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Number of leading items that behave as persistent tabs (get the floating
  /// cradle button). Items beyond this index act as one-off actions/links.
  final int tabCount;

  final Color barColor;
  final Color accentTop;
  final Color accentBottom;
  final Color unselectedColor;

  const WaveBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    int? tabCount,
    this.barColor = const Color(0xFF101722),
    this.accentTop = const Color(0xFFFFCA28),
    this.accentBottom = const Color(0xFFF9B000),
    this.unselectedColor = const Color(0xFF94A3B8),
  }) : tabCount = tabCount ?? items.length;

  @override
  State<WaveBottomNav> createState() => _WaveBottomNavState();
}

class _WaveBottomNavState extends State<WaveBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _pos; // animated, fractional active index

  static const double _barHeight = 68;
  static const double _topReserve = 26; // room for the floating button to rise
  static const double _btnRadius = 26;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _pos = AlwaysStoppedAnimation(widget.currentIndex.toDouble());
  }

  @override
  void didUpdateWidget(covariant WaveBottomNav old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _pos = Tween<double>(
        begin: _pos.value,
        end: widget.currentIndex.toDouble(),
      ).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic),
      );
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: _barHeight + _topReserve,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final count = widget.items.length;
            final itemWidth = width / count;

            return AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final pos = _pos.value;
                final activeX = itemWidth * (pos + 0.5);

                // Wave bob: 0 at endpoints, 1 mid-travel.
                final t = (pos - pos.roundToDouble()).abs(); // 0..0.5
                final bob = math.sin((t / 0.5) * math.pi); // 0..1..0
                final btnDip = bob * 9;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // The wave bar
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: _barHeight,
                      child: CustomPaint(
                        painter: _WavePainter(
                          activeX: activeX,
                          color: widget.barColor,
                          radius: _btnRadius,
                        ),
                      ),
                    ),

                    // Tappable items (labels + inactive icons)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: _barHeight,
                      child: Row(
                        children: List.generate(count, (i) {
                          final isActive =
                              i < widget.tabCount && pos.round() == i;
                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (i != widget.currentIndex) {
                                  HapticFeedback.selectionClick();
                                  widget.onTap(i);
                                }
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Active icon lives in the floating button,
                                  // so reserve the space here instead.
                                  SizedBox(
                                    height: 26,
                                    child: isActive
                                        ? null
                                        : Icon(
                                            widget.items[i].icon,
                                            size: 23,
                                            color: widget.unselectedColor,
                                          ),
                                  ),
                                  const SizedBox(height: 5),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    child: AnimatedDefaultTextStyle(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        height: 1.0,
                                        letterSpacing: 0.2,
                                        fontWeight: isActive
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isActive
                                            ? widget.accentBottom
                                            : widget.unselectedColor,
                                      ),
                                      child: Text(
                                        widget.items[i].label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    // Floating active button riding the wave
                    Positioned(
                      left: activeX - _btnRadius,
                      top: btnDip,
                      child: GestureDetector(
                        onTap: () {
                          if (widget.currentIndex != pos.round()) return;
                          HapticFeedback.lightImpact();
                          widget.onTap(widget.currentIndex);
                        },
                        child: Container(
                          width: _btnRadius * 2,
                          height: _btnRadius * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [widget.accentTop, widget.accentBottom],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: widget.barColor,
                              width: 5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.accentBottom
                                    .withValues(alpha: 0.55),
                                blurRadius: 16,
                                spreadRadius: 1,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.items[widget.currentIndex].icon,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double activeX;
  final Color color;
  final double radius;

  _WavePainter({
    required this.activeX,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    const depth = 24.0; // how deep the cradle dips
    final spread = radius * 1.7; // half-width of the cradle mouth

    // The curved top edge (used both for fill and the hairline highlight).
    final topEdge = Path()
      ..moveTo(0, 0)
      ..lineTo(activeX - spread, 0)
      ..cubicTo(
        activeX - radius * 0.95, 0,
        activeX - radius, depth,
        activeX, depth,
      )
      ..cubicTo(
        activeX + radius, depth,
        activeX + radius * 0.95, 0,
        activeX + spread, 0,
      )
      ..lineTo(size.width, 0);

    final fillPath = Path.from(topEdge)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final isLight = color.computeLuminance() > 0.5;

    // Soft drop shadow above the bar (lighter for a light theme).
    canvas.drawShadow(
      fillPath,
      Colors.black.withValues(alpha: isLight ? 0.18 : 0.55),
      isLight ? 8 : 12,
      false,
    );

    // Subtle vertical gradient gives the bar depth.
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          isLight ? color : Color.lerp(color, Colors.white, 0.05)!,
          color,
        ],
      ).createShader(rect);
    canvas.drawPath(fillPath, fill);

    // Crisp hairline along the top edge for a premium feel.
    final hairline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = isLight
          ? Colors.black.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.07);
    canvas.drawPath(topEdge, hairline);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.activeX != activeX || old.color != color;
}
