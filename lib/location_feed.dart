import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'feed.dart';
import 'package:flutter/material.dart';
import 'feed_list_view.dart';
import 'image_post.dart';
import 'server_controller.dart';
import 'profile_page.dart';
import 'main.dart';

var serverController = ServerController();

void openLocationFeed(
    BuildContext context, String location, String postOwnerID) {
  Navigator.of(context)
      .push(MaterialPageRoute<bool>(builder: (BuildContext context) {
    return LocationFeedPage(
      location: location,
      postOwnerId: postOwnerID,
    );
  }));
}

class LocationFeedPage extends StatefulWidget {
  const LocationFeedPage({this.location, this.postOwnerId});
  final String location;
  final String postOwnerId;

  _LocationFeedPage createState() =>
      _LocationFeedPage(this.location, this.postOwnerId);
}

class _LocationFeedPage extends State<LocationFeedPage> {
  _LocationFeedPage(this.location, this.postOwnerId);
  final String location; //feature_name
  final String postOwnerId;
  bool is_followed = false;
  String locationID = null;

  @override
  void initState() {
    super.initState();
  }

  void updateFollowingPlaces(String placeID, bool follow) async {
    if (placeID == null) {
      print("cant follow place with placeID null");
      return;
    }
    if (follow) {
      Future<DocumentSnapshot> geoLocationSnap = Firestore.instance.collection("geoLocation").document(placeID).get();
      await geoLocationSnap.then((geoLocation) => {
          Firestore.instance
            .collection('activities')
            .document(currentUserModel.id)
            .collection('followingPlaces')
            .document(placeID)
            .setData(geoLocation.data).then(
                (value) => {
                      Firestore.instance
                          .collection('users')
                          .document(currentUserModel.id)
                          .updateData(
                              {'followingPlaces': FieldValue.increment(1)})
                    })
      });

      var a = await Firestore.instance
        .collection('activities')
        .document(currentUserModel.id)
        .collection('followingPlaces')
        .document(placeID);
      a.get().then((value) async => {
        await a.updateData({'d': {'name': value.data['d']['name']}})
      });
      
    } else {
      Firestore.instance
          .collection('activities')
          .document(currentUserModel.id)
          .collection('followingPlaces')
          .document(placeID)
          .delete()
          .then((value) => {
                Firestore.instance
                    .collection('users')
                    .document(currentUserModel.id)
                    .updateData({'followingPlaces': FieldValue.increment(-1)})
              });
    }
  }

  void followThisPlace() {
    print("function has been called");
    setState(() {is_followed = !is_followed;});
    updateFollowingPlaces(locationID, is_followed);
    
  }

  Future<bool> isPlaceInFollow(String locationName) async {
    print("asking for place in follow 0000000000000");
    if (locationID == null) {
      var locationSnap = await Firestore.instance
          .collection('geoLocation')
          .where('d.name', isEqualTo: location)
          .getDocuments();
      locationID = locationSnap.documents.first.documentID;
    }
    var snap = await Firestore.instance
        .collection('activities')
        .document(currentUserModel.id)
        .collection('followingPlaces')
        .document(locationID)
        .get();
    if (snap.data != null) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    print("building new page");
    return FutureBuilder(
      future: isPlaceInFollow(location),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(body:Container(
              alignment: FractionalOffset.center,
              padding: const EdgeInsets.only(top: 10.0),
              child: CircularProgressIndicator()));
        }
        bool place_in_follow = snapshot.data || is_followed;
        // is_followed |= place_in_follow;
        print("lace_in_follow is "+place_in_follow.toString()+" is_followed "+is_followed.toString());
        return Scaffold(
            appBar: new AppBar(
              title: Text(
                location,
                style: TextStyle(color: Colors.black),
              ),
              backgroundColor: Colors.white,
              actions: <Widget>[
                buildFollowButton(
                  text: place_in_follow ? "Following" : "Follow",
                  backgroundcolor: place_in_follow ? Colors.blue : Colors.white,
                  textColor: place_in_follow ? Colors.white : Colors.black45,
                  borderColor: Colors.grey,
                  width: 70.0,
                  function: followThisPlace,
                )
              ],
            ),
            body: Container(
                child: FutureBuilder(
                    future: serverController.getLocationFeed(location),
                    builder: (context, snapLocationPosts) {
                      var locationPosts;
                      List<ImagePost> listOfPosts;
                      List<String> postsID;

                      if (!snapLocationPosts.hasData)
                        return Container(
                            alignment: FractionalOffset.center,
                            padding: const EdgeInsets.only(top: 10.0),
                            child: CircularProgressIndicator());

                      if (snapLocationPosts.data != null) {
                        locationPosts = snapLocationPosts.data;
                        listOfPosts = locationPosts['posts'];
                        postsID = locationPosts['postsId'];
                        return FeedListView(
                            posts: listOfPosts,
                            postsID: postsID,
                            itsLocationFeed: true);
                      }

                      print("failed to get data from server.");
                      return Container();
                    })));
      },
    );
  }
}
