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

class Feed extends StatefulWidget {
  _Feed createState() => _Feed();
}

class _Feed extends State<Feed> with AutomaticKeepAliveClientMixin<Feed> {
  List<ImagePost> feedData;
  UserPreference filterData = null;
  Coordinates cordinate;
  @override
  void initState() {
    super.initState();
    this._loadFeed();
    initLocation();
  }
  initLocation () async {
   Coordinates cordinate_1 = await getUserCordinate();
    setState(() {
      cordinate = cordinate_1;
    });
  }
  buildFeed() {
    if (feedData != null) {
      return ListView(
        children: feedData,
      );
      
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
                filterData = await Navigator.push(context,
                        MaterialPageRoute(builder: (context) => FilterPosts(currentUserModel.preferences)))
                    as UserPreference;
                print("back from filter page "+filterData.toString());
                if (filterData != null) {
                  setState(() {
                    feedData = null; //should set feedData to null in order to stop showing same old feed
                  });
                  await _updateUserPreference();
                  _getFeed();
                }
              },
            );
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: feedData != null ? ListView.builder(itemBuilder: (context,index){
          return feedData[index];
        } ,itemCount: feedData.length): Text(""),/*buildFeed(),*/
      ),
    );
  }
  _updateUserPreference() async{
    if (filterData == null){
      return;
    }
    await Firestore.instance
    .collection("post_preferences")
    .document(currentUserModel.id).setData({
      "categories":filterData.categories,
      "radius":filterData.radious,
      "location":filterData.location,
      "min_age":filterData.min_age,
      "max_age":filterData.max_age
    });
    //need to update currentUserModel because of post preferences change
    updateCurrentUser(currentUserModel, filterData);
  }
  Future<Null> _refresh() async {
    print("asked for refresh give him more ");
    await _getFeed();

    setState(() {});

    return;
  }

  _loadFeed() async {

      _getFeed();
  }
  
  bool validate(Map<String, dynamic> data) {
    int num_of_posts = data['num_of_posts'];
    if(num_of_posts == 0)
    {
      return false;
    }
    else{
      return true;
    }
    
  }
  _getFeed() async {
    print("Staring getFeed");

    SharedPreferences prefs = await SharedPreferences.getInstance();

    String userId = currentUserModel.id.toString();

    var url = 'https://us-central1-xfeed-497fe.cloudfunctions.net/getFeed?uid=' + userId;
    
    print("url is "+url);
    var httpClient = HttpClient();

    List<ImagePost> listOfPosts;
    String result;
    try {
      var request = await httpClient.getUrl(Uri.parse(url));
      var response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        String json = await response.transform(utf8.decoder).join();
        prefs.setString("feed", json);
        print("json is "+json);

        Map<String, dynamic> data_in_json = jsonDecode(json);
        print("num_of_posts "+data_in_json['num_of_posts'].toString());
        List<Map<String, dynamic>> data = data_in_json['posts'].cast<Map<String, dynamic>>();
        if (validate(data_in_json) == true){
          int num_of_posts = data_in_json['num_of_posts'];
          listOfPosts = await _generateFeed(data, num_of_posts);

        }
        else{
          print("data from server failed in validation");
        }
        //String post_id = data[1]['post_id'];
        //print("list is "+post_id)
        result = "Success in http request for feed";
      } else {
        result =
            'Error getting a feed: Http status ${response.statusCode} | userId $userId';
      }
    } catch (exception) {
      result = 'Failed invoking the getFeed function. Exception: $exception';
    }
    print(result);

    setState(() {
      feedData = listOfPosts;
      filterData = null;
    });
  }

  Future<List<ImagePost>> _generateFeed(List<Map<String, dynamic>> feedData, int num_of_posts) async {
    List<ImagePost> listOfPosts = [];
    var i ;

    for ( i = 0; i < num_of_posts; i++) {
      listOfPosts.add(await ImagePost.fromJSON(feedData[i]));
    }
    for (var j = i; j < feedData.length; j++) {
      listOfPosts.add(await ImagePost.fromID(feedData[j]['post_id']));
    } 

    return listOfPosts;
  }

  // ensures state is kept when switching pages
  @override
  bool get wantKeepAlive => true;
}
