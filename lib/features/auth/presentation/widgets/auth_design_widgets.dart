import 'package:flutter/material.dart';

import '../../../../shared/assets/app_assets.dart';
import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';

const authLogo = 'MAMEROOM';
const authBrandSubtitle =
    '\uAE30\uC5B5\uC744 \uC2EC\uACE0, \uD568\uAED8 \uC131\uC7A5\uD574\uC694.';

class AuthDesignScaffold extends StatelessWidget {
  const AuthDesignScaffold({required this.child, this.leading, super.key});

  final Widget child;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final body = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.paper, colors.primaryMist.withValues(alpha: 0.18)],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            Widget frame({required bool expanded}) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 40,
                          child: leading ?? const SizedBox(),
                        ),
                        if (expanded) Expanded(child: child) else child,
                      ],
                    ),
                  ),
                ),
              );
            }

            final shortViewport = constraints.maxHeight < 720;
            if (!keyboardVisible && !shortViewport) {
              return frame(expanded: true);
            }
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: frame(expanded: false),
            );
          },
        ),
      ),
    );
    return Scaffold(resizeToAvoidBottomInset: true, body: body);
  }
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    this.title,
    this.subtitle = authBrandSubtitle,
    this.showLogoMark = true,
    super.key,
  });

  final String? title;
  final String subtitle;
  final bool showLogoMark;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLogoMark) ...[
          const PixelMLogo(size: 78),
          const SizedBox(height: 10),
        ],
        Text(
          authLogo,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        if (title != null) ...[
          const SizedBox(height: 8),
          Text(
            title!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class AuthInputField extends StatefulWidget {
  const AuthInputField({
    required this.controller,
    required this.label,
    this.hint,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.autofillHints,
    this.onFieldSubmitted,
    this.showVisibilityToggle = false,
    this.onVisibilityToggle,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final bool showVisibilityToggle;
  final VoidCallback? onVisibilityToggle;

  @override
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (_focusNode.hasFocus)
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        validator: widget.validator,
        autofillHints: widget.autofillHints,
        onFieldSubmitted: widget.onFieldSubmitted,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          suffixIcon: widget.showVisibilityToggle
              ? IconButton(
                  tooltip: widget.obscureText
                      ? '\uBE44\uBC00\uBC88\uD638 \uBCF4\uAE30'
                      : '\uBE44\uBC00\uBC88\uD638 \uC228\uAE30\uAE30',
                  onPressed: widget.enabled ? widget.onVisibilityToggle : null,
                  icon: Icon(
                    widget.obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.primary, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    required this.label,
    required this.mark,
    required this.onPressed,
    super.key,
  });

  final String label;
  final String mark;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                mark,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: [
        Expanded(child: Divider(color: colors.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '\uB610\uB294',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
        ),
        Expanded(child: Divider(color: colors.line)),
      ],
    );
  }
}

class PixelMLogo extends StatelessWidget {
  const PixelMLogo({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        AppAssets.mameroomIcon,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      ),
    );
  }
}

class AuthIllustration extends StatelessWidget {
  const AuthIllustration({required this.icon, this.seed = true, super.key});

  final IconData icon;
  final bool seed;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return SizedBox(
      height: 154,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            icon,
            size: 92,
            color: colors.primarySoft.withValues(alpha: 0.82),
          ),
          if (seed)
            Positioned(
              top: 28,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.sun.withValues(alpha: 0.28),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.eco_rounded,
                  color: colors.seedGreen,
                  size: 28,
                ),
              ),
            ),
          Positioned(
            left: 76,
            top: 42,
            child: Icon(
              Icons.auto_awesome,
              color: colors.primaryPale,
              size: 12,
            ),
          ),
          Positioned(
            right: 72,
            top: 32,
            child: Icon(
              Icons.auto_awesome,
              color: colors.primaryPale,
              size: 10,
            ),
          ),
          Positioned(
            right: 84,
            bottom: 36,
            child: Icon(
              Icons.auto_awesome,
              color: colors.primaryPale,
              size: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class ValidationLine extends StatelessWidget {
  const ValidationLine({required this.valid, required this.text, super.key});

  final bool valid;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: [
        Icon(
          valid
              ? Icons.check_circle_outline_rounded
              : Icons.radio_button_unchecked_rounded,
          color: valid ? colors.seedGreen : colors.muted,
          size: 17,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: valid ? colors.seedGreen : colors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
