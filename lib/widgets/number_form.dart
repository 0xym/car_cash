import 'package:flutter/material.dart';

class NumberForm extends StatelessWidget {
  final void Function(String) onSaved;
  final void Function() onEditingComplete;
  final String Function(String) validate;
  final String labelText;
  final TextEditingController _controller;
  final _focusNode = FocusNode();

  static String valueToText(double value) => (value ?? '').toString();

  NumberForm(
      {@required double initialValue,
      @required this.onSaved,
      @required this.onEditingComplete,
      @required this.validate,
      @required this.labelText})
      : _controller = TextEditingController(text: valueToText(initialValue)) {
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        onSaved(_controller.text);
      }
    });
  }

  void getFocus() {
    _focusNode.requestFocus();
  }

  void changeValue(double value) => _controller.text = valueToText(value);

  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      onFieldSubmitted: (v) {
        onSaved(v);
      },
      validator: validate,
      onEditingComplete: onEditingComplete,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: labelText),
      textInputAction: TextInputAction.next,
    );
  }
}
