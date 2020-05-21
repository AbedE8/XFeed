import 'dart:async';
import 'package:Xfeedm/main.dart';
import 'package:Xfeedm/models/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FilterMap extends StatefulWidget {
  // final LatLng center;
  final UserPreference pref;
  final FilterMapController filterController;
  FilterMap(this.pref, this.filterController);
  @override
  State<StatefulWidget> createState() =>
      _FilterMap(this.pref, this.filterController);
}

class _FilterMap extends State<FilterMap> {
  LatLng center;
  final UserPreference pref;
  FilterMapController filterController;
  _FilterMap(this.pref, this.filterController);
  // 1
  Completer<GoogleMapController> _controller = Completer();
  // 2
  CameraPosition _initPosition;
  Marker pin;
  double radius = 0;
  double radisInitial;
  Set<Marker> markers;
  Set<Circle> circles;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    radisInitial = pref.radious;
    center = new LatLng(pref.location.latitude, pref.location.longitude);
    print("recieved lat " +
        center.latitude.toString() +
        " radius is " +
        radisInitial.toString() +
        "user pref is ");
    setState(() {
      _initPosition = new CameraPosition(target: center, zoom: 14.5746);
    });

    markers = new Set.from(
        [new Marker(markerId: MarkerId("asas"), position: center)]);
    circles = new Set.from([
      new Circle(
          circleId: CircleId("1"),
          center: center,
          radius: radisInitial * 1000,
          fillColor: Color.fromRGBO(0, 0, 255, 0.2),
          strokeWidth: 1,
          strokeColor: Colors.blue)
    ]);
  }

  @override
  Widget build(BuildContext context) {
    int dis = radius.toInt();
    // TODO: implement build
    return Scaffold(
      // 1
      body: Stack(
        children: <Widget>[
          new GoogleMap(
            // 2
            initialCameraPosition: _initPosition,
            // 3
            mapType: MapType.normal,
            onTap: (pos) {
              Marker m = new Marker(markerId: MarkerId("asas"), position: pos);
              Circle c = new Circle(
                  circleId: CircleId("1"),
                  center: pos,
                  radius: radisInitial,
                  fillColor: Color.fromRGBO(0, 0, 255, 0.2),
                  strokeWidth: 1,
                  strokeColor: Colors.blue);
              setState(() {
                markers.add(m);
                circles.add(c);
                // filterController.mapData = new FilterFromMap(pos, radisInitial);
                filterController.center = pos;
                filterController.radius = radisInitial;
              });
            },
            // 4
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            markers: markers,
            circles: circles,
          ),
          Padding(
              padding: const EdgeInsets.fromLTRB(5, 8, 20, 0),
              child: Align(
                alignment: Alignment.topRight,
                child: Text(
                  "${dis}KM",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
                alignment: Alignment.topRight,
                child: RotatedBox(
                  quarterTurns: 1,
                  child: CupertinoSlider(
                    value: radius,
                    onChanged: (newDis) {
                      Circle c = new Circle(
                          circleId: CircleId("1"),
                          center: circles.last.center,
                          radius: newDis * 1000,
                          fillColor: Color.fromRGBO(0, 0, 255, 0.2),
                          strokeWidth: 1,
                          strokeColor: Colors.blue);
                      radius = newDis;
                      setState(() {
                        circles.add(c);
                        filterController.center = circles.last.center;
                        filterController.radius = newDis;
                        // new FilterFromMap(circles.last.center, newDis);
                      });
                    },
                    min: 0,
                    max: 20,
                  ),
                )),
          ),
        ],
      ),
    );
  }
}

class FilterMapController {
  LatLng center;
  double radius;

  FilterMapController(this.center, this.radius);

}
