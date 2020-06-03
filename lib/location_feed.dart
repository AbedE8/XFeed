import 'dart:convert';
import 'dart:io';
import 'feed.dart';
import 'package:flutter/material.dart';

import 'feed_list_view.dart';
import 'image_post.dart';

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
                future: getLocationPosts(),
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

                    return FeedListView(posts: listOfPosts, postsID: postsID);
                  }

                  print("failed to get data from server.");
                  return Container();
                })));
  }

  getLocationPosts() async {
    var httpClient = HttpClient();
    var url =
        'https://us-central1-xfeed-497fe.cloudfunctions.net/getLocationFeed?feature_name=' +
            location;

    print("url is " + url);
    String result;
    try {
      var request = await httpClient.getUrl(Uri.parse(url));
      var response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        String json = await response.transform(utf8.decoder).join();
        print("json is " + json);

        Map<String, dynamic> data_in_json = jsonDecode(json);
        print("num_of_posts " + data_in_json['num_of_posts'].toString());
        List<Map<String, dynamic>> data =
            data_in_json['posts'].cast<Map<String, dynamic>>();
        if (validate(data_in_json) == true) {
          Map<String, dynamic> parsedFeed =
              await parseFeedFromJson(data_in_json);
          return parsedFeed;
        } else {
          print("data from server failed in validation");
        }
        result = "Success in http request for feed";
      } else {
        result = 'Error getting a location feed: Http status ${response.statusCode}';
      }
    } catch (exception) {
      result = 'Failed invoking the getLocationFeed function. Exception: $exception';
    }
    print(result);

    return null;
  }
}
