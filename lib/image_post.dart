import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'location_feed.dart';
import 'main.dart';
import 'dart:async';
import 'profile_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'comment_screen.dart';
import 'package:flare_flutter/flare_actor.dart';

class ImagePost extends StatefulWidget {
  ImagePost(
      {this.mediaUrl,
      this.username,
      this.location,
      this.description,
      this.likes,
      this.postId,
      this.ownerId,
      this.activities,
      this.timeStr});

  static var users_reference = Firestore.instance.collection('users');
  static var posts_reference = Firestore.instance.collection('posts');

  static String timePassed(Duration duration) {
    String suffix = " a go";


    if (duration.inDays != 0) {
      return duration.inDays.toString() + " days" + suffix;
    }
    if (duration.inHours != 0) {
      return duration.inHours.toString() + " hours" + suffix;
    }
    if (duration.inMinutes != 0) {
      return duration.inMinutes.toString() + " mins" + suffix;
    }
  }

  static DateTime fromTimestamp(int seconds, int nanoseconds) {
    // var test = data.cast
    double nanotomilli = (nanoseconds / 1000000);
    double timeInMilli = (seconds * 1000) + nanotomilli;
    DateTime postTime = DateTime.fromMillisecondsSinceEpoch(timeInMilli.toInt());
    return postTime;
  }

  static Future<ImagePost> fromDocument(DocumentSnapshot document) async {
    var userRef = document.data['publisher'];
    var userData = await users_reference.document(userRef).get();
    DateTime postTime = document.data['timeStamp'].toDate();
    // DateTime postTime = DateTime.now();
    // print("creating image of time default"+postTime.toString());
    // print("creating image of time utc"+postTime.toUtc().toString());
    // print("creating image of time local"+postTime.toLocal().toString());
    // print("date now is "+DateTime.now().toString() +" post time utc"+ postTime.toUtc().toString());
    Duration differ = DateTime.now().difference(postTime.toUtc());
    return ImagePost(
        username: userData.data['username'],
        location: document.data['feature_name'],
        mediaUrl: document.data['img_url'],
        likes: document.data['likes'],
        description: document.data['description'],
        postId: document.documentID,
        ownerId: document.data['publisher'],
        activities: document.data['category'],
        timeStr: timePassed(differ));
  }

  static Future<ImagePost> fromJSON(Map<String, dynamic> data) async {
    var userRef = data['publisher'];
    DocumentSnapshot userData = await users_reference.document(userRef).get();

    int seconds = data['timeStamp']['_seconds'];
    int nano = data['timeStamp']['_nanoseconds'];

    DateTime postTime = fromTimestamp(seconds, nano);
    Duration differ = DateTime.now().difference(postTime);

    return ImagePost(
        username: userData.data['username'],
        location: data['feature_name'],
        mediaUrl: data['img_url'],
        likes: data['likes'],
        description: data['description'],
        ownerId: data['publisher'],
        postId: data['id'],
        activities: data['category'],
        timeStr: timePassed(differ));
  }
 //TODO: inc view only if asked for (location_feed dont need to inc view on the recived posts but get_feed should inc).
  static Future<ImagePost> fromID(String postID) async {
    DocumentSnapshot postData = await posts_reference.document(postID).get();
    posts_reference
        .document(postID)
        .updateData({'views': FieldValue.increment(1)});
    return await fromDocument(postData);
  }

  int getLikeCount(var likes) {
    if (likes == null) {
      return 0;
    }
// issue is below
    var vals = likes.values;
    int count = 0;
    for (var val in vals) {
      if (val == true) {
        count = count + 1;
      }
    }

    return count;
  }

  final String mediaUrl;
  final String username;
  final String location;
  final String description;
  final String timeStr;
  final likes;
  final String postId;
  final String ownerId;
  final activities;
  // FloatingActionButton loc = new FloatingActionButton(onPressed: null)
  _ImagePost createState() => _ImagePost(
      mediaUrl: this.mediaUrl,
      username: this.username,
      location: this.location,
      description: this.description,
      likes: this.likes,
      likeCount: getLikeCount(this.likes),
      ownerId: this.ownerId,
      postId: this.postId,
      activities: this.activities,
      timeStr: timeStr);
}

class _ImagePost extends State<ImagePost> {
  final String mediaUrl;
  final String username;
  final String location;
  final String description;
  final List<dynamic> activities;
  final String timeStr;
  Map likes;
  int likeCount;
  final String postId;
  bool liked;
  final String ownerId;

  bool showHeart = false;

  TextStyle boldStyle = TextStyle(
    color: Colors.black,
    fontWeight: FontWeight.bold,
  );

  var reference = Firestore.instance.collection('posts');

  _ImagePost(
      {this.mediaUrl,
      this.username,
      this.location,
      this.description,
      this.likes,
      this.postId,
      this.likeCount,
      this.ownerId,
      this.activities,
      this.timeStr});

  GestureDetector buildLikeIcon() {
    Color color;
    IconData icon;

    if (liked) {
      color = Colors.pink;
      icon = FontAwesomeIcons.solidHeart;
    } else {
      icon = FontAwesomeIcons.heart;
    }

    return GestureDetector(
        child: Icon(
          icon,
          size: 25.0,
          color: color,
        ),
        onTap: () {
          _likePost(postId);
        });
  }

  GestureDetector buildLikeableImage() {
    return GestureDetector(
      onDoubleTap: () => _likePost(postId),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CachedNetworkImage(
            imageUrl: mediaUrl,
            fit: BoxFit.fitWidth,
            placeholder: (context, url) => loadingPlaceHolder,
            errorWidget: (context, url, error) => Icon(Icons.error),
          ),
          showHeart
              ? Positioned(
                  child: Container(
                    width: 100,
                    height: 100,
                    child: Opacity(
                        opacity: 0.85,
                        child: FlareActor(
                          "assets/flare/Like.flr",
                          animation: "Like",
                        )),
                  ),
                )
              : Container()
        ],
      ),
    );
  }

  buildPostHeader({String ownerId}) {
    if (ownerId == null) {
      return Text("owner error");
    }

    return FutureBuilder(
        future: Firestore.instance.collection('users').document(ownerId).get(),
        builder: (context, snapshot) {
          if (snapshot.data != null) {
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(
                    snapshot.data.data['profile_pic_url']),
                backgroundColor: Colors.grey,
              ),
              title: GestureDetector(
                child: Text(snapshot.data.data['username'], style: boldStyle),
                onTap: () {
                  openProfile(context, ownerId);
                },
              ),
              subtitle: GestureDetector(
                child: Text(this.location),
                onTap: () {
                  openLocationFeed(context, this.location);
                },
              ),
              //trailing: const Icon(Icons.more_vert),
              trailing: Text(
                  this.activities == null ? "NA" : this.activities.toString()),
            );
          }

          // snapshot data is null here
          return Container();
        });
  }

  Container loadingPlaceHolder = Container(
    height: 400.0,
    child: Center(child: CircularProgressIndicator()),
  );

  @override
  Widget build(BuildContext context) {
    liked = (likes[currentUserModel.id.toString()] == true);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(ownerId: ownerId),
        buildLikeableImage(),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: const EdgeInsets.only(left: 20.0, top: 40.0)),
            buildLikeIcon(),
            Padding(padding: const EdgeInsets.only(right: 20.0)),
            GestureDetector(
                child: const Icon(
                  FontAwesomeIcons.comment,
                  size: 25.0,
                ),
                onTap: () {
                  goToComments(
                      context: context,
                      postId: postId,
                      ownerId: ownerId,
                      mediaUrl: mediaUrl);
                }),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(left: 20.0),
              child: Text(
                "$likeCount likes",
                style: boldStyle,
              ),
            )
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
                margin: const EdgeInsets.only(left: 20.0),
                child: Text(
                  "$username ",
                  style: boldStyle,
                )),
            Expanded(child: Text(description)),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
                margin: const EdgeInsets.fromLTRB(20, 5, 0, 5),
                child: Text(
                  "$timeStr ",
                  
                )),
          ],
        ),
      ],
    );
  }

  void _likePost(String postId2) {
    var userId = currentUserModel.id;
    bool _liked = likes[userId] == true;

    if (_liked) {
      print('removing like');
      reference.document(postId).updateData({
        'likes.$userId': false
        //firestore plugin doesnt support deleting, so it must be nulled / falsed
      });

      setState(() {
        likeCount = likeCount - 1;
        liked = false;
        likes[userId] = false;
      });

      removeActivityFeedItem();
    }

    if (!_liked) {
      print('liking');
      reference.document(postId).updateData({'likes.$userId': true});

      addActivityFeedItem();

      setState(() {
        likeCount = likeCount + 1;
        liked = true;
        likes[userId] = true;
        showHeart = true;
      });
      Timer(const Duration(milliseconds: 2000), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  void addActivityFeedItem() {
    Firestore.instance
        .collection("activities")
        .document(ownerId)
        .collection("items")
        .document(postId)
        .setData({
      "username": currentUserModel.username,
      "userId": currentUserModel.id,
      "type": "like",
      "userProfileImg": currentUserModel.photoUrl,
      "mediaUrl": mediaUrl,
      "timestamp": DateTime.now(),
      "postId": postId,
    });
  }

  void removeActivityFeedItem() {
    Firestore.instance
        .collection("activities")
        .document(ownerId)
        .collection("items")
        .document(postId)
        .delete();
  }
}

class ImagePostFromId extends StatelessWidget {
  final String id;

  const ImagePostFromId({this.id});

  getImagePost() async {
    var document =
        await Firestore.instance.collection('posts').document(id).get();
    return ImagePost.fromDocument(document);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getImagePost(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Container(
                alignment: FractionalOffset.center,
                padding: const EdgeInsets.only(top: 10.0),
                child: CircularProgressIndicator());
          return snapshot.data;
        });
  }
}

void goToComments(
    {BuildContext context, String postId, String ownerId, String mediaUrl}) {
  Navigator.of(context)
      .push(MaterialPageRoute<bool>(builder: (BuildContext context) {
    return CommentScreen(
      postId: postId,
      postOwner: ownerId,
      postMediaUrl: mediaUrl,
    );
  }));
}
