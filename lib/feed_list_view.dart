import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'image_post.dart';

class FeedListView extends StatefulWidget {
  final List<ImagePost> posts;
  final List<String> postsID;
  final bool itsLocationFeed;
  const FeedListView({Key key, this.posts, this.postsID, this.itsLocationFeed}) : super(key: key);
  @override
  _MyFeedListViewState createState() =>
      new _MyFeedListViewState(this.posts, this.postsID, this.itsLocationFeed);
}

class _MyFeedListViewState extends State<FeedListView> {
  final List<ImagePost> posts;
  final List<String> postsID;
  ScrollController controller;
  static const int postsToFetch = 1;
  static const int initPostsToFetch = 3;
  final bool itsLocationFeed;
  
  // List<String> items = new List.generate(100, (index) => 'Hello $index');

  _MyFeedListViewState(this.posts, this.postsID, this.itsLocationFeed);

  @override
  void initState() {
    super.initState();
    controller = new ScrollController()..addListener(_scrollListener);
    if (posts.length < 2) {
      Future<List<ImagePost>> newPosts = fetchPostsFromId(initPostsToFetch);
      newPosts.then((value) => updateList(value));
    }
  }

  updateList(List<ImagePost> value) {
    // print("back from async update posts lists");
    setState(() {
      if (value != null) {
        posts.addAll(value);
      }
    });
  }

  Future<List<ImagePost>> fetchPostsFromId(int num_of_posts) async {
    int num_posts_to_fetch = min(num_of_posts, postsID.length);
    // print("About to fetch " + num_posts_to_fetch.toString() + " from postIds");
    if (num_posts_to_fetch == 0) {
      // print("no more post ids ");
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
          physics: const AlwaysScrollableScrollPhysics (),
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
    if (controller.position.extentAfter < 500) {
      // print("arrived to the end");
      Future<List<ImagePost>> newPosts = fetchPostsFromId(postsToFetch);
      newPosts.then((value) => updateList(value));
    
    }
  }
}
