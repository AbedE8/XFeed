import 'dart:convert';
import 'package:path/path.dart' as Path;
import 'package:Xfeedm/categories.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:geocoder/model.dart';
import 'package:image_downloader/image_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'feed.dart';
import 'location.dart';
import 'upload_page.dart';
import 'dart:async';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'search_page.dart';
import 'activity_feed.dart';
import 'create_account.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io' show Platform;
import 'models/user.dart';
import 'package:image_picker/image_picker.dart';
import 'filter_page.dart';

final auth = FirebaseAuth.instance;
final googleSignIn = GoogleSignIn();
// final ref = Firestore.instance.collection('insta_users');
final users_ref = Firestore.instance.collection('users');
final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
var FBlogin_a = FacebookLogin();

User currentUserModel;

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // after upgrading flutter this is now necessary

  // enable timestamps in firebase
  Firestore.instance.settings().then((_) {
    print('[Main] Firestore timestamps in snapshots set');
  }, onError: (_) => print('[Main] Error setting timestamps in snapshots'));
  runApp(Fluttergram());
}

Future<Null> _ensureLoggedIn(BuildContext context) async {
  GoogleSignInAccount user = googleSignIn.currentUser;
  if (user == null) {
    user = await googleSignIn.signInSilently();
  }
  if (user == null) {
    await googleSignIn.signIn();
    await tryCreateUserRecord(context);
  }

  if (await auth.currentUser() == null) {
    final GoogleSignInAccount googleUser = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await auth.signInWithCredential(credential);
  }
}

Future<Null> _ensureFBLoggedIn(BuildContext context) async {
  FacebookLoginResult facebookLoginResult =
      await FBlogin_a.logIn(['email', 'user_gender', 'user_birthday']);
  switch (facebookLoginResult.status) {
    case FacebookLoginStatus.cancelledByUser:
      print("Cancelled");
      break;
    case FacebookLoginStatus.error:
      print("error");
      break;
    case FacebookLoginStatus.loggedIn:
      print("Logged In");
      final accessToken = facebookLoginResult.accessToken.token;
      final facebookAuthCred =
          FacebookAuthProvider.getCredential(accessToken: accessToken);
      final user = await auth.signInWithCredential(facebookAuthCred);
      await tryCreateUserRecordFB(context);
      print("User : " + user.toString());
      break;
  }
}

Future<Null> _silentLogin(BuildContext context) async {
  GoogleSignInAccount user = googleSignIn.currentUser;

  if (user == null) {
    user = await googleSignIn.signInSilently();
    await tryCreateUserRecord(context);
  }

  if (await auth.currentUser() == null && user != null) {
    final GoogleSignInAccount googleUser = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await auth.signInWithCredential(credential);
  }
}

Future<Null> _silentFBLogin(BuildContext context) async {
  FacebookAccessToken accessToken = await FBlogin_a.currentAccessToken;

  if (accessToken == null) {
    // user = await googleSignIn.signInSilently();
    // await tryCreateUserRecord(context);
    print("No access token should register");
    return;
  } else {
    print("access token is valid");
  }

  if (await auth.currentUser() == null && accessToken != null) {
    print("no authntication");
    final FacebookAccessToken accessToken = await FBlogin_a.currentAccessToken;
    final facebookAuthCred =
        FacebookAuthProvider.getCredential(accessToken: accessToken.token);
    await auth.signInWithCredential(facebookAuthCred);
  }
  await tryCreateUserRecordFB(context);
}

Future<Null> _setUpNotifications() async {
  if (Platform.isAndroid) {
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print('on message $message');
      },
      onResume: (Map<String, dynamic> message) async {
        print('on resume $message');
      },
      onLaunch: (Map<String, dynamic> message) async {
        print('on launch $message');
      },
    );

    _firebaseMessaging.getToken().then((token) {
      print("Firebase Messaging Token: " + token);

      Firestore.instance
          .collection("users")
          .document(currentUserModel.id)
          .updateData({"androidNotificationToken": token});
    });
  }
  if (Platform.isIOS) iOS_Permission();
  
  
  // _firebaseMessaging.requestNotificationPermissions();
  _firebaseMessaging.getToken().then((token) {
    print("token is " + token);
    Firestore.instance
        .collection("users")
        .document(currentUserModel.id)
        .updateData({"iosNotificationToken": token});
  });

  _firebaseMessaging.configure(
    onMessage: (Map<String, dynamic> message) async {
      print('on message $message');
    },
    onResume: (Map<String, dynamic> message) async {
      print('on resume $message');
    },
    onLaunch: (Map<String, dynamic> message) async {
      print('on launch $message');
    },
  );
}

void iOS_Permission() {
  _firebaseMessaging.requestNotificationPermissions(
      IosNotificationSettings(sound: true, badge: true, alert: true));
  _firebaseMessaging.onIosSettingsRegistered
      .listen((IosNotificationSettings settings) {
    print("Settings registered: $settings");
  });
}

Future<void> tryCreateUserRecord(BuildContext context) async {
  GoogleSignInAccount user = googleSignIn.currentUser;
  if (user == null) {
    return null;
  }
  DocumentSnapshot userRecord = await users_ref.document(user.id).get();
  if (userRecord.data == null) {
    // no user record exists, time to create

    String userName = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Center(
                child: Scaffold(
                    appBar: AppBar(
                      leading: Container(),
                      title: Text('Fill out missing data',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.white,
                    ),
                    body: ListView(
                      children: <Widget>[
                        Container(
                          child: CreateAccount(),
                        ),
                      ],
                    )),
              )),
    );

    if (userName != null || userName.length != 0) {
      users_ref.document(user.id).setData({
        "id": user.id,
        "username": userName,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "displayName": user.displayName,
        "bio": "",
        "followers": {},
        "following": {},
      });
    }
    userRecord = await users_ref.document(user.id).get();
  }

  currentUserModel = await User.fromDocument(userRecord);
  return null;
}

Future<String> _downloadImage(
    String photoURL, String uid) async {
  // var httpClient = HttpClient();
  // var req = await httpClient.getUrl(Uri.parse(photoURL));
  // var _dir = (await getApplicationDocumentsDirectory()).path;
  // String imagePath = _dir+'/'+uid;
  // var file = File(imagePath);
  // await file.writeAsBytes(req.bodyBytes);

  var imageId = await ImageDownloader.downloadImage(photoURL);
  if (imageId == null) {
    print("image library doesnt work");
    return null;
  }
  var path = await ImageDownloader.findPath(imageId);

  var file = File(path);
  print("19191919191991919191919199191 " + path.toString());
  // String image_path =  await uploadImage(file);
  // var uuid = Uuid().v1();
  var usersImages = FirebaseStorage.instance.ref().child("profilePic/${uid}.jpg");
  var metadata = StorageMetadata(contentType: "image/jpeg");
  // var storegRef = FirebaseStorage.instance.ref();
// var mountainsRef = storegRef.child("$uid.jpg");

  // StorageReference ref =
  //     FirebaseStorage.instance.ref().child("profilePic/pic_$uid.jpg");
  StorageUploadTask uploadTask =  usersImages.putFile(file);
StorageTaskSnapshot taskSnapshot= await uploadTask.onComplete;
  // String downloadUrl = await (await uploadTask.onComplete).ref.getDownloadURL();
  String downloadUrl = await taskSnapshot.ref.getDownloadURL();
  print("imageUrl after uploading is "+downloadUrl);
  return downloadUrl;
  // print("image file downloaded and located at"+image_path);
  // return image_path;
}

// TODO: implimint this window to get username/nickname from user instead of fb
Future<String> getNickname(var contexts) async {
  String userName = await Navigator.push(
    contexts,
    MaterialPageRoute(
        builder: (context) => Center(
              child: Scaffold(
                  appBar: AppBar(
                    leading: Container(),
                    title: Text('Fill out missing data',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.white,
                  ),
                  body: ListView(
                    children: <Widget>[
                      Container(
                        child: CreateAccount(),
                      ),
                    ],
                  )),
            )),
  );
  return userName;
}

void createNewUser(
    Map<String, dynamic> user_data, String photo_FB_URL, String userName) async {
      print("createNewUser: here id "+user_data['id']);
  await users_ref.document(user_data['id']).setData({
    "bio": "",
    "birthday": user_data['birthday'],
    "credit": "",
    "email": user_data['email'],
    "first_name": user_data['first_name'],
    "gender": user_data['gender'],
    "last_name": user_data['last_name'],
    "post_distribution": 250,
    "profile_pic_url": photo_FB_URL,
    "registration_date": DateTime.now(),
    "username": userName
  });
  //After creating user record we should update user preference to default
  Coordinates current_cordinate = await getUserCordinate();

  await Firestore.instance
    .collection("post_preferences")
    .document(user_data['id']).setData({
      "categories":FeedCategory.getAllCategoriesNames(),
      "radius":1,
      "gender":FeedCategory.genderNames,
      "location":GeoPoint(current_cordinate.latitude, current_cordinate.longitude),
      "min_age":FilterPosts.minAge,
      "max_age":FilterPosts.maxAge
    });
  
}

Future<void> tryCreateUserRecordFB(BuildContext context) async {
  // final user_token = await FBlogin_a.currentAccessToken.accessToken;
// final result = await facebookSignIn.logInWithReadPermissions(['email']);
  final FacebookAccessToken accessToken = await FBlogin_a.currentAccessToken;

  if (accessToken == null) {
    print("No user token exist");
    return null;
  }
  // print("token is " + accessToken.token);
  var httpClient = HttpClient();

  try {
    var request = await httpClient.getUrl(Uri.parse(
        'https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email,gender,birthday,picture&access_token=${accessToken.token}'));
    var response = await request.close();
    if (response.statusCode == HttpStatus.ok) {
      String json = await response.transform(utf8.decoder).join();
      Map<String, dynamic> user_data = jsonDecode(json);
      String photo_FB_URL = user_data['picture']['data']['url'].toString();
      print("printing data " + user_data.toString());

      DocumentSnapshot userRecord =
          await users_ref.document(user_data['id']).get();
      if (userRecord.data == null) {
        print("no user record exists, time to create");
        String userName = await getNickname(context);
        // print("nickname is "+nickname);
        await createNewUser(user_data, photo_FB_URL, userName);
        
       // await _downloadImage(photo_FB_URL,user_data['id']);
        // String userName = user_data['name']; //see getnickname
        
        userRecord = await users_ref.document(user_data['id']).get();
      } else {
        //TODO : download user photo once registered and upload it
        print("user phtot updated");
        await users_ref
            .document(user_data['id'])
            .updateData({"profile_pic_url": photo_FB_URL});
      }

      currentUserModel = User.fromDocument(userRecord);
      await currentUserModel.setUserPref();
      print("######user record created######");
    } else {
      print(
          'Error sending token to facebook: Http status ${response.statusCode} ');
    }
  } catch (exception) {
    print('Failed invoking the getFeed function. Exception: $exception');
  }

  return null;
}
updateCurrentUser(User currentUser, UserPreference pref) {
  //  DocumentSnapshot userRecord = await users_ref.document(userId).get();
  //  currentUserModel = await User.fromDocument(userRecord);
  //  await currentUser.setUserPref();
  currentUser.preferences = pref;
}
class Fluttergram extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluttergram122',
      theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
          // counter didn't reset back to zero; the application is not restarted.
          primarySwatch: Colors.blue,
          buttonColor: Colors.pink,
          primaryIconTheme: IconThemeData(color: Colors.black)),
      home: HomePage(title: 'Xfeed'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

PageController pageController;

class _HomePageState extends State<HomePage> {
  final int feedPage = 0;
  final int searchPage = 1;
  final int favoritePage = 2;
  final int profilePage = 3;
  bool triedSilentLogin = false;
  bool setupNotifications = false;
  File imageFile;
  Scaffold buildLoginPage() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 240.0),
          child: Column(
            children: <Widget>[
              Text(
                'Xfeed',
                style: TextStyle(
                    fontSize: 60.0,
                    fontFamily: "Billabong",
                    color: Colors.black),
              ),
              Padding(padding: const EdgeInsets.only(bottom: 100.0)),
              GestureDetector(
                onTap: login,
                child: Image.asset(
                  "assets/images/FB_image.png",
                  width: 255,
                  // height: 70,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("building page");
    if (triedSilentLogin == false) {
      silentFBLogin(context);
    }

    if (setupNotifications == false && currentUserModel != null) {
      setUpNotifications();
    }
    print("acceccToken " +
        (FBlogin_a.currentAccessToken == null ? "true" : "false") +
        " current_model " +
        (currentUserModel == null ? "true" : "false"));
    return (FBlogin_a.currentAccessToken == null || currentUserModel == null)
        ? buildLoginPage()
        : Scaffold(
            body: PageView(
              children: [
                Container(
                  color: Colors.white,
                  child: Feed(),
                ),
                Container(color: Colors.white, child: SearchPage()),
                Container(color: Colors.white, child: ActivityFeedPage()),
                Container(
                    color: Colors.white,
                    child: ProfilePage(
                      userId: currentUserModel.id,
                    )),
              ],
              controller: pageController,
              physics: NeverScrollableScrollPhysics(),
            ),
            floatingActionButton: Container(
                height: 65.0,
                width: 70.0,
                child: FloatingActionButton(
                  onPressed: () async {
                    var image = await ImagePicker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 1920,
                        maxHeight: 1200,
                        imageQuality: 80);

                    setState(() {
                      imageFile = image;
                      imageFile == null
                          ? pageController.jumpToPage(
                              feedPage) //jump to feed page in case no image captured
                          : Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Uploader(
                                        imageFile: imageFile,
                                      )));
                    });
                  },
                  child: Icon(Icons.add),
                )),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: BottomAppBar(
              shape: CircularNotchedRectangle(),
              color: Colors.white,
              child: Container(
                height: 30,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    IconButton(
                      iconSize: 30.0,
                      padding: EdgeInsets.only(left: 28.0),
                      icon: Icon(Icons.home),
                      onPressed: () {
                        setState(() {
                          pageController.jumpToPage(feedPage);
                        });
                      },
                    ),
                    IconButton(
                      iconSize: 30.0,
                      padding: EdgeInsets.only(right: 28.0),
                      icon: Icon(Icons.search),
                      onPressed: () {
                        setState(() {
                          pageController.jumpToPage(searchPage);
                        });
                      },
                    ),
                    IconButton(
                      iconSize: 30.0,
                      padding: EdgeInsets.only(left: 28.0),
                      icon: Icon(Icons.star),
                      onPressed: () {
                        setState(() {
                          pageController.jumpToPage(favoritePage);
                        });
                      },
                    ),
                    IconButton(
                      iconSize: 30.0,
                      padding: EdgeInsets.only(right: 28.0),
                      icon: Icon(Icons.person),
                      onPressed: () {
                        setState(() {
                          pageController.jumpToPage(profilePage);
                        });
                      },
                    )
                  ],
                ),
              ),
            ),
          );
  }

  void _FBlogin() async {
    await _ensureFBLoggedIn(context);
    setState(() {
      triedSilentLogin = true;
    });
  }

  void login() async {
    await _ensureFBLoggedIn(context);
    setState(() {
      print("@@@@@@@here");
      triedSilentLogin = true;
    });
  }

  void setUpNotifications() {
    _setUpNotifications();
    setState(() {
      setupNotifications = true;
    });
  }

  // void silentLogin(BuildContext context) async {
  //   await _silentLogin(context);
  //   setState(() {
  //     triedSilentLogin = true;
  //   });
  // }

  void silentFBLogin(BuildContext context) async {
    await _silentFBLogin(context);
    setState(() {
      print("here00000000000");
      triedSilentLogin = true;
    });
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }
}
