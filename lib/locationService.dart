import 'dart:ffi';

import 'package:Xfeedm/main.dart';
import 'package:background_location/background_location.dart';
import 'package:geodesy/geodesy.dart';

import 'server_controller.dart';

class LocationService {
  double dropOffLng;
  double dropOffLat;
  
  LocationService(double i_dropOffLng, double i_dropOffLat){
    this.dropOffLng = i_dropOffLng;
    this.dropOffLat = i_dropOffLat;
  }

  void checkIfArrived(userLocation) async {
    Geodesy geodesy = Geodesy();
    print("dropOff: lng:" + this.dropOffLng.toString() + " lat:" + this.dropOffLat.toString());
    print("location: lng:" + userLocation.longitude.toString() + " lat:" + userLocation.latitude.toString());
    print(geodesy.distanceBetweenTwoGeoPoints(new LatLng(this.dropOffLat, this.dropOffLng), new LatLng(userLocation.latitude, userLocation.longitude)));
    if (geodesy.distanceBetweenTwoGeoPoints(new LatLng(this.dropOffLat, this.dropOffLng), new LatLng(userLocation.latitude, userLocation.longitude)) < 50){
      BackgroundLocation.stopLocationService();
      var serverController = ServerController();
      await serverController.userArrivedLocation(currentUserModel.id);
    }
  }

  void startLocationService(){
    BackgroundLocation.getPermissions(
    onGranted: () {
        print("start location service");
        BackgroundLocation.startLocationService();
      },
    onDenied: () {
      // Show a message asking the user to reconsider or do something else
    });
    BackgroundLocation.startLocationService();
    BackgroundLocation.getLocationUpdates((location) {
      checkIfArrived(location);
    });
  }
}
