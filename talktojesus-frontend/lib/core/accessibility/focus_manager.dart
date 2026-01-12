import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppFocusManager {
  static final Map<String, FocusNode> _focusNodes = {};
  static final Map<String, List<String>> _focusTraversalOrder = {};

  static FocusNode getFocusNode(String key) {
    return _focusNodes.putIfAbsent(key, () => FocusNode());
  }

  static void disposeFocusNode(String key) {
    _focusNodes[key]?.dispose();
    _focusNodes.remove(key);
  }

  static void disposeAll() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _focusNodes.clear();
    _focusTraversalOrder.clear();
  }

  static void setFocusTraversalOrder(String groupKey, List<String> focusKeys) {
    _focusTraversalOrder[groupKey] = focusKeys;
  }

  static void focusNext(String currentKey, String groupKey) {
    final order = _focusTraversalOrder[groupKey];
    if (order == null) return;

    final currentIndex = order.indexOf(currentKey);
    if (currentIndex == -1) return;

    final nextIndex = (currentIndex + 1) % order.length;
    final nextKey = order[nextIndex];
    _focusNodes[nextKey]?.requestFocus();
  }

  static void focusPrevious(String currentKey, String groupKey) {
    final order = _focusTraversalOrder[groupKey];
    if (order == null) return;

    final currentIndex = order.indexOf(currentKey);
    if (currentIndex == -1) return;

    final previousIndex = currentIndex == 0 ? order.length - 1 : currentIndex - 1;
    final previousKey = order[previousIndex];
    _focusNodes[previousKey]?.requestFocus();
  }

  static void requestFocus(String key) {
    _focusNodes[key]?.requestFocus();
  }

  static void unfocus(String key) {
    _focusNodes[key]?.unfocus();
  }

  static bool hasFocus(String key) {
    return _focusNodes[key]?.hasFocus ?? false;
  }
}

class AppFocusTraversalGroup extends StatefulWidget {
  final String groupKey;
  final List<String> focusOrder;
  final Widget child;

  const AppFocusTraversalGroup({
    super.key,
    required this.groupKey,
    required this.focusOrder,
    required this.child,
  });

  @override
  State<AppFocusTraversalGroup> createState() => _AppFocusTraversalGroupState();
}

class _AppFocusTraversalGroupState extends State<AppFocusTraversalGroup> {
  @override
  void initState() {
    super.initState();
    AppFocusManager.setFocusTraversalOrder(widget.groupKey, widget.focusOrder);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.tab) {
            final currentFocusedKey = widget.focusOrder.firstWhere(
              (key) => AppFocusManager.hasFocus(key),
              orElse: () => '',
            );

            if (currentFocusedKey.isNotEmpty) {
              if (HardwareKeyboard.instance.isShiftPressed) {
                AppFocusManager.focusPrevious(currentFocusedKey, widget.groupKey);
              } else {
                AppFocusManager.focusNext(currentFocusedKey, widget.groupKey);
              }
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}

class AccessibleFocusWidget extends StatefulWidget {
  final String focusKey;
  final Widget child;
  final VoidCallback? onFocusChanged;
  final bool autofocus;

  const AccessibleFocusWidget({
    super.key,
    required this.focusKey,
    required this.child,
    this.onFocusChanged,
    this.autofocus = false,
  });

  @override
  State<AccessibleFocusWidget> createState() => _AccessibleFocusWidgetState();
}

class _AccessibleFocusWidgetState extends State<AccessibleFocusWidget> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = AppFocusManager.getFocusNode(widget.focusKey);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    widget.onFocusChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: isFocused
                ? BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).focusColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: widget.child,
          );
        },
      ),
    );
  }
}