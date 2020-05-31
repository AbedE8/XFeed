/* File to get location of user
* used dependencies - location => to get location coordinates of user,
*   - geoLocation => To get Address from the location coordinates
 */
// import 'dart:html';

import 'package:flutter/services.dart';
import 'package:geocoder/geocoder.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';
getUserLocation() async {
  LocationData currentLocation;
  String error;
  Location location = Location();
  try {
    currentLocation = await location.getLocation();
  } on PlatformException catch (e) {
    if (e.code == 'PERMISSION_DENIED') {
      error = 'please grant permission';
      print(error);
    }
    if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
      error = 'permission denied- please enable it from app settings';
      print(error);
    }
    currentLocation = null;
  }
  final coordinates = Coordinates(
      currentLocation.latitude, currentLocation.longitude);
  // var addresses =
  //     await Geocoder.local.findAddressesFromCoordinates(coordinates);
  // var addresses = await Geocoder.google("AIzaSyCIsdZDKCzkVb6pb9cb02_ec-Tih_1qhO4").findAddressesFromCoordinates(coordinates);
  //List<Placemark> placemark = await Geolocator().placemarkFromCoordinates(currentLocation.latitude, currentLocation.longitude);
  print("current location lat "+currentLocation.latitude.toString()+" long " +currentLocation.longitude.toString());
  // for (var item in addresses) {
  //   print("address is "+item.featureName);
  //   print("address is "+item.locality);
  //   // print("address is "+item.subLocality);
  //   // print("address is "+item.subAdminArea);
  //   // print("address is "+item.featureName);
  // }
  // var first = addresses.first;
  return null;
}
 getUserCordinate() async {
  LocationData currentLocation;
  String error;
  Location location = Location();
  try {
    currentLocation = await location.getLocation();
  } on PlatformException catch (e) {
    if (e.code == 'PERMISSION_DENIED') {
      error = 'please grant permission';
      print(error);
    }
    if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
      error = 'permission denied- please enable it from app settings';
      print(error);
    }
    currentLocation = null;
  }
  final coordinates = Coordinates(
      currentLocation.latitude, currentLocation.longitude);
  return coordinates;
}

getSpecificAdd(double latitiude, double long) async{
  // final coordinates = Coordinates(
  //     latitiude, long);
  // // var addresses =
  // //     await Geocoder.local.findAddressesFromCoordinates(coordinates);
  // print("addresses");

  // var addresses = await Geocoder.google("AIzaSyCIsdZDKCzkVb6pb9cb02_ec-Tih_1qhO4")
  // .findAddressesFromCoordinates(coordinates);
  // print("num addresses "+addresses.length.toString());
  // print("addLine: "+addresses.first.addressLine);
  // print("adminArea: "+addresses.first.adminArea);
  // print("countrycode: "+addresses.first.countryCode);
  // print("featurename: "+addresses.first.featureName);
  // print("locality: "+addresses.first.locality);
  // print("subThoroughfare: "+addresses.first.subThoroughfare);

  // var sss = await Geolocator().placemarkFromCoordinates(latitiude, long);
  // for (var item in sss) {
  //   print("feature is "+item.toJson().toString());
  // }
  // // print("subThoroughfare: "+addresses.first.);

  // // print("sublocality: "+addresses.first.subLocality);
  // // print("thoroughfare: "+addresses.first.thoroughfare);
}
