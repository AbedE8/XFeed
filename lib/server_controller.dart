import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'image_post.dart';
import 'main.dart';

enum resIndexValue {
  NUM_OF_POSTS,
  POST_LIST,
  POSTS_ID_LIST
}

/*singleton pattern*/
class ServerController{
  static final ServerController _serverController = ServerController._internal();
  var httpClient = HttpClient();
  String serverUrl ='https://us-central1-xfeed-497fe.cloudfunctions.net/';

  factory ServerController() {
    return _serverController;
  }

  ServerController._internal();

  getFeed(String userId, String explore_param) async{
    var url = serverUrl + 'getFeed?uid=' + userId+'&feedMode=' + explore_param; 
    var num_of_posts;
    var listOfPosts; 
    var postsID;
    var result;
    
    try {
      var request = await httpClient.getUrl(Uri.parse(url));
      var response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        String json = await response.transform(utf8.decoder).join();
        Map<String, dynamic> data_in_json = jsonDecode(json);
        if (validate(data_in_json) == true) {
          Map<String, dynamic> parsedFeed = await parseFeedFromJson(data_in_json, false);
          num_of_posts = data_in_json['num_of_posts'];
          listOfPosts = parsedFeed['posts'];
          postsID = parsedFeed['postsId'];
          SharedPreferences prefs =  await SharedPreferences.getInstance();
          prefs.setString('feed', json);
        } else {
          print("data from server failed in validation");
        }
        result = "Success in http request for feed";
      } else {
        result = 'Error getting a feed: Http status ${response.statusCode} | userId $userId';
      }
    } catch (exception) {
      result = 'Failed invoking the getFeed function. Exception: $exception';
    }

    return [num_of_posts, listOfPosts, postsID];
  }

  getLocationFeed(String location) async{
    var result;
    var url = serverUrl + 'getLocationFeed?feature_name=' + location;
    try{
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
              await parseFeedFromJson(data_in_json, true);
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

  uploadPost({String mediaUrl, String location, String description, Set<String> activity,
            Coordinates point, Set<String> genders, RangeValues ageRange}) async {
    
    var req_body = jsonEncode(<String, dynamic>{
      'lng': "${point.longitude}",
      'lat': "${point.latitude}",
      'feature_name': location,
      'img_url': mediaUrl,
      'description': description,
      "uid": currentUserModel.id.toString(),
      "timestamp": DateTime.now().toUtc().toString(),
      "category": activity.toList(),
      "genders": genders.toList(),
      "min_age": ageRange.start.toInt(),
      "max_age": ageRange.end.toInt()
    });
    print('upload post with time '+DateTime.now().toUtc().toString());
    final http.Response response = await http.post(
        serverUrl + 'uploadPost',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: req_body);
  }
  
 userArrivedLocation(String userId, String publisherId) async{
    var req_body = jsonEncode(<String, dynamic>{
      'userId': userId,
      'publisherId': publisherId
    });
    await http.post(
        serverUrl + 'userArriveToLocation',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: req_body);
    print("inform server that user arrived.");
  }

  bool validate(Map<String, dynamic> data) {
    if (!data.containsKey('num_of_posts')) {
      return false;
    } else {
      return true;
    }
  }

  static Future<Map<String, dynamic>> parseFeedFromJson(Map<String, dynamic> data_in_json, bool itsLocationFeed) async {
    int num_of_posts = data_in_json['num_of_posts'];
    List<Map<String, dynamic>> posts =
        data_in_json['posts'].cast<Map<String, dynamic>>();
    List<ImagePost> listOfPosts = [];
    List<String> listOfPostsId = [];
    var i;

    for (i = 0; i < num_of_posts; i++) {
      listOfPosts.add(await ImagePost.fromJSON(posts[i], itsLocationFeed));
    }
    for (var j = i; j < posts.length; j++) {
      listOfPostsId.add(posts[j]['post_id']);
    }

    return {'posts': listOfPosts, 'postsId': listOfPostsId};
  }
}

