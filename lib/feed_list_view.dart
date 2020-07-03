import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'image_post.dart';

class FeedListView extends StatefulWidget {
  final List<ImagePost> posts;
  final List<String> postsID;
  final bool itsLocationFeed;
  const FeedListView({Key key, this.posts, this.postsID, this.itsLocationFeed})
      : super(key: key);
  @override
  _MyFeedListViewState createState() =>
      new _MyFeedListViewState(this.posts, this.postsID, this.itsLocationFeed);
}

class _MyFeedListViewState extends State<FeedListView> {
  final List<ImagePost> posts;
  final List<String> postsID;
  Map<String, ImagePost> gen_ImagePost = {};
  ScrollController controller;
  static const int postsToFetch = 1;
  static const int initPostsToFetch = 1;
  final bool itsLocationFeed;

  // List<String> items = new List.generate(100, (index) => 'Hello $index');

  _MyFeedListViewState(this.posts, this.postsID, this.itsLocationFeed);

  @override
  void initState() {
    super.initState();
    controller = new ScrollController()..addListener(_scrollListener);

    for (var id in postsID) {
      gen_ImagePost[id] = null;
    }
    Future<List<ImagePost>> newPosts = fetchPostsFromId(initPostsToFetch);
    newPosts.then((value) => {
      if(value!=null){
        value.forEach((element) {updateList(element);})
      }
      
    });
  }
  void printMap(){
    print("printing map");
    for (var key in gen_ImagePost.keys) {
      print("key: "+key.toString());
    }
  }
  updateList(ImagePost value) {
    gen_ImagePost[value.postId] = value;   
    if (gen_ImagePost.keys.first.compareTo(value.postId) == 0) {
      setState(() {
        List<String> map_keys = gen_ImagePost.keys.toList();
        for (var key in map_keys) {
          if (gen_ImagePost[key] == null) {
            return;
          } else {
            posts.add(gen_ImagePost[key]);
            gen_ImagePost.removeWhere((key_map, value) => key_map.compareTo(key)==0);
          }
        }
      });
    }
  }

  Future<List<ImagePost>> fetchPostsFromId(int num_of_posts) async {
    int num_posts_to_fetch = min(num_of_posts, postsID.length);

    if (num_posts_to_fetch == 0) {
      return null;
    }

    List<String> ids = postsID.getRange(0, num_posts_to_fetch).toList();
    postsID.removeRange(0, num_posts_to_fetch);
    List<ImagePost> to_return = [];
    for (var id in ids) {
      to_return.add(await ImagePost.fromID(id, this.itsLocationFeed));
    }
    return to_return;
  }

  @override
  void dispose() {
    controller.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Scrollbar(
        child: new ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: controller,
          itemBuilder: (context, index) {
            return posts[index];
          },
          itemCount: posts.length,
        ),
      ),
    );
  }

  void _scrollListener() async {
    // print(controller.position.extentAfter);

    if (controller.position.extentAfter < 100) {
      print("arrived to the end");

      if (postsID.length == 0) {
        controller.removeListener(_scrollListener);
        return;
      }
      Future<List<ImagePost>> newPosts =  fetchPostsFromId(postsToFetch);
      newPosts.then((value) => {

        if(value!=null){
          value.forEach((element) => {updateList(element)})
        }
      });
      print("has " + postsID.length.toString());
    }
  
  }
}
