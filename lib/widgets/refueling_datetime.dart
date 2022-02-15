import 'package:carsh/adapters/refueling_adapter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/localization.dart';
import '../utils/common.dart';
import '../utils/global_preferences.dart';
import '../model/preferences.dart';

typedef TimestampSetter = Function(DateTime);

abstract class _RefuelingDateTime extends StatefulWidget {
  final RefuelingAdapter _refueling;
  final TimestampSetter _setter;
  _RefuelingDateTime(this._refueling, this._setter);
}

abstract class _RefuelingDateTimeState extends State<_RefuelingDateTime> {
  TextEditingController? _controller;
  final preferences = Preferences();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  DateTime get _old => widget._refueling.get().timestamp!;
  String get _format;
  String get _label;
  void _setText() => _controller?.text = DateFormat(_format).format(_old);
  void _showPicker();
  set timestamp(DateTime timestamp) {
    widget._setter(timestamp);
    setState(() => _setText());
  }

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
  RefuelingDate(RefuelingAdapter refueling, TimestampSetter setter)
      : super(refueling, setter);

  @override
  _RefuelingDateTimeState createState() => _RefuelingDateState();
}

class _RefuelingDateState extends _RefuelingDateTimeState {
  void _updateDate(DateTime? date) {
    if (date != null) {
      timestamp = DateTime(date.year, date.month, date.day, _old.hour,
          _old.minute, _old.second, _old.millisecond);
    }
  }

  String get _format => preferences.get(DATE_FORMAT);
  String get _label => 'date';
  void _showPicker() => showDatePicker(
          context: context,
          initialDate: _old,
          firstDate: DateTime(2000),
          lastDate: today())
      .then(_updateDate);
}

class RefuelingTime extends _RefuelingDateTime {
  RefuelingTime(RefuelingAdapter refueling, TimestampSetter setter)
      : super(refueling, setter);

  @override
  _RefuelingDateTimeState createState() => _RefuelingTimeState();
}

class _RefuelingTimeState extends _RefuelingDateTimeState {
  void _updateTime(TimeOfDay? time) {
    if (time != null) {
      timestamp = DateTime(_old.year, _old.month, _old.day, time.hour,
          time.minute, _old.second, _old.millisecond);
    }
  }

  String get _format => preferences.get(TIME_FORMAT);
  String get _label => 'time';
  void _showPicker() => showTimePicker(
          context: context, initialTime: TimeOfDay.fromDateTime(_old))
      .then(_updateTime);
}
