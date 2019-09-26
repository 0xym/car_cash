import 'package:flutter/material.dart';

class TwoItemLine extends StatelessWidget {
  static const _spaceBetween = 10.0;
  final Widget widget1;
  final Widget widget2;
  TwoItemLine(this.widget1, this.widget2);
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded( child: widget1,),
        SizedBox( width: _spaceBetween,),
        Expanded( child: widget2,)
      ],
    );
  }
}
