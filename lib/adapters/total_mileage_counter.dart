import '../model/refueling.dart';

class TotalMileageCounter {
  Map<int, int> _carMileage;
  TotalMileageCounter(Map<int, int> initialMileages) : _carMileage = initialMileages;

  //this function assumes that refueling is valid - carId has corresponding car
  void updateRefueling(Refueling refueling) {
    _carMileage[refueling.carId] += refueling.tripMileage;
    refueling.totalMileage = _carMileage[refueling.carId];
  }
}