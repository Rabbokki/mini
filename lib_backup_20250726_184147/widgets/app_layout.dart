import 'package:flutter/material.dart';
import '../theme.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  final bool centerContent;

  const AppLayout({
    super.key,
    required this.child,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: AppTheme.maxWidth), // CSS: max-width: 1280px
      margin: const EdgeInsets.symmetric(horizontal: 0), // CSS: margin: 0 auto
      padding: const EdgeInsets.all(AppTheme.rootPadding), // CSS: padding: 2rem
      alignment: centerContent ? Alignment.center : null, // CSS: text-align: center
      child: child,
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;

  const AppCard({
    super.key,
    required this.child,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding), // CSS: .card padding: 2em
        child: child,
      ),
    );
  }
}

class AppLogo extends StatefulWidget {
  final String? imagePath;
  final bool enableHoverEffect;
  final bool enableRotation;
  final Color? glowColor;

  const AppLogo({
    super.key,
    this.imagePath,
    this.enableHoverEffect = true,
    this.enableRotation = false,
    this.glowColor,
  });

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _hoverController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    // 로고 회전 애니메이션 (CSS: @keyframes logo-spin)
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20), // CSS: 20s linear
      vsync: this,
    );
    
    // 호버 효과 애니메이션
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300), // CSS: transition: filter 300ms
      vsync: this,
    );

    if (widget.enableRotation) {
      _rotationController.repeat(); // CSS: infinite
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: widget.enableHoverEffect ? (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      } : null,
      onExit: widget.enableHoverEffect ? (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      } : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _hoverController]),
        builder: (context, child) {
          return Container(
            width: AppTheme.logoSize, // CSS: height: 6em
            height: AppTheme.logoSize,
            padding: const EdgeInsets.all(AppTheme.logoPadding), // CSS: padding: 1.5em
            decoration: widget.enableHoverEffect && _isHovered
                ? BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: widget.glowColor ?? Colors.blue.withOpacity(0.7), // CSS: drop-shadow
                        blurRadius: 32, // CSS: 2em blur
                        spreadRadius: 0,
                      ),
                    ],
                  )
                : null,
            child: Transform.rotate(
              angle: widget.enableRotation ? _rotationController.value * 2 * 3.14159 : 0,
              child: widget.imagePath != null
                  ? Image.asset(
                      widget.imagePath!,
                      fit: BoxFit.contain,
                    )
                  : Icon(
                      Icons.flutter_dash,
                      size: AppTheme.logoSize - AppTheme.logoPadding * 2,
                      color: AppColors.primary,
                    ),
            ),
          );
        },
      ),
    );
  }
}

class ReadTheDocsText extends StatelessWidget {
  final String text;

  const ReadTheDocsText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.readTheDocsColor, // CSS: .read-the-docs color: #888
      ),
    );
  }
} 