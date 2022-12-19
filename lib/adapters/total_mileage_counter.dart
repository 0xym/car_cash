import '../model/expenditure.dart';

class TotalMileageCounter {
  Map<int?, int?> _carMileage;
  TotalMileageCounter(Map<int?, int?> initialMileages)
      : _carMileage = initialMileages;

  //this function assumes that refueling is valid - carId has corresponding car
  void updateRefueling(Expenditure refueling) {
    _carMileage[refueling.carId] =
        _carMileage[refueling.carId] ?? 0 + (refueling.tripMileage ?? 0);
    refueling.totalMileage = _carMileage[refueling.carId]!;
  }
}
