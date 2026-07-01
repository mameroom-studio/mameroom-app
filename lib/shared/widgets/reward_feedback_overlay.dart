import 'package:flutter/material.dart';

class RewardFeedbackOverlay extends StatefulWidget {
  const RewardFeedbackOverlay({
    required this.child,
    required this.messages,
    required this.trigger,
    this.alignment = Alignment.topCenter,
    super.key,
  });

  final Widget child;
  final List<String> messages;
  final int trigger;
  final Alignment alignment;

  @override
  State<RewardFeedbackOverlay> createState() => _RewardFeedbackOverlayState();
}

class _RewardFeedbackOverlayState extends State<RewardFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;
  List<String> _visibleMessages = const [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.72, curve: Curves.easeOut),
      reverseCurve: Curves.easeIn,
    );
    _scale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: const Offset(0, -0.12),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant RewardFeedbackOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.messages.isNotEmpty) {
      _visibleMessages = widget.messages;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: widget.alignment,
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: ScaleTransition(
                    scale: _scale,
                    child: _RewardBubble(messages: _visibleMessages),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RewardBubble extends StatelessWidget {
  const _RewardBubble({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: messages
              .map(
                (message) => Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class RewardAnimatedValue extends StatelessWidget {
  const RewardAnimatedValue({required this.value, this.style, super.key});

  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(value),
      tween: Tween<double>(begin: 1.18, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Text(value, style: style ?? Theme.of(context).textTheme.titleMedium),
    );
  }
}
