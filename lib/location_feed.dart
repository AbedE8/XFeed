import 'dart:convert';
import 'dart:io';
import 'feed.dart';
import 'package:flutter/material.dart';
import 'feed_list_view.dart';
import 'image_post.dart';
import 'server_controller.dart';

var serverController = ServerController();

void openLocationFeed(BuildContext context, String location) {
  Navigator.of(context)
      .push(MaterialPageRoute<bool>(builder: (BuildContext context) {
    return LocationFeedPage(location: location);
  }));
}

class LocationFeedPage extends StatefulWidget {
  const LocationFeedPage({this.location});
  final String location;

  _LocationFeedPage createState() => _LocationFeedPage(this.location);
}

class _LocationFeedPage extends State<LocationFeedPage> {
  _LocationFeedPage(this.location);
  final String location; //feature_name

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: new AppBar(title: Text(location, style: TextStyle(color: Colors.black),), backgroundColor: Colors.white,),
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
                    return FeedListView(posts: listOfPosts, postsID: postsID, itsLocationFeed: true);
                  }

                  print("failed to get data from server.");
                  return Container();
                })));
  }
}
