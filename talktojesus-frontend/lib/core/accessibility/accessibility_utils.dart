import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';

class AccessibilityUtils {
  static void announceMessage(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  static void provideFeedback({
    bool haptic = true,
    bool audio = true,
  }) {
    if (haptic) {
      HapticFeedback.lightImpact(); // Subtle haptic feedback
    }
    if (audio) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  static Widget makeAccessible({
    required Widget child,
    required String label,
    String? hint,
    String? value,
    bool isButton = false,
    bool isSelected = false,
    bool isEnabled = true,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: isButton,
      selected: isSelected,
      enabled: isEnabled,
      onTap: onTap,
      child: child,
    );
  }

  static Widget createFocusableButton({
    required Widget child,
    required VoidCallback onPressed,
    required String semanticLabel,
    String? semanticHint,
    FocusNode? focusNode,
    bool autofocus = false,
  }) {
    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;

          return Container(
            decoration: isFocused
                ? BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).focusColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: Semantics(
              label: semanticLabel,
              hint: semanticHint,
              button: true,
              onTap: () {
                provideFeedback();
                onPressed();
              },
              child: GestureDetector(
                onTap: () {
                  provideFeedback();
                  onPressed();
                },
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  static bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  static bool isReduceMotionEnabled(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  static double getAccessibleTextScale(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0);
  }

  static EdgeInsets getAccessibleTouchTarget() {
    return const EdgeInsets.all(8.0); // Minimum 48x48 touch target
  }

  static Duration getAccessibleAnimationDuration(BuildContext context) {
    return isReduceMotionEnabled(context)
        ? Duration.zero
        : const Duration(milliseconds: 300);
  }
}

class AccessibleTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputType? keyboardType;

  const AccessibleTextFormField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      textField: true,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).focusColor,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}