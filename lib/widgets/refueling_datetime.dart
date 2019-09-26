import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/localization.dart';
import '../model/refueling.dart';

abstract class _RefuelingDateTime extends StatefulWidget {
  final Refueling _refueling;
  _RefuelingDateTime(this._refueling);
}

abstract class _RefuelingDateTimeState extends State<_RefuelingDateTime> {
  TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime get _old => widget._refueling.timestamp;
  String get _format;
  String get _label;
  void _setText() => _controller.text = DateFormat(_format).format(widget._refueling.timestamp);
  void _showPicker();

  @override
  Widget build(BuildContext context) {
    final loc = Localization.of(context);
    _setText();
    return TextFormField(
      controller: _controller,
      readOnly: true,
      textAlign: TextAlign.center,
      decoration: InputDecoration(labelText: loc.tr(_label)),
      onTap: _showPicker,
    );
  }
}

class RefuelingDate extends _RefuelingDateTime {
  RefuelingDate(Refueling refueling) : super(refueling);

  @override
  _RefuelingDateTimeState createState() => _RefuelingDateState();
}

class _RefuelingDateState extends _RefuelingDateTimeState {
  void _updateDate(DateTime date) {
    if (date != null) {
      setState(() {
        widget._refueling.timestamp = DateTime(date.year, date.month, date.day, _old.hour, _old.minute, _old.second, _old.millisecond);
        _setText();
      });
    }
  }

  String get _format => 'yyyy-MM-dd';
  String get _label => 'date';
  void _showPicker() => showDatePicker(context: context, initialDate: _old, firstDate: DateTime(2000), lastDate: DateTime.now()).then(_updateDate);
}

class RefuelingTime extends _RefuelingDateTime {
  RefuelingTime(Refueling refueling) : super(refueling);

  @override
  _RefuelingDateTimeState createState() => _RefuelingTimeState();
}
class _RefuelingTimeState extends _RefuelingDateTimeState {
  void _updateTime(TimeOfDay time) {
    if (time != null) {
      setState(() {
        widget._refueling.timestamp = DateTime(_old.year, _old.month, _old.day, time.hour, time.minute, _old.second, _old.millisecond);
        _setText();
      });
    }
  }

  String get _format => 'HH:mm';
  String get _label => 'time';
  void _showPicker() => showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_old)).then(_updateTime);
}