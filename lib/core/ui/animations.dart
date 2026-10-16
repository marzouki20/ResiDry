library residry.core.ui.animations;

import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/theme/app_theme.dart';

class AnimatedCard extends StatelessWidget {
  const AnimatedCard({
    super.key,
    required this.child,
    this.delay = 0,
    this.duration = const Duration(milliseconds: 600),
    this.animate = true,
  });

  final Widget child;
  final int delay;
  final Duration duration;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    return FadeInUp(
      delay: Duration(milliseconds: delay),
      duration: duration,
      from: 20,
      child: child,
    );
  }
}

class AnimatedListItem extends StatelessWidget {
  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 500),
  });

  final Widget child;
  final int index;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return SlideInUp(
      delay: Duration(milliseconds: 50 * index),
      duration: duration,
      from: 30,
      child: child,
    );
  }
}

class AnimatedFab extends StatelessWidget {
  const AnimatedFab({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
  });

  final VoidCallback onPressed;
  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ZoomIn(
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: backgroundColor ?? AppColors.navy,
        child: child,
      ),
    );
  }
}

class AnimatedSectionHeader extends StatelessWidget {
  const AnimatedSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.delay = 0,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      delay: Duration(milliseconds: delay),
      duration: const Duration(milliseconds: 600),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
            if (action != null && onAction != null)
              TextButton(
                onPressed: onAction,
                child: Text(action!),
              ),
          ],
        ),
      ),
    );
  }
}

class ScanResultCard extends StatefulWidget {
  const ScanResultCard({
    super.key,
    required this.success,
    required this.message,
    this.alerts = const [],
  });

  final bool success;
  final String message;
  final List<String> alerts;

  @override
  State<ScanResultCard> createState() => _ScanResultCardState();
}

class _ScanResultCardState extends State<ScanResultCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.success ? Colors.green : Colors.red;
    return ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _opacity,
        child: Card(
          color: color.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  widget.success ? Icons.check_circle : Icons.error,
                  color: color,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScanningLoader extends StatefulWidget {
  const ScanningLoader({super.key, required this.label});

  final String label;

  @override
  State<ScanningLoader> createState() => _ScanningLoaderState();
}

class _ScanningLoaderState extends State<ScanningLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _rotation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _rotation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.radio_button_checked, color: AppColors.navy, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            widget.label,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class PulseDot extends StatefulWidget {
  const PulseDot({super.key, this.color = AppColors.navy, this.size = 12});

  final Color color;
  final double size;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.8, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyStateIllustration extends StatelessWidget {
  const EmptyStateIllustration({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconSize = 80,
    this.iconColor = AppColors.muted,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final double iconSize;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: iconSize + 20,
            height: iconSize + 20,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class StaggeredListBuilder extends StatelessWidget {
  const StaggeredListBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(16),
    this.itemSpacing = 10,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsetsGeometry padding;
  final double itemSpacing;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: itemSpacing),
          child: AnimatedListItem(child: itemBuilder(context, index), index: index),
        );
      },
    );
  }
}
