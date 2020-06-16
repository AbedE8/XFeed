import 'package:Xfeedm/chat_main_page.dart';
import 'package:Xfeedm/feed_list_view.dart';
import 'package:Xfeedm/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'filter_page.dart';
import 'image_post.dart';
import 'dart:async';
import 'location.dart';
import 'main.dart';
import 'dart:io';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'server_controller.dart';

class Feed extends StatefulWidget {
  _Feed createState() => _Feed();
}

class _Feed extends State<Feed> with AutomaticKeepAliveClientMixin<Feed> {
  List<ImagePost> feedData;
  bool shouldSendRequest = false;
  List<String> feedPostsID = [];
  int num_of_return_posts =
      -1; //the initial value because at the beggining we dont now the num of posts
  Coordinates cordinate;
  @override
  void initState() {
    super.initState();
    this._getFeed(true);
    initLocation();
  }

  initLocation() async {
    Coordinates cordinate_1 = await getUserCordinate();
    setState(() {
      cordinate = cordinate_1;
    });
  }

  buildFeed() {
    if (num_of_return_posts == 0) {
      return Container(
          alignment: FractionalOffset.center,
          child: Text("No posts to show", style: TextStyle(fontSize: 20)));
    } else if (feedData != null) {
      return FeedListView(
          posts: feedData, postsID: feedPostsID, itsLocationFeed: false);
    } else {
      return Container(
          alignment: FractionalOffset.center,
          child: CircularProgressIndicator());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // reloads state when opened again

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xfeed',
            style: const TextStyle(
                fontFamily: "Billabong", color: Colors.black, fontSize: 35.0)),
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(
                Icons.filter,
              ),
              onPressed: () async {
                shouldSendRequest = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            FilterPosts(currentUserModel.preferences))) as bool;
                print("back from filter page shouldSendRequest " +
                    shouldSendRequest.toString());
                if (shouldSendRequest) {
                  clearUI();
                  // await _updateUserPreference();
                  _getFeed(false);
                }
              },
            );
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.chat,
            ),
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => ChatPage()));
            },
          )
        ],
      ),
      body: RefreshIndicator(onRefresh: _refresh, child: buildFeed()),
    );
  }

  void clearUI() {
    setState(() {
      feedData =
          null; //should set feedData to null in order to stop showing same old feed
      num_of_return_posts = -1;
    });
  }

  Future<Null> _refresh() async {
    print("asked for refresh give him more ");
    clearUI();
    _getFeed(false);

    return;
  }

  Future<List<String>> _fetchAllPostsForTest() async {
    var snap = await Firestore.instance.collection('posts').getDocuments();
    List<String> postsIds = new List();
    for (var item in snap.documents) {
      postsIds.add(item.documentID);
    }
    return postsIds;
  }

  _getFeed(bool fromCache) async {
    print("Staring getFeed fromCache " + fromCache.toString());
    var res;
    bool feed_from_server = false;
    if (fromCache) {
      print("fetching from cache");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String data = prefs.getString("feed");

      if (data != null && data.isNotEmpty) {
        Map<String, dynamic> data_in_json = jsonDecode(data);
        Map<String, dynamic> parsedFeed =
            await ServerController.parseFeedFromJson(data_in_json, false);

        res = [
          data_in_json['num_of_posts'],
          parsedFeed['posts'],
          parsedFeed['postsId']
        ];
      } else {
        print("no data in cache");
        feed_from_server = true;
      }
      print("data is " + res.toString());
    }
    if (!fromCache || feed_from_server) {
      String userId = currentUserModel.id.toString();
      var serverController = ServerController();
      res = await serverController.getFeed(userId);
    }

    setState(() {
      num_of_return_posts = res[resIndexValue.NUM_OF_POSTS.index];
      feedData = res[resIndexValue.POST_LIST.index];
      feedPostsID = res[resIndexValue.POSTS_ID_LIST.index];
    });
  }

  // ensures state is kept when switching pages
  @override
  bool get wantKeepAlive => true;
}
