
import 'package:flutter/material.dart';

class FocusItem {
  final FocusNode focusNode;
  final bool Function() isSet;

  FocusItem(this.focusNode, this.isSet);
}

class FocusHandler {
  final _items = <FocusItem>[];
  final Function() saveForm;

  FocusHandler(this.saveForm);

  void make(FocusNode node,  bool Function() isSet) => _items.add(FocusItem(node, isSet));

  bool allOthersAreSet(FocusNode node) => 
    _items.where((element) => element.focusNode != node).every((element) => element.isSet());

  TextInputAction nodeAction(FocusNode node) => 
    allOthersAreSet(node) ? TextInputAction.done : TextInputAction.next;

  bool allAreSet() => _items.every((element) => element.isSet());
  
  void focusNext() => 
    _items.firstWhere((element) => !element.isSet(), orElse: null)?.focusNode?.requestFocus();

  void afterSave(TextInputAction action) => 
    (action == TextInputAction.done) && allAreSet() ? saveForm() : focusNext();

  void defocusAll() => _items.forEach((element) => element.focusNode.unfocus());
}