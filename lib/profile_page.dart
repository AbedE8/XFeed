// import 'dart:html';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat.dart';
import 'main.dart';
import 'image_post.dart';
import 'dart:async';
import 'edit_profile_page.dart';
import 'models/user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({this.userId});

  final String userId;

  _ProfilePage createState() => _ProfilePage(this.userId);
}

class _ProfilePage extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin<ProfilePage> {
  final String profileId;

  String currentUserId = currentUserModel.id;
  String view = "grid"; // default view
  bool isFollowing = false;
  bool followButtonClicked = false;
  int postCount = 0;
  int followerCount = 0;
  int followingCount = 0;
  User userProfile;
  List<DocumentSnapshot> _userPosts = new List();

  _ProfilePage(this.profileId);
  openChat() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Chat(
                  userToChatWith: userProfile,
                )));
  }

  editProfile() {
    EditProfilePage editPage = EditProfilePage();

    Navigator.of(context)
        .push(MaterialPageRoute<bool>(builder: (BuildContext context) {
      return Center(
        child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.maybePop(context);
                },
              ),
              title: Text('Edit Profile',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              actions: <Widget>[
                IconButton(
                    icon: Icon(
                      Icons.check,
                      color: Colors.blueAccent,
                    ),
                    onPressed: () {
                      editPage.applyChanges();
                      Navigator.maybePop(context);
                      setState(() {
                        //this is used to build the screen again so the changes made in edit
                        //take place
                      });
                    })
              ],
            ),
            body: ListView(
              children: <Widget>[
                Container(
                  child: editPage,
                ),
              ],
            )),
      );
    }));
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // reloads state when opened again

    Column buildStatColumn(String label, int number) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            number.toString(),
            style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
          ),
          Container(
              margin: const EdgeInsets.only(top: 4.0),
              child: Text(
                label,
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w400),
              ))
        ],
      );
    }

    Future<List<ImagePost>> getPosts() async {
      print("fetching user posts");

       List<ImagePost> posts = [];
      
        for (var doc in _userPosts) {
          posts.add(await ImagePost.fromDocument(doc,true));
        }

      return posts.toList();
    }

    Container buildFollowButton(
        {String text,
        Color backgroundcolor,
        Color textColor,
        Color borderColor,
        Function function}) {
      return Container(
        padding: EdgeInsets.only(top: 2.0),
        child: FlatButton(
            onPressed: function,
            child: Container(
              decoration: BoxDecoration(
                  color: backgroundcolor,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(5.0)),
              alignment: Alignment.center,
              child: Text(text,
                  style:
                      TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              width: 250.0,
              height: 27.0,
            )),
      );
    }

    Container buildProfileFollowButton(User user) {
      // viewing your own profile - should show edit button

      if (currentUserModel == null || user.id != currentUserModel.id) {
        return buildFollowButton(
          text: "Send Message",
          backgroundcolor: Colors.white,
          textColor: Colors.black,
          borderColor: Colors.grey,
          function: openChat,
        );
      }
      return buildFollowButton(
        text: "Edit Profile",
        backgroundcolor: Colors.white,
        textColor: Colors.black,
        borderColor: Colors.grey,
        function: editProfile,
      );
    }

    Row buildImageViewButtonBar() {
      Color isActiveButtonColor(String viewName) {
        if (view == viewName) {
          return Colors.blueAccent;
        } else {
          return Colors.black26;
        }
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.grid_on, color: isActiveButtonColor("grid")),
            onPressed: () {
              changeView("grid");
            },
          ),
          IconButton(
            icon: Icon(Icons.list, color: isActiveButtonColor("feed")),
            onPressed: () {
              changeView("feed");
            },
          ),
        ],
      );
    }

    Container buildUserPosts() {
      return Container(
          child: FutureBuilder<List<ImagePost>>(
        future: getPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Container(
                alignment: FractionalOffset.center,
                padding: const EdgeInsets.only(top: 10.0),
                child: CircularProgressIndicator());
          if (view == "grid") {
            return GridView.count(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                padding: const EdgeInsets.all(0.5),
                mainAxisSpacing: 1.5,
                crossAxisSpacing: 1.5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: snapshot.data.map((ImagePost post) {
                  return GridTile(child: ImageTile(post));
                }).toList());
          } else if (view == "feed") {
            return Column(
                children: snapshot.data.map((ImagePost post) {
              return post;
            }).toList());
          }
        },
      ));
      // },
      // ));
    }

    return Scaffold(
        body: FutureBuilder<DocumentSnapshot>(
            future: Firestore.instance
                .collection('users')
                .document(profileId)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Container(
                    alignment: FractionalOffset.center,
                    child: CircularProgressIndicator());

              User user = User.fromDocument(snapshot.data);
              userProfile = user;
              return Scaffold(
                  appBar: AppBar(
                    title: Text(
                      user.username,
                      style: const TextStyle(color: Colors.black),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  body: ListView(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                CircleAvatar(
                                  radius: 40.0,
                                  backgroundColor: Colors.grey,
                                  backgroundImage: NetworkImage(user.photoUrl),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    children: <Widget>[
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: <Widget>[
                                          buildStatColumn("posts", postCount),
                                        ],
                                      ),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: <Widget>[
                                            buildProfileFollowButton(user)
                                          ]),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(top: 15.0),
                                child: Text(
                                  user.displayName,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                )),
                            Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Text(user.bio),
                            ),
                          ],
                        ),
                      ),
                      Divider(),
                      buildImageViewButtonBar(),
                      Divider(height: 0.0),
                      buildUserPosts(),
                    ],
                  ));
            }));
  }

  changeView(String viewName) {
    setState(() {
      view = viewName;
    });
  }

  int _countFollowings(Map followings) {
    int count = 0;

    void countValues(key, value) {
      if (value) {
        count += 1;
      }
    }

    followings.forEach(countValues);

    return count;
  }

  void getUserInfo() async {
    // var snapshotUser =

    var snapshotPosts = await Firestore.instance
        .collection('posts')
        .where("publisher", isEqualTo: profileId)
        .orderBy("timeStamp", descending: true)
        .getDocuments();

    postCount = snapshotPosts.documents.length;
    _userPosts = snapshotPosts.documents;
    // print("updating num of posts to " + postCount.toString());
    // return snapshotUser;
    setState(() {
      
    });
  }

  // ensures state is kept when switching pages
  @override
  bool get wantKeepAlive => false;
}

class ImageTile extends StatelessWidget {
  final ImagePost imagePost;

  ImageTile(this.imagePost);

  getImagePost(DocumentSnapshot imageDocument) async {
    return await ImagePost.fromDocument(imageDocument, true);
  }

  clickedImage(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<bool>(
      builder: (BuildContext context) {
        return StreamBuilder(
            stream: Firestore.instance
                .collection('posts')
                .document(imagePost.postId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Container(
                    alignment: FractionalOffset.center,
                    child: CircularProgressIndicator());

              return Center(
                child: Scaffold(
                    appBar: AppBar(
                      title: Text('Photo',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.white,
                    ),
                    body: ListView(
                      children: <Widget>[
                        Container(
                          child: FutureBuilder(
                            future: getImagePost(snapshot.data),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData)
                                return Container(
                                    alignment: FractionalOffset.center,
                                    child: CircularProgressIndicator());
                              return Container(child: snapshot.data);
                            },
                          ),
                        ),
                      ],
                    )),
              );
            });
      },
    ));
  }

  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => clickedImage(context),
        child: Image.network(imagePost.mediaUrl, fit: BoxFit.cover));
  }
}

void openProfile(BuildContext context, String userId) {
  Navigator.of(context)
      .push(MaterialPageRoute<bool>(builder: (BuildContext context) {
    return ProfilePage(userId: userId);
  }));
}
