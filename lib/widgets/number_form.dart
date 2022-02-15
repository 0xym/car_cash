import 'package:carsh/utils/focus_handler.dart';
import 'package:flutter/material.dart';

const DEFAULT_PRECISION = 2;

class NumberForm extends StatelessWidget {
  final void Function(String) onSaved;
  final void Function() onEditingComplete;
  final String Function(double) valueToText;
  final String? Function(String?) validate;
  final String labelText;
  final TextEditingController _controller;
  final focusNode = FocusNode();
  final FocusHandler focusHandler;

  NumberForm(
      {required double initialValue,
      required this.valueToText,
      required this.onSaved,
      required this.onEditingComplete,
      required this.validate,
      required this.labelText,
      required this.focusHandler})
      : _controller = TextEditingController(text: valueToText(initialValue)) {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        onSaved(_controller.text);
      }
    });
  }

  void getFocus() {
    focusNode.requestFocus();
  }

  void changeValue(double value, [int precision = DEFAULT_PRECISION]) =>
      _controller.text = valueToText(value);

  void dispose() {
    focusNode.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        controller: _controller,
        focusNode: focusNode,
        onFieldSubmitted: (v) {
          final action = focusHandler.nodeAction(focusNode);
          onSaved(v);
          focusHandler.afterSave(action);
        },
        validator: validate,
        onEditingComplete: onEditingComplete,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: labelText),
        textInputAction: focusHandler.nodeAction(focusNode));
  }
}
