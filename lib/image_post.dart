import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:Xfeedm/categories.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:location/location.dart';
import 'location_feed.dart';
import 'main.dart';
import 'dart:async';
import 'models/user.dart';
import 'profile_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'comment_screen.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:timeago/timeago.dart' as timeago;

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
      this.timeStr,
      this.numComments});

  static var users_reference = Firestore.instance.collection('users');
  static var posts_reference = Firestore.instance.collection('posts');

  static Future<int> getCommentsCount(String postId) async {
    QuerySnapshot data = await Firestore.instance
        .collection("all_comments")
        .document(postId)
        .collection("comments")
        .getDocuments();
    if (data.documents != null) {
      return data.documents.length;
    }
    return 0;
  }

  static DateTime fromTimestamp(int seconds, int nanoseconds) {
    // var test = data.cast
    double nanotomilli = (nanoseconds / 1000000);
    double timeInMilli = (seconds * 1000) + nanotomilli;
    DateTime postTime =
        DateTime.fromMillisecondsSinceEpoch(timeInMilli.toInt());
    return postTime;
  }

  static Future<ImagePost> fromDocument(DocumentSnapshot document) async {
    var userRef = document.data['publisher'];
    var userData = await users_reference.document(userRef).get();
    DateTime postTime = document.data['timeStamp'].toDate();
    final now = new DateTime.now();
    Duration differ = now.difference(postTime.toUtc());
    String timePassed = timeago.format(now.subtract(differ));
    int numComments = await getCommentsCount(document.documentID);
    return ImagePost(
        username: userData.data['username'],
        location: document.data['feature_name'],
        mediaUrl: document.data['img_url'],
        likes: document.data['likes'],
        description: document.data['description'],
        postId: document.documentID,
        ownerId: document.data['publisher'],
        activities: document.data['category'],
        timeStr: timePassed,
        numComments: numComments);
  }

  static Future<ImagePost> fromJSON(Map<String, dynamic> data) async {
    var userRef = data['publisher'];
    DocumentSnapshot userData = await users_reference.document(userRef).get();

    int seconds = data['timeStamp']['_seconds'];
    int nano = data['timeStamp']['_nanoseconds'];
    final now = new DateTime.now();
    DateTime postTime = fromTimestamp(seconds, nano);
    Duration differ = now.difference(postTime);
    String timePassed = timeago.format(now.subtract(differ));
    int numComments = await getCommentsCount(data['id']);
    return ImagePost(
        username: userData.data['username'],
        location: data['feature_name'],
        mediaUrl: data['img_url'],
        likes: data['likes'],
        description: data['description'],
        ownerId: data['publisher'],
        postId: data['id'],
        activities: data['category'],
        timeStr: timePassed,
        numComments: numComments);
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
    var keys = likes.keys;
    int count = 0;
    for (var key in keys) {
      if (likes[key] == true) {
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
  final int numComments;
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
      timeStr: timeStr,
      numComments: this.numComments);
}

class _ImagePost extends State<ImagePost> {
  final String mediaUrl;
  final String username;
  final String location;
  final String description;
  final List<dynamic>
      activities; //this is the same of categories, need to delete it later
  final String timeStr;
  final int numComments;
  Map likes;
  int likeCount;
  final String postId;
  bool liked;
  final String ownerId;
  List<String> categories = new List();
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
      this.timeStr,
      this.numComments});
  @override
  void initState() {
    categories = parseActivities(this.activities.toString());
  }

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

  Future<List<User>> getLikesUsers() async {
    List<User> to_return = new List();
    for (var key in this.likes.keys) {
      if (this.likes[key] == true) {
        to_return.add(await User.fromID(key));
      }
    }
    return to_return;
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
                  onTap: () {},
                ),
                trailing: IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () => openLocationFeed(context, this.location),
                ));
          }

          // snapshot data is null here
          return Container();
        });
  }

  Container loadingPlaceHolder = Container(
    height: 400.0,
    child: Center(child: CircularProgressIndicator()),
  );

  List<String> parseActivities(String data) {
    String d = data.substring(1, data.length - 1);
    List<String> dd = d.split(',').map((e) => e.trim()).toList();
    // List<String> to_return = new List.from(dd);

    return dd;
  }

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
            Padding(padding: EdgeInsets.only(left: 60)),
            Wrap(
              spacing: 2,
              children: FeedCategory.buildCirculeCategore(categories),
            ),
            Spacer(flex: 1),
            // Padding(padding: EdgeInsets.only(top:5)),
            Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(padding: EdgeInsets.only(top: 5)),
                Material(
                  // color: Colors.yellow[100],
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () => takeMe(),
                    splashColor: Colors.yellow[50],
                    highlightColor: Colors.yellow[50],
                    child: Container(
                        height: 30,
                        width: 90,
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.blue[300]),
                        ),
                        child: Row(children: <Widget>[
                          Icon(Icons.drive_eta),
                          Center(
                            child: Text("TakeMe"),
                          ),
                        ])),
                  ),
                ),
              ],
            )
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(left: 20.0, bottom: 5),
              child: GestureDetector(
                child: Text(
                  "$likeCount likes",
                  style: boldStyle,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => Center(
                              child: Scaffold(
                                appBar: AppBar(
                                  // leading: Container(),
                                  title: Text('Likes',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold)),
                                  backgroundColor: Colors.white,
                                ),
                                body: Container(
                                    child: FutureBuilder<List<User>>(
                                  future: getLikesUsers(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Center(
                                          child: CircularProgressIndicator());
                                    }
                                    List<User> users = snapshot.data;
                                    return ListView.builder(
                                      padding: const EdgeInsets.all(10),
                                      itemBuilder: (context, index) {
                                        return Column(
                                          children: [
                                            Row(
                                              children: <Widget>[
                                                CircleAvatar(
                                                  backgroundImage: NetworkImage(
                                                      users[index].photoUrl),
                                                ),
                                                Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 20.0)),
                                                Column(
                                                  children: <Widget>[
                                                    GestureDetector(
                                                      child: Text(
                                                          users[index].username,
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                      onTap: () {
                                                        openProfile(context,
                                                            users[index].id);
                                                      },
                                                    ),
                                                    Text(users[index]
                                                        .displayName),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Divider()
                                          ],
                                        );
                                      },
                                      itemCount: users.length,
                                    );
                                  },
                                )),
                              ),
                            )),
                  );
                },
              ),
            ),
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
        this.numComments == 0
            ? Container()
            : Row(crossAxisAlignment: CrossAxisAlignment.start,
              
             children: [
               Container(
                 margin: const EdgeInsets.fromLTRB(20, 5, 0, 5),
                 child: GestureDetector(
                  child: Text(
                    "View all ${this.numComments} comments...",
                  ),
                  onTap: () {
                    goToComments(
                        context: context,
                        postId: postId,
                        ownerId: ownerId,
                        mediaUrl: mediaUrl);
                  },
                ),)
                
              ]),
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

  takeMe() {
    print("takeMe has been pressed");
    showDialog(
      context: context,
      builder: (BuildContext context) => _buildAboutDialog(context),
    );
  }

  Widget _buildAboutDialog(BuildContext context) {
    return new AlertDialog(
      title: const Text('Going with:'),
      actions: <Widget>[
        new RaisedButton.icon(
          onPressed: () => {runWaze(this.location)},
          icon: Icon(Icons.drive_eta),
          label: Text('WAZE'),
          color: Colors.blue[100],
          padding: EdgeInsets.only(right: 10.0, left: 5),
        ),
        // Spacer(flex: 100),
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
        ),
        new RaisedButton.icon(
          onPressed: () => {runGett(this.location)},
          icon: Icon(Icons.local_taxi),
          label: Text('GETT'),
          color: Colors.yellow[100],
          padding: EdgeInsets.only(right: 10.0, left: 5),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
        ),
      ],
    );
  }

  void runWaze(location) async {
    var snapGeoLocationDB = await Firestore.instance
        .collection("geoLocation")
        .where("d.name", isEqualTo: location)
        .getDocuments();
    GeoPoint locationGeoPoint =
        snapGeoLocationDB.documents[0].data['d']['coordinates'];
    var url = 'https://www.waze.com/ul?ll=' +
        locationGeoPoint.latitude.toString() +
        '%2C' +
        locationGeoPoint.longitude.toString() +
        '&navigate=yes&zoom=17';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void runGett(dropoff_location) async {
    Location location = Location();
    LocationData pickupLocation = await location.getLocation();
    var snapGeoLocationDB = await Firestore.instance
        .collection("geoLocation")
        .where("d.name", isEqualTo: dropoff_location)
        .getDocuments();
    GeoPoint dropOff = snapGeoLocationDB.documents[0].data['d']['coordinates'];
    String url = 'gett://order?pickup_latitude=' +
        pickupLocation.latitude.toString() +
        '&pickup_longitude=' +
        pickupLocation.longitude.toString() +
        '&dropoff_latitude=' +
        dropOff.latitude.toString() +
        '&dropoff_longitude=' +
        dropOff.longitude.toString();
    String urlAndroidStore =
        "https://play.google.com/store/apps/details?id=com.gettaxi.android";
    String urlIosStore =
        "https://itunes.apple.com/us/app/gett-nyc-black-car/id449655162?mt=8";
    if (await canLaunch(url)) {
      print(url);
      await launch(url);
    } else {
      if (Platform.isAndroid) {
        print(
            'Gett is not currently installed on your phone, opening Play Store.');
        await launch(urlAndroidStore);
      } else if (Platform.isIOS) {
        print(
            'Gett is not currently installed on your phone, opening App store.');
        await launch(urlIosStore);
      }
    }
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
