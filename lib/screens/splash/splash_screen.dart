import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary  = Color(0xFF5E8B7E); // sage green glow
  static const Color _light    = Color(0xFFFFFFFF); // white top
  static const Color _gold     = Color(0xFFF9B000); // brand gold
  static const Color _bgBottom = Color(0xFFF5F7FA); // soft off-white bottom
  static const Color _textDark = Color(0xFF1F2937); // dark slate text

  // 2.4 seconds total — all elements animate in together
  static const Duration _total = Duration(milliseconds: 2400);

  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _glowScale;
  late final Animation<double> _glowFade;
  late final Animation<double> _textFade;
  late final Animation<double> _textSlide;
  late final Animation<double> _accentWidth;
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _ctrl = AnimationController(vsync: this, duration: _total);

    // Glow expands and fades — same start as everything else
    _glowScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic)),
    );

    _glowFade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 35),
      TweenSequenceItem(tween: ConstantTween(1.0),           weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 35),
    ]).animate(CurvedAnimation(parent: _ctrl,
        curve: const Interval(0.0, 0.72, curve: Curves.easeInOut)));

    // Logo + text enter TOGETHER from the very start
    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.0, 0.42, curve: Curves.easeOutBack)),
    );

    _logoFade = CurvedAnimation(parent: _ctrl,
        curve: const Interval(0.0, 0.28, curve: Curves.easeOut));

    _textFade = CurvedAnimation(parent: _ctrl,
        curve: const Interval(0.0, 0.38, curve: Curves.easeOut));

    _textSlide = Tween<double>(begin: 18.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.0, 0.38, curve: Curves.easeOutCubic)),
    );

    _accentWidth = Tween<double>(begin: 0.0, end: 48.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.25, 0.58, curve: Curves.easeOut)),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.88, 1.0, curve: Curves.easeIn)),
    );

    _ctrl.forward();
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _light,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Opacity(
            opacity: _exitFade.value,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_light, _bgBottom],
                ),
              ),
              child: Stack(
                children: [
                  // Subtle top-right accent
                  Positioned(
                    top: -70,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _gold.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -30,
                    right: -10,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _gold.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  // Bottom-left sage accent
                  Positioned(
                    bottom: -60,
                    left: -40,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ),

                  // Center content — logo + text all animate in together
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo with sage green radial glow
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Radial glow ring
                              Opacity(
                                opacity: _glowFade.value,
                                child: Transform.scale(
                                  scale: _glowScale.value,
                                  child: Container(
                                    width: 160,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          _primary.withValues(alpha: 0.55),
                                          _primary.withValues(alpha: 0.0),
                                        ],
                                        stops: const [0.55, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Logo card
                              Opacity(
                                opacity: _logoFade.value,
                                child: Transform.scale(
                                  scale: _logoScale.value,
                                  child: Container(
                                    width: 104,
                                    height: 104,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(26),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _primary.withValues(alpha: 0.45),
                                          blurRadius: 32,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 8),
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/icons/app_icon.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Text — enters at the same time as the logo
                        Opacity(
                          opacity: _textFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _textSlide.value),
                            child: Column(
                              children: [
                                const Text(
                                  'Visamate',
                                  style: TextStyle(
                                    color: _textDark,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'BANSAL IMMIGRATION',
                                  style: TextStyle(
                                    color: _textDark.withValues(alpha: 0.55),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 3.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Gold accent line grows in shortly after text
                        Container(
                          width: _accentWidth.value,
                          height: 3,
                          decoration: BoxDecoration(
                            color: _gold,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
