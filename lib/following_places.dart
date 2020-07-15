import 'package:Xfeedm/location_feed.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'image_post.dart';

class FollowingPlaces extends StatefulWidget {
  final String userId;
  const FollowingPlaces({Key key, this.userId}) : super(key: key);
  @override
  _FollowingPlaces createState() => new _FollowingPlaces(this.userId);
}
class LocationWrapper{
  final String locationName;
  final int numOfPosts;

  LocationWrapper(this.locationName, this.numOfPosts);
}
class _FollowingPlaces extends State<FollowingPlaces> {
  // List<String> items = new List.generate(100, (index) => 'Hello $index');
  final String userID;
  _FollowingPlaces(this.userID);

  @override
  void initState() {
    super.initState();
  }

  Future<List<LocationWrapper>> getUserFollowingPlaces() async {
    List<LocationWrapper> placesName = [];
    var snapPlaces = await Firestore.instance
        .collection('activities')
        .document(userID)
        .collection('followingPlaces')
        .getDocuments();

    for (var item in snapPlaces.documents) {
      var placeNameSnap = await Firestore.instance
          .collection('geoLocation')
          .document(item.documentID)
          .get();
      placesName.add(new LocationWrapper(placeNameSnap.data['d']['name'], placeNameSnap.data['d']['posts'].length));
    }
    return placesName;
  }

  @override
  Widget build(Object context) {
    // TODO: implement build
    return Scaffold(
      body: FutureBuilder(
        future: getUserFollowingPlaces(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Container(
                alignment: FractionalOffset.center,
                child: CircularProgressIndicator());
          List<LocationWrapper> all_places = snapshot.data;
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: Text(
                "Locations",
                style: TextStyle(color: Colors.black),
              ),
            ),
            
            body: ListView.builder(
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.pin_drop),
                    title:  GestureDetector(child:Text(
                      all_places[index].locationName,
                      style: TextStyle(color: Colors.black),
                    ),onTap: (){openLocationFeed(context, all_places[index].locationName, "");},),
                    trailing: Text(
                      "${all_places[index].numOfPosts}",
                      style: TextStyle(color: Colors.black),
                    ),
                  );
                },
                itemCount: all_places.length),
          );
        },
      ),
    );
  }
}
