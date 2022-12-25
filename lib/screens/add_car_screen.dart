import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/localization.dart';
import '../model/car.dart';
import '../widgets/fuel_type_selection.dart';
import '../utils/common.dart';
import '../providers/cars.dart';
import '../providers/refuelings.dart';
import '../model/distance.dart';

class AddCarScreen extends StatefulWidget {
  static const routeName = '/add-car';
  final bool _asMainScreen;
  AddCarScreen() : _asMainScreen = false;
  AddCarScreen.mainScreen() : _asMainScreen = true;
  @override
  _AddCarScreenState createState() => _AddCarScreenState();
}

enum ScrollRequestState { Init, Drawing, Done }

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  ScrollController? _scrollController;
  Car? _car;
  ScrollRequestState _scrollDownRequested = ScrollRequestState.Done;
  static final availableColors = [
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.red,
    Colors.pink,
    Colors.brown,
    Colors.blueGrey,
    Colors.grey,
    Colors.white,
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  void _scrollDown() {
    _scrollController?.animateTo(_scrollController!.position.maxScrollExtent,
        duration: Duration(milliseconds: 300), curve: Curves.easeIn);
  }

  void _fuelTypeChanged(int index, int fuelType, int fuelUnit) {
    if ((_car?.fuelTanks[index].type != fuelType) ||
        (_car?.fuelTanks[index].unit != fuelUnit)) {
      final fuelTypes = _car!.fuelTanks;
      fuelTypes[index] = FuelTank(fuelType, fuelUnit, null); //TODO - add fuel capacity selection
      setState(() => _car = _car!.copyWith(fuelTypes: fuelTypes));
    }
  }

  void _deleteFuelType(int index) {
    setState(() {
      _car = _car!.copyWith(fuelTypes: _car!.fuelTanks..removeAt(index));
    });
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final cars = Provider.of<Cars>(context, listen: false);
      final oldMileage = cars.get(_car!.id)?.initialMileage;
      final requestUpdate =
          (oldMileage != null) && (oldMileage != _car!.initialMileage);
      cars.addCar(_car!..sanitize());
      if (requestUpdate) {
        Provider.of<Refuelings>(context, listen: false)
            .recalculateTotalMileage(_car!.id!, _car!.initialMileage!);
      }
      if (widget._asMainScreen) {
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  void _deleteRequest() {
    final loc = Localization.of(context);
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(loc.tr('deleteCarConfirmation')),
              actions: <Widget>[
                TextButton(
                  child: Text(loc.tr('cancelAction')),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text(loc.tr('deleteAction')),
                  onPressed: () {
                    Provider.of<Cars>(context).delete(_car!.id!);
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final loc = Localization.of(context);
    if (_car == null) {
      _car = ModalRoute.of(context)?.settings.arguments as Car? ?? Car();
    }
    if (_scrollDownRequested == ScrollRequestState.Init) {
      Future.delayed(
          Duration.zero,
          () => setState(
              () => _scrollDownRequested = ScrollRequestState.Drawing));
    } else if (_scrollDownRequested == ScrollRequestState.Drawing) {
      _scrollDownRequested = ScrollRequestState.Done;
      Future.delayed(Duration.zero, _scrollDown);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.tr('addCarTitle')),
        actions: <Widget>[
          if (_car!.id != null)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteRequest,
            ),
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _saveForm,
          )
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              DropdownButtonFormField<int>(
                items: availableColors
                    .map((Color color) => DropdownMenuItem(
                          value: color.value,
                          child: Container(
                            color: color,
                            child: Container(
                              width: MediaQuery.of(context).size.width - 60,
                              height: 20,
                            ),
                            // decoration: BoxDecoration(color: Color(value)),
                            margin: const EdgeInsets.symmetric(
                                vertical: 1, horizontal: 4),
                          ),
                        ))
                    .toList(),
                value: _car!.color?.value,
                validator: (value) =>
                    value == null ? loc.tr('errorValueEmpty') : null,
                onChanged: (value) =>
                    setState(() => _car = _car!.copyWith(color: Color(value!))),
                decoration: InputDecoration(labelText: loc.tr('color')),
              ),
              TextFormField(
                initialValue: _car!.brand ?? '',
                onSaved: (value) => _car = _car!.copyWith(brand: value),
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                    labelText:
                        '${loc.tr("carBrand")}${loc.tr("optionalMark")}'),
              ),
              TextFormField(
                initialValue: _car!.model ?? '',
                keyboardType: TextInputType.text,
                onSaved: (value) => _car = _car!.copyWith(model: value),
                decoration: InputDecoration(
                    labelText:
                        '${loc.tr("carModel")}${loc.tr("optionalMark")}'),
              ),
              TextFormField(
                initialValue: _car!.name ?? '',
                keyboardType: TextInputType.text,
                validator: (value) =>
                    value!.isEmpty ? loc.tr('errorValueEmpty') : null,
                onSaved: (value) => _car = _car!.copyWith(name: value),
                decoration: InputDecoration(labelText: loc.tr('carName')),
              ),
              DropdownButtonFormField<Distance>(
                items: [
                  DropdownMenuItem(
                    value: Distance.km,
                    child: Text(loc.tr('unitKm')),
                  ),
                  DropdownMenuItem(
                    value: Distance.mile,
                    child: Text(loc.tr('unitMile')),
                  ),
                ],
                value: _car!.distanceUnit,
                validator: (value) =>
                    value == null ? loc.tr('errorValueEmpty') : null,
                onChanged: (value) =>
                    setState(() => _car = _car!.copyWith(distanceUnit: value)),
                decoration: InputDecoration(labelText: loc.tr('distanceUnit')),
              ),
              TextFormField(
                initialValue: _car!.distanceUnit
                        ?.toUnit(_car!.initialMileage?.toDouble())
                        ?.toString() ??
                    '',
                keyboardType: TextInputType.number,
                onSaved: (value) => _car = _car!.copyWith(
                    initialMileage: _car!.distanceUnit
                            ?.toSi(toDouble(value ?? '0.0'))
                            ?.round() ??
                        0),
                validator: (value) => value?.isEmpty ?? true
                    ? null
                    : toDouble(value!) == null
                        ? loc.tr('errorInvalidNumber')
                        : (toDouble(value) ?? 0.0) <= 0.0
                            ? loc.tr('errorMustBePositive')
                            : null,
                decoration:
                    InputDecoration(labelText: loc.tr('initialMileage')),
              ),
              ...List<Widget>.generate(
                  _car!.fuelTanks.length,
                  (idx) => FuelTypeSelectionWidget(
                        fuelIndex: idx,
                        selectedType: _car!.fuelTanks[idx].type,
                        selectedUnit: _car!.fuelTanks[idx].unit,
                        onChange: _fuelTypeChanged,
                        onDeleted:
                            _car!.fuelTanks.length > 1 ? _deleteFuelType : null,
                      )),
              if (_car!.fuelTanks.length < Car.MAX_FUEL_TYPES)
                IconButton(
                  icon: Icon(Icons.add_circle),
                  color: Theme.of(context).primaryColor,
                  tooltip: loc.tr('addFuelType'),
                  onPressed: () {
                    setState(() => _car = _car!.copyWith(
                        fuelTypes: _car!.fuelTanks
                          ..add(FuelTank(null, null, null))));
                    _scrollDownRequested = ScrollRequestState.Init;
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
