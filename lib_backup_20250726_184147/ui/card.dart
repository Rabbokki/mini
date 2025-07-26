import 'package:flutter/material.dart';
import '../theme.dart';

class AppCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    this.child,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: borderRadius ?? BorderRadius.circular(8.0), // rounded-lg
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // shadow-sm
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: AppColors.cardForeground,
        ),
        child: padding != null 
            ? Padding(padding: padding!, child: child)
            : child ?? const SizedBox.shrink(),
      ),
    );
  }
}

class CardHeader extends StatelessWidget {
  final Widget? child;
  final EdgeInsets? padding;

  const CardHeader({
    super.key,
    this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(24.0), // p-6
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (child != null) child!,
        ],
      ),
    );
  }
}

class CardTitle extends StatelessWidget {
  final String text;
  final Widget? child;
  final TextStyle? style;

  const CardTitle({
    super.key,
    required this.text,
    this.child,
    this.style,
  });

  const CardTitle.widget({
    super.key,
    required this.child,
    this.style,
  }) : text = '';

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      fontSize: 24.0, // text-2xl
      fontWeight: FontWeight.w600, // font-semibold
      height: 1.0, // leading-none
      letterSpacing: -0.025, // tracking-tight
      color: AppColors.cardForeground,
    );

    if (child != null) {
      return DefaultTextStyle(
        style: defaultStyle.merge(style),
        child: child!,
      );
    }

    return Text(
      text,
      style: defaultStyle.merge(style),
    );
  }
}

class CardDescription extends StatelessWidget {
  final String text;
  final Widget? child;
  final TextStyle? style;

  const CardDescription({
    super.key,
    required this.text,
    this.child,
    this.style,
  });

  const CardDescription.widget({
    super.key,
    required this.child,
    this.style,
  }) : text = '';

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      fontSize: 14.0, // text-sm
      color: AppColors.mutedForeground,
    );

    if (child != null) {
      return DefaultTextStyle(
        style: defaultStyle.merge(style),
        child: child!,
      );
    }

    return Text(
      text,
      style: defaultStyle.merge(style),
    );
  }
}

class CardContent extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const CardContent({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0), // p-6 pt-0
      child: child,
    );
  }
}

class CardFooter extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final MainAxisAlignment? alignment;

  const CardFooter({
    super.key,
    required this.child,
    this.padding,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0), // p-6 pt-0
      child: Row(
        mainAxisAlignment: alignment ?? MainAxisAlignment.start, // items-center
        children: [child],
      ),
    );
  }
}

// Complete card with header, content, and footer
class CompleteCard extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget content;
  final Widget? footer;
  final EdgeInsets? margin;

  const CompleteCard({
    super.key,
    this.title,
    this.description,
    required this.content,
    this.footer,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || description != null)
            CardHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    CardTitle(text: title!),
                    if (description != null) const SizedBox(height: 6.0), // space-y-1.5
                  ],
                  if (description != null)
                    CardDescription(text: description!),
                ],
              ),
            ),
          CardContent(child: content),
          if (footer != null)
            CardFooter(child: footer!),
        ],
      ),
    );
  }
} 