import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/localization.dart';
import '../model/car.dart';
import '../widgets/fuel_type_selection.dart';
import '../utils/common.dart';
import '../providers/cars.dart';
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
  ScrollController _scrollController;
  Car _car;
  ScrollRequestState _scrollDownRequested = ScrollRequestState.Done;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollDown() {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300), curve: Curves.easeIn);
  }

  void _fuelTypeChanged(int index, int fuelType, int fuelUnit) {
    setState(() {
      _car.fuelTypes[index].type = fuelType;
      _car.fuelTypes[index].unit = fuelUnit;
    });
  }

  void _deleteFuelType(int index) {
    setState(() {
      _car.fuelTypes.removeAt(index);
    });
  }

  void _saveForm() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      Provider.of<Cars>(context).addCar(_car..sanitize());
      if (widget._asMainScreen) {
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  void _deleteRequest() {
    final loc = Localization.of(context);
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(loc.tr('deleteCarConfirmation')), actions: <Widget>[
      FlatButton(child: Text(loc.tr('cancelAction')), onPressed: () => Navigator.of(context).pop(),),
      FlatButton(child: Text(loc.tr('deleteAction')), onPressed: () {
        Provider.of<Cars>(context).delete(_car.id);
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      } ,),
    ],));
  }

  @override
  Widget build(BuildContext context) {
    final loc = Localization.of(context);
    if (_car == null) {
      _car = ModalRoute.of(context).settings.arguments ?? Car();
    }
    if (_scrollDownRequested == ScrollRequestState.Init) {
      Future.delayed(
          Duration.zero,
          () => setState(
              () => _scrollDownRequested = ScrollRequestState.Drawing));
    } else if (_scrollDownRequested == ScrollRequestState.Drawing) {
      Future.delayed(Duration.zero, _scrollDown);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.tr('addCarTitle')),
        actions: <Widget>[
          if (_car.id != null) 
          IconButton(icon: Icon(Icons.delete), onPressed: _deleteRequest,),
          IconButton(icon: Icon(Icons.check), onPressed: _saveForm,)
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              TextFormField(
                initialValue: _car.brand ?? '',
                onSaved: (value) => _car.brand = value,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                    labelText:
                        '${loc.tr("carBrand")}${loc.tr("optionalMark")}'),
              ),
              TextFormField(
                initialValue: _car.model ?? '',
                keyboardType: TextInputType.text,
                onSaved: (value) => _car.model = value,
                decoration: InputDecoration(
                    labelText:
                        '${loc.tr("carModel")}${loc.tr("optionalMark")}'),
              ),
              TextFormField(
                initialValue: _car.name ?? '',
                keyboardType: TextInputType.text,
                validator: (value) => value.isEmpty ? loc.tr('errorValueEmpty') : null,
                onSaved: (value) => _car.name = value,
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
                value: _car.distanceUnit,
                validator: (value) => value == null ? loc.tr('errorValueEmpty') : null,
                onChanged: (value) => setState(() => _car.distanceUnit = value),
                decoration: InputDecoration(labelText: loc.tr('distanceUnit')),
              ),
              TextFormField(
                initialValue: _car.distanceUnit?.toUnit(_car.initialMileage)?.toString() ?? '',
                keyboardType: TextInputType.number,
                onSaved: (value) => _car.initialMileage = _car.distanceUnit?.toSi(toDouble(value)) ?? 0.0,
                validator: (value) => value.isEmpty ? null : toDouble(value) == null ? loc.tr('errorInvalidNumber') : toDouble(value) <= 0.0 ? loc.tr('errorMustBePositive') : null,
                decoration:
                    InputDecoration(labelText: loc.tr('initialMileage')),
              ),
              ...List<Widget>.generate(
                  _car.fuelTypes.length,
                  (idx) => FuelTypeSelectionWidget(
                        fuelIndex: idx,
                        selectedType: _car.fuelTypes[idx].type,
                        selectedUnit: _car.fuelTypes[idx].unit,
                        onChange: _fuelTypeChanged,
                        onDeleted: _car.fuelTypes.length > 1 ? _deleteFuelType : null,
                      )),
              if (_car.fuelTypes.length < Car.MAX_FUEL_TYPES) FlatButton(
                child: Text(
                  loc.tr('addFuelType'),
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
                onPressed: () {
                  setState(
                      () => _car.fuelTypes.add(FuelTypeAndUnit(null, null)));
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
